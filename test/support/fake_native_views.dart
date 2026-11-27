import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the native side of the plugin in widget tests.
///
/// Intercepts platform view creation, decodes the creation params, and
/// records every call each view's channel receives.
class FakeNativeViews {
  final Map<int, FakeNativeView> _views = {};

  TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Starts intercepting platform view creation. Pair with [uninstall].
  void install() {
    _messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create') {
        final args = call.arguments as Map<Object?, Object?>;
        final view = FakeNativeView._(
          args['id']! as int,
          args['viewType']! as String,
          args['params'] as Uint8List?,
        );
        _views[view.id] = view;
        _messenger.setMockMethodCallHandler(view.channel, view._handle);
      }
      return null;
    });
  }

  void uninstall() {
    _messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
    for (final view in _views.values) {
      _messenger.setMockMethodCallHandler(view.channel, null);
    }
    _views.clear();
  }

  /// The only created view of [viewType].
  FakeNativeView single(String viewType) =>
      _views.values.singleWhere((view) => view.viewType == viewType);
}

/// One fake native view and the calls it received.
class FakeNativeView {
  FakeNativeView._(this.id, this.viewType, Uint8List? params)
    : creationUpdates = _decodeUpdates(params);

  final int id;
  final String viewType;

  /// The `[method, args]` pairs sent as creation params, in order.
  final List<(String, Map<Object?, Object?>)> creationUpdates;

  /// Calls received over the channel after creation.
  final List<MethodCall> calls = [];

  /// Optional reply for incoming calls; return a value or throw.
  Object? Function(MethodCall call)? onCall;

  MethodChannel get channel => MethodChannel('${viewType}_$id');

  /// Names of the methods in [creationUpdates], in order.
  List<String> get creationMethods => [for (final (m, _) in creationUpdates) m];

  /// Arguments of the creation update for [method].
  Map<Object?, Object?> creationArgs(String method) =>
      creationUpdates.firstWhere((update) => update.$1 == method).$2;

  /// Names of the methods received after creation, in order.
  List<String> get methods => [for (final call in calls) call.method];

  /// Arguments of the last call to [method].
  Map<Object?, Object?> lastArgs(String method) =>
      calls.lastWhere((call) => call.method == method).arguments
          as Map<Object?, Object?>;

  /// Simulates the native view sending [method] to Dart.
  Future<void> emit(String method, [Map<String, Object?>? args]) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(method, args),
          ),
          (_) {},
        );
  }

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call);
    return onCall?.call(call);
  }

  static List<(String, Map<Object?, Object?>)> _decodeUpdates(
    Uint8List? params,
  ) {
    if (params == null) return const [];
    final decoded =
        const StandardMessageCodec().decodeMessage(ByteData.sublistView(params))
            as Map<Object?, Object?>;
    return [
      for (final update
          in (decoded['updates']! as List<Object?>).cast<List<Object?>>())
        (update[0]! as String, update[1]! as Map<Object?, Object?>),
    ];
  }
}
