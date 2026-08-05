import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'constants.dart';

/// Global navigator key so ErrorHandler can recover the app to its root
/// route without needing a BuildContext of its own. Must be attached to
/// MaterialApp via `navigatorKey: ErrorHandler.navigatorKey` in main.dart.
class ErrorHandler {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void install() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exception}');
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: AppColors.bgPrimary,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Builder(
              builder: (context) {
                // `Builder` gives us a BuildContext that sits inside the
                // app's widget tree, so Localizations (and AppLocalizations)
                // resolve correctly even though ErrorWidget.builder itself
                // only receives FlutterErrorDetails, not a context.
                final l10n = AppLocalizations.of(context);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 64),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n?.errorTitle ?? 'Something went wrong',
                      style: AppTypography.headline
                          .copyWith(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n?.errorMessage ??
                          "We're sorry for the inconvenience. Please restart the app or try again.",
                      style: AppTypography.body
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => _recover(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        child: Text(
                          l10n?.retry ?? 'Retry',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    };
  }

  /// Recovers the app from a rendering error by returning to the root
  /// route. We deliberately use `popUntil` rather than
  /// `pushAndRemoveUntil` with a freshly-built HomeScreen: HomeScreen
  /// requires an already-initialized PlantProvider/LocalStorage, and
  /// reconstructing those from here would open a second sqflite
  /// connection and duplicate app state. popUntil(isFirst) gets the user
  /// off the dead-end crash screen and back to a live, already-working
  /// widget tree, which is the actual goal of the "Retry" button.
  static void _recover() {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      // No navigator attached (shouldn't happen once wired into
      // MaterialApp), but fail safely rather than throw.
      return;
    }
    if (nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
    // If there's nothing to pop, we're already at root — nothing to do.
  }
}
