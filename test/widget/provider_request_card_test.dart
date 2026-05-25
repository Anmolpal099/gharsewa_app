import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/features/provider_panel/data/models/booking_request.dart';
import 'package:gharsewa/features/provider_panel/data/models/enums.dart';
import 'package:gharsewa/features/provider_panel/presentation/widgets/request_card.dart';

BookingRequest _sampleRequest({bool urgent = false}) {
  final scheduled = urgent
      ? DateTime.now().add(const Duration(hours: 6))
      : DateTime.now().add(const Duration(days: 3));
  return BookingRequest(
    id: 'req-1',
    customerId: 'c1',
    customerName: 'Alex Customer',
    customerLocation: 'Kathmandu',
    serviceTitle: 'Plumbing',
    description: 'Fix leak',
    proposedPrice: 2500,
    scheduledDateTime: scheduled,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    status: BookingRequestStatus.pending,
  );
}

void main() {
  testWidgets('RequestCard shows customer and actions (8.6)', (tester) async {
    var accepted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RequestCard(
            request: _sampleRequest(urgent: true),
            onAccept: () => accepted = true,
            onCounter: () {},
            onDecline: () {},
          ),
        ),
      ),
    );

    expect(find.text('Alex Customer'), findsOneWidget);
    expect(find.text('URGENT'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await tester.pump();
    expect(accepted, isTrue);
  });
}
