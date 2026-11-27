import 'package:cupertino_native/cupertino_native.dart';
import 'package:cupertino_native/channel/params.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Runs [body] with a context whose brightness is [brightness].
  Future<T> withContext<T>(
    WidgetTester tester,
    T Function(BuildContext context) body, {
    Brightness brightness = Brightness.light,
  }) async {
    late T result;
    await tester.pumpWidget(
      CupertinoTheme(
        data: CupertinoThemeData(brightness: brightness),
        child: Builder(
          builder: (context) {
            result = body(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('resolveColorToArgb encodes 0xAARRGGBB', (tester) async {
    final argb = await withContext(
      tester,
      (context) => resolveColorToArgb(const Color(0x80112233), context),
    );
    expect(argb, 0x80112233);
  });

  testWidgets('resolveColorToArgb resolves dynamic colors', (tester) async {
    const color = CupertinoDynamicColor.withBrightness(
      color: Color(0xFFFFFFFF),
      darkColor: Color(0xFF000000),
    );
    expect(
      await withContext(tester, (c) => resolveColorToArgb(color, c)),
      0xFFFFFFFF,
    );
    expect(
      await withContext(
        tester,
        (c) => resolveColorToArgb(color, c),
        brightness: Brightness.dark,
      ),
      0xFF000000,
    );
  });

  testWidgets('CNSymbol.encode includes every field', (tester) async {
    const symbol = CNSymbol(
      'star.fill',
      size: 20,
      color: Color(0xFFFF0000),
      paletteColors: [Color(0xFF00FF00), Color(0xFF0000FF)],
      mode: CNSymbolRenderingMode.palette,
      gradient: true,
    );
    expect(await withContext(tester, symbol.encode), {
      'name': 'star.fill',
      'size': 20.0,
      'color': 0xFFFF0000,
      'paletteColors': [0xFF00FF00, 0xFF0000FF],
      'mode': 'palette',
      'gradient': true,
    });
  });

  testWidgets('CNSymbol.encode defaults optional fields', (tester) async {
    expect(await withContext(tester, const CNSymbol('star').encode), {
      'name': 'star',
      'size': 24.0,
      'color': null,
      'paletteColors': null,
      'mode': null,
      'gradient': false,
    });
  });
}
