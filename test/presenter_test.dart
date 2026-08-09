import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hymnal_tool/models/models.dart';
import 'package:hymnal_tool/screens/presenter_screen.dart';

void main() {
  testWidgets('presenter advances and blanks from keyboard controls', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 9);
    final song = Song(
      id: 'song-1',
      title: 'Keyboard Hymn',
      sections: const [
        SongSection(
          id: 'v1',
          type: SongSectionType.verse,
          label: 'Verse 1',
          lyrics: 'First projected verse',
          order: 0,
        ),
        SongSection(
          id: 'v2',
          type: SongSectionType.verse,
          label: 'Verse 2',
          lyrics: 'Second projected verse',
          order: 1,
        ),
      ],
      rights: const RightsInfo(status: RightsStatus.userProvided),
      createdAt: now,
      updatedAt: now,
    );
    const theme = PresentationTheme(
      id: 'test-theme',
      name: 'Test',
      gradientColors: [0xff222222, 0xff000000],
    );

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpWidget(
      MaterialApp(
        home: PresenterScreen(songs: [song], theme: theme),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('First projected verse'), findsOneWidget);
    expect(find.text('1.Verse 1'), findsNothing);
    expect(find.text('Verse 1'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Second projected verse'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.pumpAndSettle();
    expect(find.text('Second projected verse'), findsNothing);
  });

  testWidgets('presenter applies the selected theme and alignment', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 9);
    final song = Song(
      id: 'song-themed',
      title: 'Themed Hymn',
      sections: const [
        SongSection(
          id: 'v1',
          type: SongSectionType.verse,
          label: 'Verse 1',
          lyrics: 'Theme preview lyrics',
          order: 0,
        ),
      ],
      rights: const RightsInfo(status: RightsStatus.userProvided),
      createdAt: now,
      updatedAt: now,
    );
    const theme = PresentationTheme(
      id: 'left-theme',
      name: 'Left aligned',
      gradientColors: [0xff123456, 0xff020304],
      textColor: 0xfffefefe,
      alignment: 'left',
      fontSize: 72,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PresenterScreen(songs: [song], theme: theme),
      ),
    );
    await tester.pumpAndSettle();

    final lyrics = tester.widget<Text>(find.text('Theme preview lyrics'));
    expect(lyrics.textAlign, TextAlign.left);
    expect(lyrics.style?.color, const Color(0xfffefefe));
    expect(lyrics.style?.fontSize, 72);
  });
}
