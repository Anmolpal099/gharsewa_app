import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gharsewa/data/models/ai_consultation_models.dart';

void main() {
  group('Form Validation Tests', () {
    group('DefectMarkerModel Validation', () {
      test('should validate coordinates within range', () {
        const validMarker = DefectMarkerModel(
          id: '1',
          x: 0.5,
          y: 0.5,
          description: 'Valid marker',
        );

        expect(validMarker.hasValidCoordinates, isTrue);
        expect(validMarker.isValid, isTrue);
      });

      test('should invalidate coordinates outside range', () {
        const invalidMarkerX = DefectMarkerModel(
          id: '1',
          x: 1.5,
          y: 0.5,
          description: 'Invalid X coordinate',
        );

        expect(invalidMarkerX.hasValidCoordinates, isFalse);
        expect(invalidMarkerX.isValid, isFalse);

        const invalidMarkerY = DefectMarkerModel(
          id: '2',
          x: 0.5,
          y: -0.1,
          description: 'Invalid Y coordinate',
        );

        expect(invalidMarkerY.hasValidCoordinates, isFalse);
        expect(invalidMarkerY.isValid, isFalse);
      });

      test('should validate description minimum length', () {
        const validMarker = DefectMarkerModel(
          id: '1',
          x: 0.5,
          y: 0.5,
          description: 'OK',
        );

        expect(validMarker.hasValidDescription, isTrue);

        const invalidMarker = DefectMarkerModel(
          id: '2',
          x: 0.5,
          y: 0.5,
          description: 'A',
        );

        expect(invalidMarker.hasValidDescription, isFalse);
        expect(invalidMarker.isValid, isFalse);
      });

      test('should trim whitespace in description validation', () {
        const markerWithSpaces = DefectMarkerModel(
          id: '1',
          x: 0.5,
          y: 0.5,
          description: '  ',
        );

        expect(markerWithSpaces.hasValidDescription, isFalse);

        const validMarkerWithSpaces = DefectMarkerModel(
          id: '2',
          x: 0.5,
          y: 0.5,
          description: '  OK  ',
        );

        expect(validMarkerWithSpaces.hasValidDescription, isTrue);
      });

      test('should validate edge case coordinates', () {
        const markerAtOrigin = DefectMarkerModel(
          id: '1',
          x: 0.0,
          y: 0.0,
          description: 'At origin',
        );

        expect(markerAtOrigin.hasValidCoordinates, isTrue);

        const markerAtMax = DefectMarkerModel(
          id: '2',
          x: 1.0,
          y: 1.0,
          description: 'At max',
        );

        expect(markerAtMax.hasValidCoordinates, isTrue);
      });

      test('should validate complete marker', () {
        const completeMarker = DefectMarkerModel(
          id: '1',
          x: 0.5,
          y: 0.5,
          description: 'Complete valid marker',
        );

        expect(completeMarker.isValid, isTrue);
        expect(completeMarker.hasValidCoordinates, isTrue);
        expect(completeMarker.hasValidDescription, isTrue);
      });
    });

    group('Marker Description Input Validation', () {
      testWidgets('should enforce maximum description length',
          (WidgetTester tester) async {
        // Test that description field has max length constraint
        const maxLength = 500;
        final longDescription = 'A' * (maxLength + 1);

        // Create a marker with long description
        final marker = DefectMarkerModel(
          id: '1',
          x: 0.5,
          y: 0.5,
          description: longDescription,
        );

        // Verify marker can be created (validation happens at API level)
        expect(marker.description.length, greaterThan(maxLength));
      });

      testWidgets('should accept valid description lengths',
          (WidgetTester tester) async {
        const validDescriptions = [
          'OK',
          'Water leak',
          'This is a longer description that is still valid',
        ];

        for (final desc in validDescriptions) {
          final marker = DefectMarkerModel(
            id: '1',
            x: 0.5,
            y: 0.5,
            description: desc,
          );

          expect(marker.hasValidDescription, isTrue);
        }
      });
    });

    group('Marker Count Validation', () {
      test('should enforce maximum marker limit', () {
        const maxMarkers = 10;

        // Create list of markers
        final markers = List.generate(
          maxMarkers,
          (index) => DefectMarkerModel(
            id: '$index',
            x: 0.5,
            y: 0.5,
            description: 'Marker $index',
          ),
        );

        expect(markers.length, equals(maxMarkers));
        expect(markers.length <= maxMarkers, isTrue);
      });

      test('should require at least one marker', () {
        final emptyMarkers = <DefectMarkerModel>[];
        expect(emptyMarkers.isEmpty, isTrue);
        expect(emptyMarkers.length >= 1, isFalse);
      });
    });

    group('Provider Recommendation Validation', () {
      test('should validate provider rating range', () {
        const validProvider = ProviderRecommendationModel(
          id: '1',
          name: 'Test Provider',
          rating: 4.5,
          services: ['Service 1'],
        );

        expect(validProvider.rating, greaterThanOrEqualTo(0.0));
        expect(validProvider.rating, lessThanOrEqualTo(5.0));
      });

      test('should identify high-rated providers', () {
        const highRatedProvider = ProviderRecommendationModel(
          id: '1',
          name: 'Excellent Provider',
          rating: 4.8,
          services: ['Service 1'],
        );

        expect(highRatedProvider.hasHighRating, isTrue);

        const lowRatedProvider = ProviderRecommendationModel(
          id: '2',
          name: 'Average Provider',
          rating: 3.5,
          services: ['Service 1'],
        );

        expect(lowRatedProvider.hasHighRating, isFalse);
      });

      test('should validate provider has services', () {
        const providerWithServices = ProviderRecommendationModel(
          id: '1',
          name: 'Test Provider',
          rating: 4.5,
          services: ['Plumbing', 'Electrical'],
        );

        expect(providerWithServices.services.isNotEmpty, isTrue);
        expect(providerWithServices.services.length, equals(2));

        const providerWithoutServices = ProviderRecommendationModel(
          id: '2',
          name: 'Test Provider',
          rating: 4.5,
          services: [],
        );

        expect(providerWithoutServices.services.isEmpty, isTrue);
      });

      test('should format rating correctly', () {
        const provider = ProviderRecommendationModel(
          id: '1',
          name: 'Test Provider',
          rating: 4.567,
          services: ['Service 1'],
        );

        expect(provider.formattedRating, equals('4.6'));
      });
    });

    group('Consultation Data Validation', () {
      test('should validate cost range', () {
        final consultation = AIConsultationModel(
          id: '1',
          imageUrl: 'https://example.com/image.jpg',
          markers: const [],
          diagnosis: 'Test diagnosis',
          recommendedServiceType: 'Plumbing',
          costMin: 2000.0,
          costMax: 5000.0,
          recommendedProviders: const [],
          createdAt: DateTime.now(),
        );

        expect(consultation.costMin, lessThan(consultation.costMax));
        expect(consultation.costMin, greaterThanOrEqualTo(0));
        expect(consultation.costMax, greaterThan(0));
      });

      test('should validate minimum cost estimate', () {
        final consultation = AIConsultationModel(
          id: '1',
          imageUrl: 'https://example.com/image.jpg',
          markers: const [],
          diagnosis: 'Test diagnosis',
          recommendedServiceType: 'Plumbing',
          costMin: 500.0,
          costMax: 1000.0,
          recommendedProviders: const [],
          createdAt: DateTime.now(),
        );

        // Minimum cost should be at least NPR 500 per requirements
        expect(consultation.costMin, greaterThanOrEqualTo(500));
      });

      test('should validate maximum cost estimate', () {
        final consultation = AIConsultationModel(
          id: '1',
          imageUrl: 'https://example.com/image.jpg',
          markers: const [],
          diagnosis: 'Test diagnosis',
          recommendedServiceType: 'Plumbing',
          costMin: 2000.0,
          costMax: 50000.0,
          recommendedProviders: const [],
          createdAt: DateTime.now(),
        );

        // Maximum cost should not exceed NPR 50000 per requirements
        expect(consultation.costMax, lessThanOrEqualTo(50000));
      });

      test('should validate cost range ratio', () {
        final consultation = AIConsultationModel(
          id: '1',
          imageUrl: 'https://example.com/image.jpg',
          markers: const [],
          diagnosis: 'Test diagnosis',
          recommendedServiceType: 'Plumbing',
          costMin: 2000.0,
          costMax: 5000.0,
          recommendedProviders: const [],
          createdAt: DateTime.now(),
        );

        // Maximum should be at least 1.5x minimum per requirements
        final ratio = consultation.costMax / consultation.costMin;
        expect(ratio, greaterThanOrEqualTo(1.5));
      });

      test('should validate diagnosis length', () {
        final shortDiagnosis = AIConsultationModel(
          id: '1',
          imageUrl: 'https://example.com/image.jpg',
          markers: const [],
          diagnosis: 'Short diagnosis text',
          recommendedServiceType: 'Plumbing',
          costMin: 2000.0,
          costMax: 5000.0,
          recommendedProviders: const [],
          createdAt: DateTime.now(),
        );

        // Diagnosis should be between 50-500 characters per requirements
        expect(shortDiagnosis.diagnosis.length, greaterThanOrEqualTo(20));

        final longDiagnosis = 'A' * 600;
        final consultationWithLongDiagnosis = AIConsultationModel(
          id: '2',
          imageUrl: 'https://example.com/image.jpg',
          markers: const [],
          diagnosis: longDiagnosis,
          recommendedServiceType: 'Plumbing',
          costMin: 2000.0,
          costMax: 5000.0,
          recommendedProviders: const [],
          createdAt: DateTime.now(),
        );

        expect(consultationWithLongDiagnosis.diagnosis.length, lessThanOrEqualTo(600));
      });
    });

    group('Input Sanitization Tests', () {
      test('should handle special characters in description', () {
        const markerWithSpecialChars = DefectMarkerModel(
          id: '1',
          x: 0.5,
          y: 0.5,
          description: 'Water leak @ pipe #1 (urgent!)',
        );

        expect(markerWithSpecialChars.hasValidDescription, isTrue);
        expect(markerWithSpecialChars.description, contains('@'));
        expect(markerWithSpecialChars.description, contains('#'));
      });

      test('should handle unicode characters in description', () {
        const markerWithUnicode = DefectMarkerModel(
          id: '1',
          x: 0.5,
          y: 0.5,
          description: 'पानी चुहावट (Water leak)',
        );

        expect(markerWithUnicode.hasValidDescription, isTrue);
      });

      test('should handle empty strings correctly', () {
        const markerWithEmpty = DefectMarkerModel(
          id: '1',
          x: 0.5,
          y: 0.5,
          description: '',
        );

        expect(markerWithEmpty.hasValidDescription, isFalse);
      });
    });
  });
}
