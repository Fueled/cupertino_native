import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// The state of a native view, grouped by the channel method that applies it.
///
/// Each entry maps a method name (for example `setValue`) to its complete
/// argument map. Arguments are always complete: a `null` value means "use the
/// native default", so clearing a property is expressed the same way as
/// setting one.
typedef NativeState = Map<String, Map<String, Object?>>;

/// Whether the current platform renders native views (iOS or macOS, not web).
bool get supportsNativeViews =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// Base [State] for widgets that embed a native iOS/macOS control.
///
/// Subclasses describe *what* the native view should show; this class owns
/// *how* it gets there:
///
/// * builds the Flutter fallback on platforms without native views;
/// * creates the `UiKitView`/`AppKitView` and the per-view method channel
///   named `<viewType>_<id>`;
/// * sends the full state as creation params, then diffs every later state
///   against what was last sent and invokes only the methods that changed;
/// * tracks brightness and re-resolves theme-dependent colors;
/// * pushes the widget's value back to native when the parent rejects a
///   change reported by native (see [recordNativeState]);
/// * reports channel errors instead of leaving them unhandled, and stops
///   talking to the view once disposed.
abstract class NativeViewState<T extends StatefulWidget> extends State<T> {
  MethodChannel? _channel;
  NativeState? _creationState;
  final NativeState _sent = {};
  bool _resyncScheduled = false;

  /// Platform view type registered by the native plugin, such as
  /// `CupertinoNativeSwitch`. Also the prefix of the channel name.
  @protected
  String get viewType;

  /// The complete state the native view should display right now.
  ///
  /// Called synchronously with a valid [context] whenever the widget or its
  /// dependencies change; resolve colors and other context-dependent values
  /// here. Entries are applied in iteration order.
  @protected
  NativeState describeNativeState(BuildContext context);

  /// The Flutter widget shown on platforms without native views.
  @protected
  Widget buildFallback(BuildContext context);

  /// Sizes and wraps the platform view. Platform views expand to fill their
  /// constraints, so implementations must give them finite bounds.
  @protected
  Widget layoutNativeView(BuildContext context, Widget platformView) =>
      platformView;

  /// Gestures the platform view should claim from the Flutter arena.
  @protected
  Set<Factory<OneSequenceGestureRecognizer>> get gestureRecognizers =>
      const <Factory<OneSequenceGestureRecognizer>>{};

  /// Handles an event sent by the native view, such as `valueChanged`.
  @protected
  void handleNativeEvent(String method, Map<Object?, Object?> args) {}

  /// Called once the native view and its [channel] exist.
  @protected
  void didCreateNativeView(MethodChannel channel) {}

  /// Called after the methods in [methods] were sent to the native view.
  @protected
  void didSendNativeUpdates(Set<String> methods) {}

  /// The channel of the live native view, or null before creation and after
  /// disposal.
  @protected
  MethodChannel? get nativeChannel => _channel;

  /// Records that the native view now shows [args] for [method] because the
  /// user changed it natively.
  ///
  /// Call this before forwarding a native change to the widget's callback.
  /// After the next frame the state is synced again, so if the parent did not
  /// accept the change, the widget's own value is pushed back to native.
  @protected
  void recordNativeState(String method, Map<String, Object?> args) {
    _sent[method] = args;
    if (_resyncScheduled) return;
    _resyncScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _resyncScheduled = false;
      _sync();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// Sends a one-off command that is not part of the view's state, such as a
  /// pressed highlight.
  @protected
  void sendNativeCommand(String method, [Map<String, Object?>? args]) {
    final channel = _channel;
    if (channel != null) unawaited(_invoke(channel, method, args));
  }

  /// Asks the native view for its intrinsic content size.
  ///
  /// Returns null if the view is not created yet, is disposed while waiting,
  /// or cannot report a size.
  @protected
  Future<Size?> measureNativeView() async {
    final channel = _channel;
    if (channel == null) return null;
    try {
      final size = await channel.invokeMapMethod<String, Object?>(
        'getIntrinsicSize',
      );
      if (!mounted || !identical(channel, _channel) || size == null) {
        return null;
      }
      final width = (size['width'] as num?)?.toDouble();
      final height = (size['height'] as num?)?.toDouble();
      if (width == null || height == null) return null;
      return Size(width, height);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    _channel = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!supportsNativeViews) return buildFallback(context);

    // The platform view reads creation params only when it is created, so
    // keep the snapshot it was created with; later changes are diffed against
    // it once the view exists.
    final creationState = _creationState ??= _currentState(context);
    final creationParams = <String, Object?>{
      'updates': [
        for (final MapEntry(key: method, value: args) in creationState.entries)
          [method, args],
      ],
    };

    final Widget platformView = defaultTargetPlatform == TargetPlatform.iOS
        ? UiKitView(
            viewType: viewType,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onPlatformViewCreated,
            gestureRecognizers: gestureRecognizers,
          )
        : AppKitView(
            viewType: viewType,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onPlatformViewCreated,
            gestureRecognizers: gestureRecognizers,
          );
    return layoutNativeView(context, platformView);
  }

  NativeState _currentState(BuildContext context) => {
    'setBrightness': {
      'isDark': CupertinoTheme.brightnessOf(context) == Brightness.dark,
    },
    ...describeNativeState(context),
  };

  void _onPlatformViewCreated(int id) {
    _channel?.setMethodCallHandler(null);
    final channel = MethodChannel('${viewType}_$id');
    _channel = channel;
    channel.setMethodCallHandler(_handleCall);
    _sent
      ..clear()
      ..addAll(_creationState ?? const {});
    didCreateNativeView(channel);
    // Catch up with anything that changed while the view was being created.
    _sync();
  }

  Future<Object?> _handleCall(MethodCall call) async {
    if (!mounted) return null;
    final args = call.arguments;
    handleNativeEvent(
      call.method,
      args is Map ? args.cast<Object?, Object?>() : const {},
    );
    return null;
  }

  void _sync() {
    final channel = _channel;
    if (channel == null || !mounted) return;
    final sent = <String>{};
    for (final MapEntry(key: method, value: args) in _currentState(
      context,
    ).entries) {
      if (_deepEquals(_sent[method], args)) continue;
      _sent[method] = args;
      sent.add(method);
      unawaited(
        _invoke(
          channel,
          method,
          args,
          // Forget a failed update so the next sync retries it.
          onError: () {
            if (identical(_sent[method], args)) _sent.remove(method);
          },
        ),
      );
    }
    if (sent.isNotEmpty) didSendNativeUpdates(sent);
  }

  Future<void> _invoke(
    MethodChannel channel,
    String method,
    Object? args, {
    VoidCallback? onError,
  }) async {
    try {
      await channel.invokeMethod<void>(method, args);
    } catch (error, stack) {
      onError?.call();
      // The view went away while the call was in flight; nothing to report.
      if (!identical(channel, _channel)) return;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'cupertino_native',
          context: ErrorDescription('while sending "$method" to $viewType'),
        ),
      );
    }
  }
}

bool _deepEquals(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
