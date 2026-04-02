import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/ui/overlays/modal_panel_frame.dart';

void main() {
  testWidgets('modal panel frame fills the modal surface without assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 240,
            child: ModalPanelFrame(child: Text('Modal content')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final frameRect = tester.getRect(find.byType(ModalPanelFrame));
    final surfaceRect = tester.getRect(
      find.byKey(const ValueKey('modal-panel-surface')),
    );

    expect(surfaceRect, equals(frameRect));
    expect(find.text('Modal content'), findsOneWidget);
    expect(find.byKey(const ValueKey('modal-panel-svg')), findsNothing);
    expect(find.byType(DecoratedBox), findsWidgets);
  });
}
