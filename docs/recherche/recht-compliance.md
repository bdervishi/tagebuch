# Recht und Compliance: Local-only Sprach-Tagebuch (iOS/Android, DACH + weltweit über die Stores)

Stand der Recherche: 3. September 2026. Lens: `recht-compliance`.

**Methodischer Hinweis (wichtig für die Autoren):** In dieser Sitzung war das Web-Suchkontingent erschöpft und der Netz-Proxy hat einen großen Teil der Primärquellen blockiert (gesetze-im-internet.de, dejure.org, buzer.de, eur-lex.europa.eu, edpb.europa.eu, support.google.com, play.google, bfarm.de, health.ec.europa.eu, fedlex.admin.ch, admin.ch, cyber.gouv.fr, bis.doc.gov, huggingface.co, Wikipedia). Direkt geprüft werden konnten: developer.apple.com (Dokumentation, App Store Connect Help, App Review Guidelines, News), developer.android.com, github.com (u. a. Whisper-/whisper.cpp-Lizenzen und der Gesetzes-Spiegel `bundestag/gesetze`, der allerdings auf einem Stand von 2021 ist). Alle Aussagen zu Google-Play-Richtlinien, EDPB/DSK-Papieren, MDR/MDCG, EAA-Richtlinientext, Schweizer Recht, AI Act, ANSSI/BIS sind deshalb **aus Kenntnisstand formuliert und mit `mustVerify` markiert** – sie müssen vor Verwendung in Konzeptdokumenten gegen die angegebene URL geprüft werden.

---

## 1. Ausgangslage: Was macht die App rechtlich aus?

- Audioaufnahme, Transkription und Speicherung erfolgen ausschließlich auf dem Gerät. Kein Konto, kein Server des Anbieters, keine Telemetrie.
- Optionaler Geräte-zu-Gerät-Transfer über eine komprimierte, verschlüsselte Datei; Übergabe wird per QR-Code initiiert.
- Monetarisierung später (z. B. Einmalkauf/Abo per In-App-Kauf).

Daraus folgen drei Rechtsebenen: (a) Datenschutzrecht (DSGVO, TDDDG, nDSG) – hier ist die App in einer ungewöhnlich günstigen Position; (b) Store-Compliance (Apple/Google) – hier gelten Pflichten unabhängig davon, ob Daten erhoben werden; (c) Produkt-/Verbraucherrecht (MDR-Abgrenzung, BFSG/EAA, DSA-Händlerstatus, Impressum, Widerruf, Exportkontrolle).

---

## 2. DSGVO bei rein lokaler Verarbeitung

