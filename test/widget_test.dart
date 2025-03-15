import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubiks_cube_analyzer/app.dart';

void main() {
  testWidgets('アプリの起動テスト', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // TODO: アプリの初期状態のアサーションを追加
  });
}
