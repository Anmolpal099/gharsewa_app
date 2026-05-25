import 'package:flutter_test/flutter_test.dart';
import 'package:gharsewa/features/provider_panel/data/models/booking_request_status.dart';
import 'package:gharsewa/features/provider_panel/data/models/provider_profile.dart';
import 'package:gharsewa/features/provider_panel/data/models/certification.dart';

void main() {
  group('ProviderProfile.completeness', () {
    test('returns 0 when empty', () {
      final profile = _minimalProfile();
      expect(profile.completeness, 0);
    });

    test('returns 100 when all criteria met', () {
      final profile = _minimalProfile(
        photoUrl: 'https://example.com/p.jpg',
        bio: 'a' * 50,
        skills: ['a', 'b', 'c'],
        certifications: [
          Certification(
            id: '1',
            name: 'Test',
            documentUrl: 'https://x.com/c.pdf',
            fileType: 'PDF',
            isVerified: false,
            uploadedAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      expect(profile.completeness, 100);
    });

    test('adds 25 per completed segment', () {
      final withPhoto = _minimalProfile(photoUrl: 'x');
      expect(withPhoto.completeness, 25);
      final withBio = _minimalProfile(bio: 'x' * 50);
      expect(withBio.completeness, 25);
    });
  });

  group('BookingRequestStatus', () {
    test('parses from json name', () {
      expect(
        BookingRequestStatus.values.byName('counterOffered'),
        BookingRequestStatus.counterOffered,
      );
    });
  });
}

ProviderProfile _minimalProfile({
  String? photoUrl,
  String? bio,
  List<String> skills = const [],
  List<Certification> certifications = const [],
}) {
  final now = DateTime(2026, 1, 1);
  return ProviderProfile(
    id: '1',
    name: 'Test',
    email: 't@test.com',
    photoUrl: photoUrl,
    bio: bio,
    location: 'KTM',
    professionalCategory: 'Plumber',
    isVerified: false,
    skills: skills,
    certifications: certifications,
    createdAt: now,
    updatedAt: now,
  );
}