**Kernaussage:** Solange keine personenbezogenen Daten den Anbieter (oder einen von ihm beauftragten Dienst) erreichen, verarbeitet der Anbieter die Tagebuchinhalte nicht und ist insoweit **nicht Verantwortlicher** i. S. v. Art. 4 Nr. 7 DSGVO. Der Nutzer selbst fällt für sein eigenes Tagebuch unter die Haushaltsausnahme (Art. 2 Abs. 2 lit. c DSGVO). Diese Einordnung ist herrschende Lesart, aber keine Aufsichtsbehörde hat sie für Tagebuch-Apps ausdrücklich bestätigt (`mustVerify`; Anhaltspunkt: Art. 4 Nr. 7, Art. 2 Abs. 2 lit. c DSGVO, https://eur-lex.europa.eu/eli/reg/2016/679/oj).

**Der Anbieter bleibt trotzdem Verantwortlicher für:**
- Support-Kommunikation (E-Mail), Website, Newsletter.
- Store-Berichte (Verkaufs-/Absturzdaten, die Apple/Google aggregiert an ihn liefern; Apple/Google sind hierfür eigene Verantwortliche).
- Jede später ergänzte Funktion, die Daten überträgt (Cloud-Sync, Analytics, Crash-SDKs, KI-Zusammenfassungen in der Cloud). Ab diesem Moment gilt das volle Programm (Art. 13, Art. 25, Art. 30, ggf. Art. 35 DSFA wegen Sprachdaten/Gesundheitsbezug).

**Datenschutzerklärung trotzdem nötig?** Ja – nicht aus Art. 13 DSGVO (mangels Erhebung), sondern weil beide Stores sie für **alle** Apps verlangen:
- Apple App Review Guideline 5.1.1(i): „All apps must include a link to their privacy policy in the App Store Connect metadata field and within the app in an easily accessible manner." Die Erklärung muss u. a. „explain its data retention/deletion policies and describe how a user can revoke consent and/or request deletion" (https://developer.apple.com/app-store/review/guidelines/, abgerufen 3.9.2026).
- App Store Connect: „You're required to provide a privacy policy URL for your iOS app platform" (https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy, abgerufen 3.9.2026).
- Google Play User-Data-Richtlinie: Datenschutzerklärung für alle Apps in der Play Console **und** in der App (seit 2022) – `mustVerify`, https://support.google.com/googleplay/android-developer/answer/10144311.

**Privacy by Design (Art. 25 DSGVO) als Nachweis:** Rechtlich verpflichtet Art. 25 nur Verantwortliche; für eine local-only App ist er vor allem ein **Positionierungs- und Nachweisinstrument**. Empfohlene, belegbare Maßnahmen: Threat-Model-Dokument, Liste aller ausgehenden Netzwerkverbindungen (Ziel: null, außer Store/Update-Mechanismen des OS), Datenflussdiagramm, reproduzierbarer Build, Open-Source-Kern oder unabhängiger Kurz-Audit. Apples HIG formuliert das als Designprinzip: „Process data on the device where possible." (https://developer.apple.com/design/human-interface-guidelines/privacy, abgerufen 3.9.2026).

**Versteckte Datenabflüsse, die die „keine Cloud"-Aussage gefährden:**
1. **OS-Backups.** iOS sichert `Documents` und `Application Support` standardmäßig in iCloud Backup; Ausschluss über `isExcludedFromBackup`, wobei Apple warnt, dies sei „not a mechanism to guarantee those items never appear in a backup or on a restored device" (https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup, abgerufen 3.9.2026). Android Auto Backup sichert bis 25 MB pro App in Google Drive, „End-to-end encrypted on Android 9+ using the device's PIN, pattern, or password"; Steuerung über `android:allowBackup`, `dataExtractionRules` (Android 12+) und `requireFlags="clientSideEncryption"` (https://developer.android.com/identity/data/autobackup, abgerufen 3.9.2026). Audio-Tagebücher sprengen 25 MB schnell; d. h. Android-Backup ist ohnehin kein tragfähiger Weg – der eigene verschlüsselte Export ist die Antwort.
2. **System-Spracherkennung.** Apples `SFSpeechRecognizer` sendet Audio an Apple-Server, sofern nicht `requiresOnDeviceRecognition = true` gesetzt ist und das Gerät `supportsOnDeviceRecognition` meldet: „Set this property to true to prevent an SFSpeechRecognitionRequest from sending audio over the network. However, on-device requests won't be as accurate." (https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition). Der neue `SpeechAnalyzer`/`SpeechTranscriber` (iOS 26+) ist laut Apple rein lokal: „SpeechAnalyzer transcriber modules don't send audio data of the user's voice to Apple's servers." (https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition, abgerufen 3.9.2026). Android: `SpeechRecognizer.createOnDeviceSpeechRecognizer()` (API 31) – Verfügbarkeit hängt vom Gerät und dem installierten Erkennungsdienst (meist Google) ab (https://developer.android.com/reference/android/speech/SpeechRecognizer). Konsequenz: Wer „ausschließlich lokal" garantieren will, sollte ein eigenes eingebettetes Modell (whisper.cpp, WhisperKit, sherpa-onnx) nutzen oder die OS-API nur mit hartem On-Device-Flag verwenden.
3. **Crash-/Analytics-SDKs.** Jede solche Bibliothek macht das Apple-Label „Data Not Collected" unmöglich und löst § 25 TDDDG-Einwilligungen aus. Empfehlung: keine.

---

## 3. TDDDG § 25 (Zugriff auf Endeinrichtungen)

Wortlaut (identisch mit § 25 TTDSG; Umbenennung in TDDDG zum 14.5.2024, Spiegel-Quelle Stand 2021, `mustVerify` für aktuelle Fassung: https://www.gesetze-im-internet.de/tddsg/__25.html):

> (1) Die Speicherung von Informationen in der Endeinrichtung des Endnutzers oder der Zugriff auf Informationen, die bereits in der Endeinrichtung gespeichert sind, sind nur zulässig, wenn der Endnutzer auf der Grundlage von klaren und umfassenden Informationen eingewilligt hat. […]
> (2) Die Einwilligung nach Absatz 1 ist nicht erforderlich, […] 2. wenn die Speicherung von Informationen in der Endeinrichtung des Endnutzers oder der Zugriff auf bereits in der Endeinrichtung des Endnutzers gespeicherte Informationen unbedingt erforderlich ist, damit der Anbieter eines Telemediendienstes einen vom Nutzer ausdrücklich gewünschten Telemediendienst zur Verfügung stellen kann.

(Quelle des Wortlauts: https://github.com/bundestag/gesetze/blob/master/t/ttdsg/index.md)

Einordnung: Apps sind digitale Dienste/Telemedien; die DSK-Orientierungshilfe Telemedien (Version 1.1, Dezember 2022) und die EDPB Guidelines 2/2023 zum technischen Anwendungsbereich von Art. 5 Abs. 3 ePrivacy-RL (Endfassung Oktober 2024) legen „Speichern/Zugriff" weit aus (`mustVerify`: https://www.datenschutzkonferenz-online.de/media/oh/20221205_oh_Telemedien_2021_Version_1_1.pdf; https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-22023-technical-scope-art-53-eprivacy-directive_en). Für das Speichern von Tagebucheinträgen, Erinnerungszeit, Einstellungen und Transkripten greift jedoch die Ausnahme Abs. 2 Nr. 2: exakt das ist der „ausdrücklich gewünschte" Dienst. **Keine Einwilligungs-Banner nötig**, solange keine Drittzugriffe (Werbe-IDs, Fingerprinting, Analytics) hinzukommen. Mikrofon-Zugriff ist ein Fall von „Zugriff auf Informationen"; die OS-Berechtigungsabfrage plus klare Zweckangabe deckt Information und Einwilligung praktisch ab – dennoch sollte die Datenschutzerklärung den Mikrofon-Zweck erläutern.

---

## 4. Apple: App Privacy „Nutrition Label", Privacy Manifest, Required Reason APIs, Berechtigungstexte

**Nutrition Label.** Apple definiert: „'Collect' refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time." und ausdrücklich: „Data that is processed only on device is not 'collected' and does not need to be disclosed in your answers." (https://developer.apple.com/app-store/app-privacy-details/, abgerufen 3.9.2026). Damit kann die App bei konsequenter Umsetzung **„Data Not Collected"** deklarieren (App Store Connect: „No, we do not collect data from this app"). Pflicht: „You're responsible for keeping your responses accurate and up to date." Ein Geräte-zu-Geräte-Transfer ohne Anbieter-Server ist kein „collect" (`mustVerify` für den Sonderfall; Apple-Definition spricht nur von Zugriff durch „you and/or your third-party partners").

**Privacy Manifest (`PrivacyInfo.xcprivacy`).** Enthält `NSPrivacyTracking`, `NSPrivacyTrackingDomains`, `NSPrivacyCollectedDataTypes`, `NSPrivacyAccessedAPITypes` (https://developer.apple.com/documentation/bundleresources/privacy-manifest-files). Seit 1.5.2024: „apps that don't describe their use of required reason API in their privacy manifest file aren't accepted by App Store Connect." (https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api). Für ein Sprach-Tagebuch realistisch relevante Kategorien und Codes (https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons, abgerufen 3.9.2026):
- `NSPrivacyAccessedAPICategoryFileTimestamp` → `C617.1` („access the timestamps, size, or other metadata of files inside the app container…"), ggf. `DDA9.1` (Anzeige von Zeitstempeln an den Nutzer; „may not be sent off-device").
- `NSPrivacyAccessedAPICategoryUserDefaults` → `CA92.1` (nur app-eigene Einstellungen, z. B. Erinnerungszeit).
- `NSPrivacyAccessedAPICategoryDiskSpace` → `E174.1` („check whether there is sufficient disk space to write files" – vor einer Aufnahme sinnvoll; „must behave differently based on disk space in a way that is observable to users").
- `NSPrivacyAccessedAPICategorySystemBootTime` → `35F9.1` (Zeitmessung, Aufnahmedauer) oder `8FFB.1` (absolute Zeitstempel für AVFAudio-Ereignisse).
Drittanbieter-SDKs aus Apples Liste benötigen eigenes Manifest und Signatur (https://developer.apple.com/support/third-party-SDK-requirements/).

**Berechtigungstexte.** `NSMicrophoneUsageDescription` ist Pflicht; ohne Key schlägt die Autorisierung fehl (https://developer.apple.com/documentation/bundleresources/information-property-list/nsmicrophoneusagedescription). `NSSpeechRecognitionUsageDescription` ist nur nötig, wenn `SFSpeechRecognizer` verwendet wird; dann gilt: „If this key is not present, your app will crash when it attempts to request authorization" (https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition). HIG-Vorgabe: „Aim for a brief, complete sentence that's straightforward, specific, and easy to understand." Positivbeispiel Apple: „The app records during the night to detect snoring sounds." Negativbeispiel: „Microphone access is needed for a better experience." Guideline 2.5.14: „Apps must request explicit user consent and provide a clear visual and/or audible indication when recording" – also sichtbare Aufnahmeanzeige einbauen.

**Altersfreigabe.** Seit 24.7.2025 gibt es die Stufen 4+, 9+, 13+, 16+, 18+; Antworten auf den neuen Fragebogen waren bis 31.1.2026 Pflicht; seit September 2026 sind zusätzlich Fragen zu „social media capabilities" verpflichtend (https://developer.apple.com/news/, Einträge 24.7.2025 und 9.7.2026). Relevante Definitionen: „Health or Wellness Topics: Content that provides self-care or lifestyle recommendations" → 9+; „Infrequent medical or treatment information" → 13+; „Frequent medical or treatment information" → 16+ (https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions, abgerufen 3.9.2026). Ein reines Tagebuch ohne Empfehlungen kann 4+ bleiben; sobald „Wohlbefindens-Tipps" hinzukommen, 9+.

**Accessibility Nutrition Labels** (iOS 26+): derzeit freiwillig, „over time, you'll be required to share accessibility support details to submit new apps and app updates" (https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels, abgerufen 3.9.2026).

**Journaling Suggestions.** Entitlement `com.apple.developer.journal.allow` (Wert `suggestions`), iOS 17.2+, wird laut Doku über die Xcode-Capability „Journaling Suggestions" hinzugefügt; der Picker „fails to present without it". Die App erhält nur die Daten der vom Nutzer gewählten Suggestion; Apple verweist für die Verwendung auf das Developer Program License Agreement („Suggestion data requires careful handling") (https://developer.apple.com/documentation/journalingsuggestions/presenting-the-suggestions-picker-and-processing-a-selection, abgerufen 3.9.2026). Ob Apple die Capability nur nach Antrag freischaltet und welche DPLA-Klauseln (z. B. Werbeverbot, kein Off-Device-Transfer) exakt gelten: `mustVerify` (Formular hinter Login: https://developer.apple.com/contact/request/journaling-suggestions/). Wichtig: „StateOfMind"-Suggestions sind Gesundheitsdaten-nah → Guideline 5.1.3 (keine Speicherung von Gesundheitsdaten in iCloud, keine Werbenutzung).

---

## 5. Google Play: Data Safety, Health-Apps, Berechtigungen (überwiegend `mustVerify`)

- **Data Safety.** Der offizielle Leitfaden bestätigt: „you alone are responsible for making complete and accurate declarations" und nennt den Datentyp „Voice or sound recordings – A user's voice such as a voicemail or a sound recording" (https://developer.android.com/guide/topics/data/collect-share, abgerufen 3.9.2026). Nach Kenntnisstand definiert Google „Erhebung" als Übertragung vom Gerät weg; rein lokale und ephemere Verarbeitung müssen nicht als „erhoben" deklariert werden; Datenschutzerklärungs-URL ist für alle Apps Pflicht (`mustVerify`: https://support.google.com/googleplay/android-developer/answer/10787469). Damit ist „Es werden keine Daten erhoben" auch bei Google erreichbar.
- **Health-Apps-Richtlinie** (in Kraft seit 2024): Apps mit Gesundheits-/Wellness-Funktionen müssen sich in der Play Console als Health-App deklarieren; irreführende Gesundheitsaussagen sind verboten (`mustVerify`: https://support.google.com/googleplay/android-developer/answer/12261419). Die Health-Connect-Deklaration kennt Kategorien wie „Stress management, relaxation, mental acuity" (Health & Fitness) und „Mental and behavioral health" (Medical) und verlangt: „Only request permissions and access data types that support the specific, user-facing health features you offer." (https://developer.android.com/health-and-fitness/guides/health-connect/publish/request-access, abgerufen 3.9.2026). Empfehlung: In Version 1 **keine** Health-Connect-/HealthKit-Integration, um Deklarations- und Review-Aufwand zu vermeiden.
- **Mikrofon.** `RECORD_AUDIO` ist Laufzeitberechtigung; Google empfiehlt Anfrage im Kontext: „only prompt for microphone access when a user clicks on the microphone button" (https://developer.android.com/training/permissions/usage-notes). Android 12+ zeigt Mikrofon-Indikator und Privacy Dashboard; eine Rationale-Activity (`VIEW_PERMISSION_USAGE`) kann den Zweck erklären (https://developer.android.com/training/permissions/explaining-access). Für Aufnahme im Hintergrund: Foreground Service Typ `microphone` mit `FOREGROUND_SERVICE_MICROPHONE`; „you cannot create a microphone foreground service while your app is in the background"; ab targetSdk 34 Deklaration der FGS-Typen in der Play Console (Policy > App content) (https://developer.android.com/develop/background-work/services/fgs/service-types, abgerufen 3.9.2026).
- **Altersfreigabe** über den IARC-Fragebogen in der Play Console (kostenlos, erzeugt USK/PEGI/ESRB); ein Tagebuch ohne Nutzerinteraktion untereinander landet typischerweise bei USK 0 / PEGI 3 (`mustVerify`: https://support.google.com/googleplay/android-developer/answer/9859655). Zielgruppe bewusst „18+"/„13+" wählen, um nicht unter die Families-Policy zu fallen (`mustVerify`).
- **DSA-Händlerstatus** auch bei Google Play seit 2024 Pflichtangabe; Händler-Kontaktdaten werden im Store angezeigt (`mustVerify`: Play Console Hilfe „EU Digital Services Act").

---

## 6. US-Exportkontrolle für Verschlüsselung (App Store, Android analog)

Apple: „When you submit your app to TestFlight or the App Store, you upload your app to a server in the United States. If you distribute your app outside the U.S. or Canada, your app is subject to U.S. export laws, regardless of where your legal entity is based." (https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations, abgerufen 3.9.2026).

Apples Dokumentationstabelle (https://developer.apple.com/help/app-store-connect/reference/export-compliance-documentation-for-encryption, abgerufen 3.9.2026):
| Verschlüsselung | Erforderliche Doku |
|---|---|
| nur OS-Verschlüsselung (CryptoKit, Keychain, Data Protection, URLSession/HTTPS) | keine Dokumentation in App Store Connect |
| Industriestandard-Algorithmus, **nicht** vom Apple-OS bereitgestellt (z. B. gebündeltes libsodium/OpenSSL/age) | französische Verschlüsselungs-Deklaration hochladen (nur bei Vertrieb in Frankreich) |
| proprietäre Algorithmen | US-CCATS **und** französische Deklaration |

Info.plist: `ITSAppUsesNonExemptEncryption` (`NO`, wenn keine oder nur exempt-Verschlüsselung) bzw. `ITSEncryptionExportComplianceCode` nach Freigabe. Jahresbericht: „If your app uses exempt forms of encryption, you might alternatively be required to submit a year-end self-classification report to the U.S. government." (BIS Annual Self-Classification Report, Frist 1. Februar, per E-Mail an BIS und NSA – `mustVerify`: https://www.bis.doc.gov/index.php/policy-guidance/encryption/4-reports-and-reviews/a-annual-self-classification). Frankreich: Apple nennt als Kontrollkategorien „Secure Storage, Secure Communications, and Security Anti-Virus applications" – ein verschlüsselter Tagebuch-Export ist „Secure Storage" (https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance); die ANSSI-Deklaration nach Décret 2007-663 ist gebührenfrei (`mustVerify`: https://cyber.gouv.fr/reglementation-des-moyens-de-cryptologie).

**Praktische Empfehlung:** Transferdatei ausschließlich mit OS-Kryptografie verschlüsseln (iOS: CryptoKit AES-GCM/ChaChaPoly + Keychain; Android: `javax.crypto`/Android Keystore, ggf. Jetpack Security). Dann: `ITSAppUsesNonExemptEncryption = NO` vertretbar, keine französische Deklaration, kein CCATS. Konservative Variante: im Fragebogen „verwendet Verschlüsselung / qualifiziert für Ausnahme" beantworten und den kostenlosen BIS-Jahresbericht einreichen. Für Android gibt es keinen Fragebogen, die EAR gilt aber ebenso (Upload zu Google-Servern in den USA) – gleiche technische Entscheidung löst das Problem.

---

## 7. Medizinprodukt-Abgrenzung (EU MDR, MDCG 2019-11, BfArM) – was die App behaupten darf

Maßgeblich ist die **Zweckbestimmung des Herstellers** (MDR Art. 2 Nr. 1, Nr. 12). MDCG 2019-11 (Rev. 1 vom Juni 2025, `mustVerify`) stellt klar: Software, die nur „storage, archival, communication, simple search, lossless compression" leistet, ist keine Medical Device Software; Lifestyle-/Wellbeing-Apps ohne medizinische Zweckbestimmung fallen nicht unter die MDR (`mustVerify`: https://health.ec.europa.eu/system/files/2020-09/md_mdcg_2019_11_guidance_qualification_classification_software_en_0.pdf). Die BfArM-Orientierungshilfe „Medical Apps" nennt Tagebuch-/Dokumentationsfunktionen ohne Auswertung als Beispiel für Nicht-Medizinprodukte; sobald die App Daten **bewertet** und daraus Diagnose-, Überwachungs- oder Therapiehinweise ableitet, wird sie Medizinprodukt (bei psychischer Gesundheit i. d. R. Klasse IIa nach Regel 11) (`mustVerify`: https://www.bfarm.de/DE/Medizinprodukte/Aufgaben/Abgrenzung-und-Klassifizierung/Orientierungshilfe-Medical-Apps/_node.html).

Store-seitig verschärft Apple: „Medical apps that could provide inaccurate data or information, or that could be used for diagnosing or treating patients may be reviewed with greater scrutiny" und „Apps must clearly disclose data and methodology to support accuracy claims relating to health measurements" (Guideline 1.4.1). Die Whisper-Modellkarte warnt zudem: „use of the model for classification is not only not evaluated but also not appropriate, particularly to infer human attributes" (https://github.com/openai/whisper/blob/main/model-card.md).

**Erlaubt (kein Medizinprodukt):** vom Nutzer selbst gewählte Stimmungs-Tags/Emojis; Statistik „an wie vielen Tagen hast du aufgenommen"; Wortwolken; Rückblick „vor einem Jahr"; neutrale Reflexionsfragen („Wofür warst du heute dankbar?").
**Riskant (Medizinprodukt-/AI-Act-/Store-Risiko):** automatische Stimmungs- oder Emotionserkennung aus der Stimme; „Erkennt Anzeichen von Stress/Depression"; „Überwacht dein mentales Wohlbefinden"; Trend-Warnungen mit Handlungsempfehlung. Automatische Emotionserkennung wäre zudem ein „Emotionserkennungssystem" nach AI Act Art. 3 Nr. 39 mit Transparenzpflicht nach Art. 50 Abs. 3 (gilt seit 2.8.2026; Verbot nur am Arbeitsplatz/in Bildungseinrichtungen, Art. 5) – `mustVerify`: https://eur-lex.europa.eu/eli/reg/2024/1689/oj.

---

## 8. European Accessibility Act / BFSG (DE), BaFG (AT), Schweiz

BFSG § 3 Abs. 3 (Wortlaut, Spiegel-Quelle): „Absatz 1 gilt nicht für Kleinstunternehmen, die Dienstleistungen anbieten oder erbringen." (https://github.com/bundestag/gesetze/blob/master/b/bfsg/index.md; aktuelle Fassung `mustVerify`: https://www.gesetze-im-internet.de/bfsg/__3.html). Kleinstunternehmen = weniger als 10 Beschäftigte **und** Jahresumsatz oder Bilanzsumme ≤ 2 Mio. EUR (Art. 3 Nr. 23 RL (EU) 2019/882; `mustVerify`: https://eur-lex.europa.eu/eli/dir/2019/882/oj). Das BFSG gilt seit 28.6.2025. Der sachliche Anwendungsbereich erfasst bei Apps vor allem „Dienstleistungen im elektronischen Geschäftsverkehr" (§ 1 Abs. 3 Nr. 5, § 2 Nr. 26 BFSG) – also den Kaufvorgang; ob eine Tagebuch-App als solche selbst erfasst ist, ist umstritten; der In-App-Kauf über Apple/Google ist deren E-Commerce-Dienst (`mustVerify`). Fazit: Für einen Indie-Inhaber (Kleinstunternehmen) besteht **keine BFSG-Pflicht** für die App-Dienstleistung; die Ausnahme entfällt, sobald die 10-Personen-/2-Mio.-Schwelle überschritten wird. Österreich hat mit dem Barrierefreiheitsgesetz (BaFG, BGBl. I Nr. 76/2023) dieselbe Kleinstunternehmen-Ausnahme (`mustVerify`). Schweiz: Der EAA gilt nicht; das BehiG verpflichtet Bund und Konzessionäre; private Anbieter trifft nur das Diskriminierungsverbot (Art. 6 BehiG); eine Revision mit Pflichten für private Dienstleistungen ist in Vorbereitung (`mustVerify`: https://www.fedlex.admin.ch/eli/cc/2003/667/de).
**Soll-Empfehlung unabhängig von der Pflicht:** VoiceOver/TalkBack-Labels, Dynamic Type, Kontrast, Untertitel = Transkript (ohnehin Kernfunktion). Damit sind Apples Accessibility Nutrition Labels später ausfüllbar.

---

## 9. DSA-Händlerstatus, Impressum, Verbraucherrechte

**DSA (Apple, verifiziert):** Händler ist, wer „acting … for purposes relating to his or her trade, business, craft or profession"; Faktoren: „Whether you make revenue as a result of your app, for example if your app includes In-App Purchases" (https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements, abgerufen 3.9.2026). Einzelpersonen müssen „Address or P.O. Box", Telefon und E-Mail (jeweils per 2FA verifiziert) hinterlegen; Apple veröffentlicht sie auf der Produktseite in allen 27 EU-Storefronts. Nicht-Händler: „consumers in the EU will be informed that consumer rights stemming from applicable consumer protection laws won't apply". Sobald monetarisiert wird, ist der Status Händler zwingend. Apple entfernte ab 17.2.2025 Apps ohne Status aus dem EU-Store (`mustVerify`).

**Impressum (DE):** § 5 DDG (bis Mai 2024 § 5 TMG) verpflichtet Anbieter geschäftsmäßiger, in der Regel entgeltlicher digitaler Dienste zu Name, Anschrift, E-Mail, ggf. Register/USt-IdNr.; Angaben müssen „leicht erkennbar, unmittelbar erreichbar und ständig verfügbar" sein → **innerhalb der App** (z. B. Einstellungen > Rechtliches), nicht nur auf der Store-Seite (`mustVerify`: https://www.gesetze-im-internet.de/ddg/__5.html). Österreich: § 5 ECG und § 25 MedienG; Schweiz: Art. 3 Abs. 1 lit. s UWG (Identität und Kontaktadresse im E-Commerce) (`mustVerify`).

**Widerruf bei In-App-Käufen:** § 356 Abs. 5 BGB: Das Widerrufsrecht erlischt bei digitalen Inhalten, wenn der Unternehmer mit der Ausführung begonnen hat, nachdem der Verbraucher „1. ausdrücklich zugestimmt hat, dass der Unternehmer mit der Ausführung des Vertrags vor Ablauf der Widerrufsfrist beginnt, und 2. seine Kenntnis davon bestätigt hat, dass er durch seine Zustimmung mit Beginn der Ausführung des Vertrags sein Widerrufsrecht verliert" (Spiegel-Fassung 2021: https://github.com/bundestag/gesetze/blob/master/b/bgb/index.md; seit 28.5.2022 zusätzlich Nr. 3: Vertragsbestätigung nach § 312f – `mustVerify`: https://www.gesetze-im-internet.de/bgb/__356.html). In der Praxis sind bei Store-IAP Apple bzw. Google Vertragspartner/Händler für den Kauf und wickeln Widerruf/Erstattung über ihre Nutzungsbedingungen ab; der Entwickler muss nur die Store-Regeln einhalten (Guideline 3.1.1: Funktionen dürfen nur über In-App-Kauf freigeschaltet werden, „not … license keys, … QR codes"). Achtung: Der QR-Code für den Transfer darf keine Freischaltfunktion haben. Bei alternativem Vertrieb (DMA) würde der Entwickler selbst Verkäufer – dann volle Fernabsatzpflichten (`mustVerify`).

---

## 10. Aufbewahrung und Löschung bei lokalen Daten

Es gibt keine gesetzliche Aufbewahrungspflicht für Nutzerinhalte auf dem Gerät; der Nutzer ist Herr der Daten. Store-Pflicht (Apple 5.1.1(i)): Datenschutzerklärung muss Aufbewahrung/Löschung erklären. Empfohlenes Design: Löschen einzelner Einträge, „Alle Daten löschen" mit Bestätigung, Hinweis, dass Deinstallation alles entfernt; Aufbewahrungsregel optional (z. B. Audio nach X Monaten automatisch löschen, Text behalten); iOS Data Protection `NSFileProtectionComplete`, Android Keystore-basierte Dateiverschlüsselung; klarer Hinweis auf OS-Backups mit Opt-out-Schalter. Für den Transfer: kurzlebiger Sitzungsschlüssel aus dem QR-Code, Datei nach erfolgreichem Import auf beiden Seiten löschen, Hinweis, dass die Exportdatei nur so sicher ist wie ihr Passwort/Schlüssel.

---

## 11. Open-Source-Lizenzen für Sprachmodelle in kommerziellen Apps

| Komponente | Lizenz | Quelle (abgerufen 3.9.2026) |
|---|---|---|
| OpenAI Whisper (Code **und** Gewichte) | MIT – „Whisper's code and model weights are released under the MIT License." | https://github.com/openai/whisper |
| whisper.cpp | MIT, © 2023–2026 The ggml authors | https://github.com/ggml-org/whisper.cpp/blob/master/LICENSE |
| WhisperKit (argmaxinc, CoreML) | MIT; Pro-SDK kommerziell | https://github.com/argmaxinc/WhisperKit |
| sherpa-onnx (Android/iOS, Zipformer/Whisper/SenseVoice u. a.) | Apache-2.0; Modell-Lizenzen separat prüfen | https://github.com/k2-fsa/sherpa-onnx |

Pflichten: MIT → Copyright- und Lizenzhinweis in der App mitliefern („The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software"). Apache-2.0 → zusätzlich NOTICE-Datei übernehmen, Änderungen kennzeichnen. CC-BY-Modelle → Namensnennung; **CC-NC-Modelle sind für eine bezahlte App tabu**. Modellgrößen für Planung: whisper.cpp ggml `tiny` 75 MiB, `base` 142 MiB, `small` 466 MiB, `large-v3-turbo-q5_0` 547 MiB (https://github.com/ggml-org/whisper.cpp/blob/master/models/README.md). Ethische Nutzungshinweise der Whisper-Modellkarte (kein Transkribieren ohne Einwilligung Dritter) in die Nutzungsbedingungen aufnehmen: Das Tagebuch ist für die eigene Stimme gedacht.

---

## 12. Schweiz (nDSG) und Österreich – Kurzfassung (`mustVerify`)

nDSG in Kraft seit 1.9.2023 (https://www.fedlex.admin.ch/eli/cc/2022/491/de): Art. 2 Abs. 2 lit. a nimmt Daten aus, die eine natürliche Person „ausschliesslich zum persönlichen Gebrauch" bearbeitet; der Anbieter ist bei local-only nicht Verantwortlicher für Tagebuchinhalte. Art. 19 (Informationspflicht) und Art. 7 (Datenschutz durch Technik und Voreinstellungen) greifen für Support-/Website-Daten. Bussen bis CHF 250'000 richten sich gegen natürliche Personen bei vorsätzlicher Verletzung u. a. der Informationspflicht. Ein Vertreter in der Schweiz (Art. 14) ist nur bei umfangreicher, risikoreicher Bearbeitung nötig – hier nicht. Österreich: DSG ergänzt DSGVO; für Impressum ECG/MedienG; Verbraucherrechte FAGG; Barrierefreiheit BaFG.

---

## 13. Checkliste Muss / Soll / Kann

**MUSS**
1. Datenschutzerklärung (URL im Store + in der App erreichbar), die erklärt: keine Erhebung, Mikrofonzweck, lokale Speicherung, OS-Backups, Export/Transfer, Löschung, Kontakt. (Apple 5.1.1; Google User Data Policy)
2. Apple Privacy Label korrekt („Data Not Collected") und Google Data Safety („Keine Daten erhoben/weitergegeben"); bei jeder Funktionsänderung aktualisieren.
3. `PrivacyInfo.xcprivacy` mit Required-Reason-Codes (C617.1, CA92.1, E174.1, 35F9.1/8FFB.1 je nach Nutzung).
4. `NSMicrophoneUsageDescription` (und nur bei `SFSpeechRecognizer`: `NSSpeechRecognitionUsageDescription`); Android `RECORD_AUDIO` im Kontext anfragen; sichtbare Aufnahmeanzeige (Guideline 2.5.14).
5. Exportkontroll-Frage in App Store Connect beantworten; `ITSAppUsesNonExemptEncryption` setzen; bei nicht-OS-Krypto: französische Deklaration; ggf. BIS-Jahresbericht bis 1.2.
6. DSA-Händlerstatus (Apple und Google) mit verifizierter Adresse/Telefon/E-Mail, spätestens vor Monetarisierung.
7. Impressum nach § 5 DDG / § 5 ECG in der App.
8. Altersfreigabe-Fragebögen (Apple neu seit 2025, inkl. Social-Media-Fragen ab 9/2026; IARC bei Google).
9. Open-Source-Lizenzhinweise (MIT/Apache) in der App.
10. Keine Gesundheits-/Diagnose-Claims; keine automatische Emotionserkennung ohne rechtliche Prüfung (MDR, AI Act, Guideline 1.4.1).
11. Freischaltung nur über Store-IAP (Guideline 3.1.1); QR-Code darf nichts freischalten.

**SOLL**
1. Vollständiger Backup-Opt-out (iOS `isExcludedFromBackup`, Android `allowBackup`/`dataExtractionRules`) mit erklärendem Schalter.
2. Eigenes eingebettetes Modell statt OS-Cloud-Spracherkennung, oder hartes On-Device-Flag; iOS 26 `SpeechAnalyzer` als Apple-eigener lokaler Pfad.
3. Transfer-Verschlüsselung nur mit OS-Kryptobibliotheken (vereinfacht Exportkontrolle).
4. Barrierefreiheit (VoiceOver/TalkBack, Dynamic Type, Kontrast) trotz Kleinstunternehmen-Ausnahme; Accessibility Nutrition Labels ausfüllen.
5. Privacy-by-Design-Dossier (Datenflussdiagramm, Netzwerk-Null-Nachweis, Threat Model) als Vertrauens- und Marketing-Asset.
6. „Alles löschen"-Funktion und optionale Auto-Löschregel für Audio.
7. Health Connect/HealthKit/State of Mind in v1 weglassen.
8. Zielgruppe im Play Store nicht „Kinder" (Families-Policy vermeiden).

**KANN**
1. Journaling-Suggestions-Picker (iOS 17.2+) – nach Prüfung der DPLA-Bedingungen.
2. Unabhängiger Kurz-Audit oder Open-Source-Kern als Nachweis „keine Cloud".
3. Schweizer/US-Storefront-Texte mit lokal angepassten Rechtsangaben.
4. Freiwillige Selbstverpflichtung („Wir werden nie Analytics einbauen") als Teil der Datenschutzerklärung – rechtlich bindend über Unterlassung, deshalb bewusst formulieren.

---

## 14. Formulierungshilfen

**Berechtigungstext Mikrofon (iOS `NSMicrophoneUsageDescription`, DE):**
„[App] nimmt deine Tagebucheinträge mit dem Mikrofon auf. Die Aufnahme bleibt auf deinem Gerät und wird dort in Text umgewandelt."
(EN): „[App] records your diary entries with the microphone. Recordings stay on your device and are transcribed there."

**Android-Rationale (vor der Systemabfrage):**
„Zum Aufnehmen deines Eintrags braucht [App] Zugriff auf das Mikrofon. Aufnahme und Transkription laufen vollständig auf diesem Gerät – nichts wird hochgeladen."

**Kurz-Datenschutzerklärung (Kern, DE):**
„[App] erhebt keine personenbezogenen Daten. Aufnahmen, Transkripte und Einstellungen werden ausschließlich auf deinem Gerät gespeichert und verarbeitet. Es gibt kein Nutzerkonto, keine Server des Anbieters, keine Analyse- oder Werbedienste. Die Spracherkennung erfolgt mit einem auf dem Gerät installierten Modell ohne Internetverbindung. Hinweis: Wenn du die Geräte-Sicherung deines Betriebssystems (iCloud-Backup / Google-Backup) aktiviert hast, können App-Daten Teil dieser Sicherung sein; du kannst das in den Einstellungen von [App] ausschalten. Der optionale Transfer auf ein anderes Gerät erzeugt eine verschlüsselte Datei, die nur du besitzt; der Anbieter hat darauf keinen Zugriff. Du löschst einzelne Einträge oder alle Daten jederzeit in der App; mit der Deinstallation werden alle Daten entfernt. Wenn du uns per E-Mail kontaktierst, verarbeiten wir deine Angaben nur zur Beantwortung (Art. 6 Abs. 1 lit. b/f DSGVO) und löschen sie danach."

**Store-Text (zulässige Aussagen):** „Deine Stimme bleibt bei dir." – „Keine Cloud, kein Konto, kein Tracking." – „Transkription direkt auf dem Gerät." – „Wir können deine Einträge nicht lesen – technisch nicht."
**Vermeiden:** „100 % sicher", „unhackbar", „militärische Verschlüsselung", „verbessert deine mentale Gesundheit", „erkennt Stress/Depression", „Stimmungsanalyse deiner Stimme", „medizinisches Tagebuch".

**Abgrenzungssatz (für Store und AGB):** „[App] ist ein persönliches Tagebuch und kein Medizinprodukt. Sie stellt keine Diagnosen, gibt keine Therapieempfehlungen und ersetzt keine ärztliche oder psychotherapeutische Beratung."

---

## 15. Offene Punkte (zu verifizieren)

- Exakte aktuelle Wortlaute § 25 TDDDG, § 5 DDG, § 356 Abs. 5 BGB (Fassung 2022), § 2/§ 3 BFSG.
- Google-Play-Definitionen „collect"/„ephemeral", Health-Apps-Policy-Text, DSA-Händler-Fristen, IARC-Ergebnis für Tagebuch-Apps.
- MDCG 2019-11 Rev. 1 (2025) und BfArM-Beispiele im Wortlaut.
- DPLA-Klauseln zu Journaling Suggestions; ob die Capability antragspflichtig ist.
- ANSSI-Verfahren und BIS-Frist/Adressen für den Jahresbericht.
- Schweizer BehiG-Revision (Stand 2026) und nDSG-Artikel im Wortlaut.
- Einordnung des In-App-Kaufs als „Dienstleistung im elektronischen Geschäftsverkehr" nach BFSG, wenn der Anbieter kein Kleinstunternehmen mehr ist.

---

## Quellenliste

Verifiziert (abgerufen 3.9.2026):
- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons
- https://developer.apple.com/documentation/bundleresources/information-property-list/nsmicrophoneusagedescription
- https://developer.apple.com/documentation/bundleresources/information-property-list/nsspeechrecognitionusagedescription
- https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition
- https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition
- https://developer.apple.com/documentation/speech/speechanalyzer
- https://developer.apple.com/documentation/speech/speechtranscriber
- https://developer.apple.com/design/human-interface-guidelines/privacy
- https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations
- https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance
- https://developer.apple.com/help/app-store-connect/reference/export-compliance-documentation-for-encryption
- https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation
- https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements
- https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions
- https://developer.apple.com/news/ (Einträge 24.7.2025, 9.7.2026)
- https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels
- https://developer.apple.com/documentation/journalingsuggestions
- https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.journal.allow
- https://developer.apple.com/documentation/journalingsuggestions/presenting-the-suggestions-picker-and-processing-a-selection
- https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup
- https://developer.android.com/guide/topics/data/collect-share
- https://developer.android.com/health-and-fitness/guides/health-connect/publish/request-access
- https://developer.android.com/develop/background-work/services/fgs/service-types
- https://developer.android.com/identity/data/autobackup
- https://developer.android.com/training/permissions/explaining-access
- https://developer.android.com/training/permissions/usage-notes
- https://developer.android.com/reference/android/speech/SpeechRecognizer
- https://github.com/openai/whisper (README, Lizenzabschnitt) und https://github.com/openai/whisper/blob/main/LICENSE
- https://github.com/openai/whisper/blob/main/model-card.md
- https://github.com/ggml-org/whisper.cpp/blob/master/LICENSE und https://github.com/ggml-org/whisper.cpp/blob/master/models/README.md
- https://github.com/argmaxinc/WhisperKit
- https://github.com/k2-fsa/sherpa-onnx
- https://github.com/bundestag/gesetze/blob/master/t/ttdsg/index.md (§ 25, Stand 2021)
- https://github.com/bundestag/gesetze/blob/master/b/bfsg/index.md (§ 3 Abs. 3, Stand 2021)
- https://github.com/bundestag/gesetze/blob/master/b/bgb/index.md (§ 356 Abs. 4/5, Stand 2021)

Nicht abrufbar, aus Kenntnisstand zitiert (mustVerify):
- https://www.gesetze-im-internet.de/tddsg/__25.html · https://www.gesetze-im-internet.de/ddg/__5.html · https://www.gesetze-im-internet.de/bfsg/__3.html · https://www.gesetze-im-internet.de/bgb/__356.html
- https://eur-lex.europa.eu/eli/reg/2016/679/oj (DSGVO) · https://eur-lex.europa.eu/eli/dir/2019/882/oj (EAA) · https://eur-lex.europa.eu/eli/reg/2017/745/oj (MDR) · https://eur-lex.europa.eu/eli/reg/2024/1689/oj (AI Act) · https://eur-lex.europa.eu/eli/reg/2022/2065/oj (DSA)
- https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-22023-technical-scope-art-53-eprivacy-directive_en
- https://www.datenschutzkonferenz-online.de/media/oh/20221205_oh_Telemedien_2021_Version_1_1.pdf
- https://health.ec.europa.eu/system/files/2020-09/md_mdcg_2019_11_guidance_qualification_classification_software_en_0.pdf
- https://www.bfarm.de/DE/Medizinprodukte/Aufgaben/Abgrenzung-und-Klassifizierung/Orientierungshilfe-Medical-Apps/_node.html
- https://support.google.com/googleplay/android-developer/answer/10787469 (Data safety) · https://support.google.com/googleplay/android-developer/answer/10144311 (User Data) · https://support.google.com/googleplay/android-developer/answer/12261419 (Health apps) · https://support.google.com/googleplay/android-developer/answer/9859655 (Content ratings)
- https://www.bis.doc.gov/index.php/policy-guidance/encryption/4-reports-and-reviews/a-annual-self-classification
- https://cyber.gouv.fr/reglementation-des-moyens-de-cryptologie
- https://www.fedlex.admin.ch/eli/cc/2022/491/de (nDSG) · https://www.fedlex.admin.ch/eli/cc/2003/667/de (BehiG)
- https://www.ris.bka.gv.at/GeltendeFassung.wxe?Abfrage=Bundesnormen&Gesetzesnummer=20001703 (ECG) · BaFG BGBl. I Nr. 76/2023
