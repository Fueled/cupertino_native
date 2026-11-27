import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

/// On platforms without native views every component renders a Flutter
/// fallback instead of a platform view.
void main() {
  final android = TargetPlatformVariant.only(TargetPlatform.android);

  Widget app(Widget child) => CupertinoApp(
    home: CupertinoPageScaffold(child: Center(child: child)),
  );

  void expectNoPlatformViews() {
    expect(find.byType(UiKitView), findsNothing);
    expect(find.byType(AppKitView), findsNothing);
  }

  testWidgets('switch and slider fall back and forward changes', (
    tester,
  ) async {
    bool? switched;
    double? slid;
    await tester.pumpWidget(
      app(
        Column(
          children: [
            CNSwitch(value: false, onChanged: (v) => switched = v),
            CNSlider(value: 0.5, onChanged: (v) => slid = v),
          ],
        ),
      ),
    );

    expectNoPlatformViews();
    // No color: the fallback keeps CupertinoSwitch's own default.
    expect(
      tester
          .widget<CupertinoSwitch>(find.byType(CupertinoSwitch))
          .activeTrackColor,
      isNull,
    );
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.drag(find.byType(CupertinoSlider), const Offset(40, 0));
    expect(switched, isTrue);
    expect(slid, isNotNull);
  }, variant: android);

  testWidgets('icon falls back to a placeholder', (tester) async {
    await tester.pumpWidget(app(const CNIcon(symbol: CNSymbol('star'))));

    expectNoPlatformViews();
    expect(find.byType(Icon), findsOneWidget);
  }, variant: android);

  testWidgets('segmented control with fewer than two segments builds', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        CNSegmentedControl(
          labels: const [],
          sfSymbols: const [CNSymbol('star')],
          selectedIndex: 0,
          onValueChanged: (_) {},
        ),
      ),
    );

    expectNoPlatformViews();
    expect(tester.takeException(), isNull);
  }, variant: android);

  testWidgets('symbol-only segments fall back to icons', (tester) async {
    await tester.pumpWidget(
      app(
        CNSegmentedControl(
          labels: const [],
          sfSymbols: const [CNSymbol('a'), CNSymbol('b')],
          selectedIndex: 0,
          onValueChanged: (_) {},
        ),
      ),
    );

    expect(find.byType(CupertinoSegmentedControl<int>), findsOneWidget);
  }, variant: android);

  testWidgets('button falls back and respects enabled', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      app(
        Column(
          children: [
            CNButton(label: 'On', onPressed: () => presses++),
            CNButton(label: 'Off', enabled: false, onPressed: () => presses++),
          ],
        ),
      ),
    );

    expectNoPlatformViews();
    await tester.tap(find.text('On'));
    await tester.tap(find.text('Off'));
    expect(presses, 1);
  }, variant: android);

  testWidgets('button fallback is labelled and activates', (tester) async {
    final semantics = tester.ensureSemantics();
    var presses = 0;
    await tester.pumpWidget(
      app(
        CNButton.icon(
          icon: const CNSymbol('gear'),
          semanticLabel: 'Settings',
          onPressed: () => presses++,
        ),
      ),
    );

    tester.semantics.tap(find.semantics.byLabel('Settings'));
    expect(presses, 1);
    semantics.dispose();
  }, variant: android);

  testWidgets('popup menu fallbacks are labelled and open the menu', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
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

    for (final label in ['Switch site', 'Child menu']) {
      tester.semantics.tap(find.semantics.byLabel(label));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
    semantics.dispose();
  }, variant: android);

  testWidgets('icon variants draw fallbackIcon, else an ellipsis', (
    tester,
  ) async {
    const items = [CNPopupMenuItem(label: 'One')];
    await tester.pumpWidget(
      app(
        Column(
          children: [
            CNButton.icon(
              icon: const CNSymbol('gear'),
              fallbackIcon: CupertinoIcons.settings,
              onPressed: () {},
            ),
            CNPopupMenuButton.icon(
              buttonIcon: const CNSymbol('globe'),
              fallbackIcon: CupertinoIcons.globe,
              items: items,
              onSelected: (_) {},
            ),
          ],
        ),
      ),
    );
    expect(find.byIcon(CupertinoIcons.settings), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.globe), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.ellipsis), findsNothing);

    await tester.pumpWidget(
      app(
        Column(
          children: [
            CNButton.icon(icon: const CNSymbol('gear'), onPressed: () {}),
            CNPopupMenuButton.icon(
              buttonIcon: const CNSymbol('globe'),
              items: items,
              onSelected: (_) {},
            ),
          ],
        ),
      ),
    );
    expect(find.byIcon(CupertinoIcons.ellipsis), findsNWidgets(2));
  }, variant: android);

  testWidgets('popup menu falls back to an action sheet', (tester) async {
    int? selected;
    await tester.pumpWidget(
      app(
        CNPopupMenuButton.label(
          buttonLabel: 'Menu',
          items: const [
            CNPopupMenuItem(label: 'One'),
            CNPopupMenuDivider(),
            CNPopupMenuItem(label: 'Two'),
          ],
          onSelected: (i) => selected = i,
        ),
      ),
    );

    expectNoPlatformViews();
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(selected, 2);
  }, variant: android);

  testWidgets('tab bar falls back to CupertinoTabBar', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      app(
        CNTabBar(
          items: const [
            CNTabBarItem(label: 'A'),
            CNTabBarItem(label: 'B'),
          ],
          currentIndex: 0,
          onTap: (i) => tapped = i,
        ),
      ),
    );

    expectNoPlatformViews();
    await tester.tap(find.text('B'));
    expect(tapped, 1);
  }, variant: android);
}
