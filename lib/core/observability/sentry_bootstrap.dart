import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> runWithSentry(Future<void> Function() appMain) async {
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (sentryDsn.isEmpty) {
    if (kDebugMode) {
      print('SENTRY_DSN is not set. Running without Sentry.');
    }
    await appMain();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      options.tracesSampleRate = 1.0;
      options.beforeSend = (event, hint) {
        // Scrub sensitive data
        if (event.user != null) {
          event = event.copyWith(
            user: event.user!.copyWith(
              email: event.user!.email != null ? '[REDACTED]' : null,
            ),
          );
        }
        if (event.request != null && event.request!.headers.containsKey('Authorization')) {
          final newHeaders = Map<String, String>.from(event.request!.headers)
            ..remove('Authorization');
          event = event.copyWith(
            request: event.request!.copyWith(headers: newHeaders),
          );
        }
        return event;
      };
    },
    appRunner: appMain,
  );
}

void sendSentrySmokeTestMessage() {
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  if (sentryDsn.isNotEmpty && kDebugMode) {
    Sentry.captureMessage('Sentry Smoke Test: App Initialized');
  }
}

