import 'package:flutter_test/flutter_test.dart';
import 'package:x_video_downloader/main.dart';

void main() {
  testWidgets('shows the downloader home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('X Video Downloader'), findsOneWidget);
    expect(find.text('Paste Video URL'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
  });
}
