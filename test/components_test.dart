import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_native_views.dart';

/// The channel contract of each component: what it sends and how it reacts
/// to native events.
void main() {
  final ios = TargetPlatformVariant.only(TargetPlatform.iOS);
  final views = FakeNativeViews();

  setUp(views.install);
  tearDown(views.uninstall);

  Widget app(Widget child) => CupertinoApp(
    theme: const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: Color(0xFF0000FF),
    ),
    home: Center(child: child),
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  group('CNIcon', () {
    testWidgets('widget overrides win over the symbol', (tester) async {
      await tester.pumpWidget(
        app(
          const CNIcon(
            symbol: CNSymbol('star', size: 20, color: Color(0xFF00FF00)),
            size: 30,
            mode: CNSymbolRenderingMode.hierarchical,
          ),
        ),
      );
      await settle(tester);

      final symbol =
          views
                  .single('CupertinoNativeIcon')
                  .creationArgs('setSymbol')['symbol']
              as Map<Object?, Object?>;
      expect(symbol['name'], 'star');
      expect(symbol['size'], 30);
      expect(symbol['color'], 0xFF00FF00);
      expect(symbol['mode'], 'hierarchical');
    }, variant: ios);
  });

  group('CNSegmentedControl', () {
    testWidgets('updates labels after creation', (tester) async {
      Widget control(List<String> labels) => app(
        CNSegmentedControl(
          labels: labels,
          selectedIndex: 0,
          onValueChanged: (_) {},
        ),
      );
      await tester.pumpWidget(control(['A', 'B']));
      await settle(tester);
      final view = views.single('CupertinoNativeSegmentedControl');

      await tester.pumpWidget(control(['A', 'B', 'C']));
      await settle(tester);

      expect(view.lastArgs('setItems')['labels'], ['A', 'B', 'C']);
    }, variant: ios);

    testWidgets('global icon overrides apply to every symbol', (tester) async {
      await tester.pumpWidget(
        app(
          CNSegmentedControl(
            labels: const [],
            sfSymbols: const [CNSymbol('a', size: 12), CNSymbol('b')],
            iconSize: 18,
            selectedIndex: 0,
            onValueChanged: (_) {},
          ),
        ),
      );
      await settle(tester);

      final symbols =
          views
                  .single('CupertinoNativeSegmentedControl')
                  .creationArgs('setItems')['symbols']
              as List<Object?>;
      expect([for (final s in symbols) (s! as Map)['size']], [18, 18]);
    }, variant: ios);

    testWidgets('reports native selection', (tester) async {
      int? selected;
      await tester.pumpWidget(
        app(
          CNSegmentedControl(
            labels: const ['A', 'B'],
            selectedIndex: 0,
            onValueChanged: (i) => selected = i,
          ),
        ),
      );
      await settle(tester);

      await views.single('CupertinoNativeSegmentedControl').emit(
        'valueChanged',
        {'index': 1},
      );
      expect(selected, 1);
    }, variant: ios);
  });

  group('CNTabBar', () {
    testWidgets('encodes items as label + symbol maps', (tester) async {
      await tester.pumpWidget(
        app(
          CNTabBar(
            items: const [
              CNTabBarItem(label: 'Home', icon: CNSymbol('house')),
              CNTabBarItem(icon: CNSymbol('magnifyingglass')),
            ],
            iconSize: 22,
            currentIndex: 0,
            onTap: (_) {},
          ),
        ),
      );
      await settle(tester);

      final view = views.single('CupertinoNativeTabBar');
      final items = view.creationArgs('setItems')['items']! as List<Object?>;
      final first = items.first! as Map<Object?, Object?>;
      expect(first['label'], 'Home');
      expect((first['symbol']! as Map)['size'], 22);
      expect((items.last! as Map)['label'], isNull);
      expect(view.creationArgs('setLayout'), {
        'split': false,
        'rightCount': 1,
        'splitSpacing': 8.0,
      });
    }, variant: ios);

    testWidgets('ignores a tap on the current tab', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(
        app(
          CNTabBar(
            items: const [
              CNTabBarItem(label: 'A'),
              CNTabBarItem(label: 'B'),
            ],
            currentIndex: 0,
            onTap: taps.add,
          ),
        ),
      );
      await settle(tester);
      final view = views.single('CupertinoNativeTabBar');

      await view.emit('valueChanged', {'index': 0});
      await view.emit('valueChanged', {'index': 1});
      expect(taps, [1]);
    }, variant: ios);
  });

  group('CNButton', () {
    testWidgets('sends title and symbol together', (tester) async {
      await tester.pumpWidget(app(CNButton(label: 'Go', onPressed: () {})));
      await settle(tester);

      final view = views.single('CupertinoNativeButton');
      expect(view.creationArgs('setContent'), {'title': 'Go', 'symbol': null});
      expect(view.creationArgs('setStyle'), {
        'buttonStyle': 'plain',
        'tint': 0xFF0000FF,
        'round': false,
      });
    }, variant: ios);

    testWidgets('calls onPressed only while enabled', (tester) async {
      var presses = 0;
      Widget button(bool enabled) => app(
        CNButton(label: 'Go', enabled: enabled, onPressed: () => presses++),
      );
      await tester.pumpWidget(button(true));
      await settle(tester);
      final view = views.single('CupertinoNativeButton');

      await view.emit('pressed');
      await tester.pumpWidget(button(false));
      await settle(tester);
      await view.emit('pressed');

      expect(presses, 1);
      expect(view.lastArgs('setEnabled'), {'enabled': false});
    }, variant: ios);

    testWidgets('sends the semantic label and clears it', (tester) async {
      Widget button(String? semanticLabel) => app(
        CNButton.icon(
          icon: const CNSymbol('gear'),
          semanticLabel: semanticLabel,
          onPressed: () {},
        ),
      );
      await tester.pumpWidget(button('Settings'));
      await settle(tester);
      final view = views.single('CupertinoNativeButton');
      expect(view.creationArgs('setSemantics'), {'label': 'Settings'});

      await tester.pumpWidget(button(null));
      await settle(tester);
      expect(view.lastArgs('setSemantics'), {'label': null});
    }, variant: ios);

    testWidgets('highlights natively while pressed', (tester) async {
      await tester.pumpWidget(app(CNButton(label: 'Go', onPressed: () {})));
      await settle(tester);
      final view = views.single('CupertinoNativeButton');

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CNButton)),
      );
      await settle(tester);
      await gesture.up();
      await settle(tester);

      expect(
        [
          for (final call in view.calls)
            if (call.method == 'setPressed') call.arguments['pressed'],
        ],
        [true, false],
      );
    }, variant: ios);
  });

  group('CNPopupMenuButton', () {
    testWidgets('encodes entries in order, dividers included', (tester) async {
      int? selected;
      await tester.pumpWidget(
        app(
          CNPopupMenuButton.label(
            buttonLabel: 'Menu',
            items: const [
              CNPopupMenuItem(label: 'One', checked: true),
              CNPopupMenuDivider(),
              CNPopupMenuItem(label: 'Two', enabled: false),
            ],
            onSelected: (i) => selected = i,
          ),
        ),
      );
      await settle(tester);

      final view = views.single('CupertinoNativePopupMenuButton');
      expect(view.creationArgs('setItems')['items'], [
        {'label': 'One', 'symbol': null, 'enabled': true, 'checked': true},
        {'divider': true},
        {'label': 'Two', 'symbol': null, 'enabled': false, 'checked': false},
      ]);

      await view.emit('itemSelected', {'index': 2});
      expect(selected, 2);
    }, variant: ios);

    testWidgets('every constructor sends the semantic label', (tester) async {
      const items = [CNPopupMenuItem(label: 'One')];
      await tester.pumpWidget(
        app(
          Column(
            children: [
              CNPopupMenuButton.icon(
                buttonIcon: const CNSymbol('globe'),
                items: items,
                onSelected: (_) {},
                semanticLabel: 'Switch site',
              ),
              CNPopupMenuButton.label(
                buttonLabel: 'Menu',
                items: items,
                onSelected: (_) {},
                semanticLabel: 'Menu label',
              ),
              CNPopupMenuButton(
                items: items,
                onSelected: (_) {},
                semanticLabel: 'Child menu',
                child: const Text('Open'),
              ),
            ],
          ),
        ),
      );
      await settle(tester);

      expect([
        for (final view in views.all('CupertinoNativePopupMenuButton'))
          view.creationArgs('setSemantics')['label'],
      ], unorderedEquals(['Switch site', 'Menu label', 'Child menu']));
    }, variant: ios);

    testWidgets('child mode uses a transparent native button', (tester) async {
      await tester.pumpWidget(
        app(
          CNPopupMenuButton(
            items: const [CNPopupMenuItem(label: 'One')],
            onSelected: (_) {},
            child: const Text('Open'),
          ),
        ),
      );
      await settle(tester);

      expect(find.text('Open'), findsOneWidget);
      expect(
        views
            .single('CupertinoNativePopupMenuButton')
            .creationArgs('setStyle')['transparent'],
        isTrue,
      );
    }, variant: ios);
  });
}
