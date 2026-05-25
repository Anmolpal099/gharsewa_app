import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lightweight i18n without codegen (Epic 7.6 / Task 28.x).
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale.languageCode);
});

class AppStrings {
  AppStrings(this.languageCode);

  final String languageCode;

  static const _en = {
    'appTitle': 'Gharsewa',
    'providerExplore': 'Explore',
    'providerBookings': 'Bookings',
    'providerSafety': 'Safety',
    'providerProfile': 'Profile',
    'generateSop': 'Generate SOP',
    'saveSop': 'Save SOP',
    'browseServices': 'Browse Services',
    'confirmBooking': 'Confirm Booking',
    'bookingConfirmed': 'Booking created successfully!',
    'selectTimeSlot': 'Select a time slot',
    'noSlots': 'No slots available for this date',
  };

  static const _ne = {
    'appTitle': 'घरसेवा',
    'providerExplore': 'अन्वेषण',
    'providerBookings': 'बुकिङ',
    'providerSafety': 'सुरक्षा',
    'providerProfile': 'प्रोफाइल',
    'generateSop': 'SOP उत्पादन गर्नुहोस्',
    'saveSop': 'SOP बचत गर्नुहोस्',
    'browseServices': 'सेवाहरू ब्राउज गर्नुहोस्',
    'confirmBooking': 'बुकिङ पुष्टि गर्नुहोस्',
    'bookingConfirmed': 'बुकिङ सफल भयो!',
    'selectTimeSlot': 'समय छान्नुहोस्',
    'noSlots': 'यो मितिमा कुनै स्लट छैन',
  };

  String get(String key) {
    final map = languageCode == 'ne' ? _ne : _en;
    return map[key] ?? _en[key] ?? key;
  }

  String get appTitle => get('appTitle');
  String get browseServices => get('browseServices');
  String get confirmBooking => get('confirmBooking');
  String get bookingConfirmed => get('bookingConfirmed');
  String get selectTimeSlot => get('selectTimeSlot');
  String get noSlots => get('noSlots');
}
