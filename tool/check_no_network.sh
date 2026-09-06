#!/usr/bin/env bash
# Netz-Wächter (docs/04-technik-architektur.md Abschnitt 10, D14).
# Schlägt fehl, wenn die App Netzwerkzugriff bekommen könnte:
#  1. android.permission.INTERNET im main- oder release-Manifest (oder im gemergten Release-Manifest, falls gebaut);
#  2. Pakete aus der Sperrliste in pubspec.lock (HTTP-Clients, Analytics, Crash-Reporter, Werbung, Cloud-SDKs);
#  3. Netzwerk-Entitlements oder Local-Network-Schlüssel in der iOS-Konfiguration;
#  4. Direkte Socket-/HTTP-Nutzung im Dart-Code der App und der Pakete.
# Für die spätere WLAN-Direktübertragung (D6, Version 1.x) wird diese Datei bewusst und sichtbar angepasst.
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
say() { printf '%s\n' "$*"; }
bad() { say "FEHLER: $*"; fail=1; }

# 1. Android-Manifeste
for m in app/android/app/src/main/AndroidManifest.xml app/android/app/src/release/AndroidManifest.xml \
         app/build/app/intermediates/merged_manifests/release/AndroidManifest.xml \
         app/build/app/intermediates/merged_manifest/release/AndroidManifest.xml; do
  # XML-Kommentare entfernen, damit erklärende Hinweise im Manifest nicht anschlagen.
  if [ -f "$m" ] && perl -0pe 's/<!--.*?-->//gs' "$m" | grep -qE 'uses-permission[^>]*android\.permission\.INTERNET'; then
    bad "INTERNET-Berechtigung in $m"
  fi
done
# Das Debug-Manifest darf INTERNET enthalten (Hot Reload); wir melden es nur.
if [ -f app/android/app/src/debug/AndroidManifest.xml ] && perl -0pe 's/<!--.*?-->//gs' app/android/app/src/debug/AndroidManifest.xml | grep -qE 'uses-permission[^>]*android\.permission\.INTERNET'; then
  say "Hinweis: Debug-Manifest enthält INTERNET (nur für Entwicklung, nicht im Release)."
fi

# 2. Sperrliste in pubspec.lock
blocklist='^  (http|dio|chopper|retrofit|firebase_[a-z_]+|cloud_firestore|sentry|sentry_flutter|bugsnag_flutter|datadog_flutter_plugin|amplitude_flutter|mixpanel_flutter|posthog_flutter|google_mobile_ads|facebook_app_events|appsflyer_sdk|adjust_sdk|onesignal_flutter|supabase_flutter|amplify_flutter|aws_[a-z_]+|googleapis|googleapis_auth|web_socket_channel|socket_io_client|grpc):$'
if [ -f pubspec.lock ]; then
  if hits=$(grep -E "$blocklist" pubspec.lock); then
    # web_socket_channel kommt transitiv über flutter_test/test hinein und ist im Release-Build nicht enthalten:
    # nur melden, wenn es als direkte Abhängigkeit eines Pakets eingetragen ist.
    while read -r line; do
      name=$(echo "$line" | tr -d ' :')
      if grep -rqs "^\s*$name:" app/pubspec.yaml packages/*/pubspec.yaml; then
        bad "Gesperrtes Paket als direkte Abhängigkeit: $name"
      else
        say "Hinweis: $name ist nur transitiv (Entwicklungswerkzeuge) im Lock enthalten."
      fi
    done <<< "$hits"
  fi
fi

# 3. iOS
for f in app/ios/Runner/Info.plist app/ios/Runner/Runner.entitlements app/ios/Runner/DebugProfile.entitlements app/ios/Runner/Release.entitlements; do
  if [ -f "$f" ]; then
    if grep -qE "NSLocalNetworkUsageDescription|NSBonjourServices|com.apple.developer.networking|NSAppTransportSecurity" "$f"; then
      bad "Netzwerk-Schlüssel oder -Entitlement in $f"
    fi
  fi
done

# 4. Dart-Quellen (ohne Tests)
if grep -rnE "HttpClient\(|Socket\.connect|ServerSocket\.bind|RawDatagramSocket|WebSocket\.connect|package:http/|package:dio/" \
     --include='*.dart' app/lib packages/*/lib 2>/dev/null; then
  bad "Netzwerk-API im Dart-Code gefunden (siehe oben)"
fi

if [ "$fail" -ne 0 ]; then
  say "Netz-Wächter: FEHLGESCHLAGEN"
  exit 1
fi
say "Netz-Wächter: bestanden (keine INTERNET-Berechtigung, keine gesperrten Pakete, keine Netzwerk-APIs)."
