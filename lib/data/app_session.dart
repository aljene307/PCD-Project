import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';

/// Lightweight in-memory session state.
///
/// During a Dart VM session (i.e. between hot reloads), these statics keep
/// track of which screen the user is on so reload doesn't bounce them back
/// to the onboarding flow.
///
/// A full hot-restart wipes static state, which is the expected dev behavior.
class AppSession {
  /// Unique session ID generated once per app launch.
  static final String userId = const Uuid().v4();

  /// Set to true after the user reaches the recommendations screen.
  static bool hasCompletedOnboarding = false;

  /// Currently selected bottom-nav tab index.
  /// 0 = Home, 1 = My Soil, 2 = My Climate, 3 = Crops
  static int currentTabIndex = 0;

  /// True when the user chose "Submit a Soil Report" on the onboarding screen.
  static bool labReportExists = false;

  /// True only when lab measurements were successfully extracted and posted to
  /// the backend. Use this (not labReportExists) to decide which API path to
  /// call — labReportExists can be true even when OCR failed.
  static bool get hasLabData =>
      labReportExists &&
      labMeasurements != null &&
      labMeasurements!.isNotEmpty;

  /// Bytes and name of the PDF selected on the upload screen (web).
  static Uint8List? soilReportBytes;
  static String? soilReportName;

  /// Measurements extracted from the soil lab report PDF.
  static List<LabMeasurement>? labMeasurements;

  /// Active advisor chat session ID (persists for the app lifecycle).
  static String? advisorSessionId;
}
