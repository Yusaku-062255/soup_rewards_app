import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> runWithSentry(Future<void> Function() appMain) async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
      options.tracesSampleRate = 1.0;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      await appMain();
    },
  );
}

void sendSentrySmokeTestMessage() {
  Sentry.captureMessage('SOUP iOS build smoke test');
}
