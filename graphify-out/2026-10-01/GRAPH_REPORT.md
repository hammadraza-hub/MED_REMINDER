# Graph Report - med_remind_app  (2026-09-30)

## Corpus Check
- 63 files · ~532,319 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 52 file(s) not represented in the graph (top: .xcconfig 8, (none) 7, .xml 7)

## Summary
- 856 nodes · 1109 edges · 41 communities (30 shown, 11 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `32c14342`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Win32Window
- app_colors.dart
- package:flutter/material.dart
- camera_service.dart
- dose_action_sheet.dart
- scan_label_screen.dart
- home_screen.dart
- ocr_service.dart
- AppDelegate
- review_scan_screen.dart
- add_medication_screen.dart
- meds_screen.dart
- my_application.cc
- health_profile_screen.dart
- custom_button.dart
- utils.cpp
- custom_text_field.dart
- meds_data.dart
- signup_screen.dart
- StatelessWidget
- splash_screen.dart
- family_setup_screen.dart
- reset_password_screen.dart
- manifest.json
- ../core/constants/app_colors.dart
- login_screen.dart
- MaterialPageRoute
- State
- onboarding_header.dart
- social_icons.dart
- windows/flutter/generated_plugin_registrant.cc
- widget_test.dart
- MainActivity.kt
- LaunchImage.imageset/README.md

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `MessageHandler` - 12 edges
3. `FlutterWindow` - 10 edges
4. `Create` - 10 edges
5. `WndProc` - 10 edges
6. `MessageHandler` - 9 edges
7. `_MyApplication` - 7 edges
8. `OnCreate` - 7 edges
9. `WindowClassRegistrar` - 7 edges
10. `Destroy` - 7 edges

## Surprising Connections (you probably didn't know these)
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.h → windows/flutter/generated_plugin_registrant.cc
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc

## Import Cycles
- None detected.

## Communities (41 total, 11 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.05
Nodes (38): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), MessageHandler, OnCreate, OnDestroy, project_, EnableFullDpiSupportIfAvailable() (+30 more)

### Community 1 - "app_colors.dart"
Cohesion: 0.03
Nodes (61): accentOrange, accentYellow, AppColors, avatarFill, avatarSelected, background, barEmpty, brandTeal (+53 more)

### Community 2 - "package:flutter/material.dart"
Cohesion: 0.05
Nodes (36): AppTheme, borderColor, darkNavy, inputBg, lightBg, primaryGreen, textMuted, AddMedicationData (+28 more)

### Community 3 - "camera_service.dart"
Cohesion: 0.05
Nodes (29): _cameras, CameraService, capture, captureDocument, captureSquare, _controller, dispose, flashOff (+21 more)

### Community 4 - "dose_action_sheet.dart"
Cohesion: 0.05
Nodes (40): build, createState, dispose, dose, _DoseActionSheet, _DoseActionSheetState, onTaken, onUntaken (+32 more)

### Community 5 - "scan_label_screen.dart"
Cohesion: 0.05
Nodes (36): active, build, _buildBody, _buildCameraControls, _buildCameraLoading, _buildCameraPreview, _buildDetectedCard, _buildHeader (+28 more)

### Community 6 - "home_screen.dart"
Cohesion: 0.05
Nodes (36): _actionButton, _badge, _buildHomeContent, createState, dateLabel, dose, _doses, _dotStat (+28 more)

### Community 7 - "ocr_service.dart"
Cohesion: 0.05
Nodes (35): _addIfUnique, _calculateConfidence, _cleanLine, confidence, DetectedMedicine, _detectForm, _detectFrequency, _detectInstructions (+27 more)

### Community 8 - "AppDelegate"
Cohesion: 0.06
Nodes (14): Cocoa, file_selector_macos, Flutter, FlutterMacOS, Foundation, AppDelegate, SceneDelegate, RunnerTests (+6 more)

### Community 9 - "review_scan_screen.dart"
Cohesion: 0.05
Nodes (36): build, _buildContent, _buildContinueButton, _buildHeader, _buildImageCard, _buildMainDetailsCard, _buildMedicineName, _buildReadSuccess (+28 more)

### Community 10 - "add_medication_screen.dart"
Cohesion: 0.06
Nodes (29): _addManually, AddMedicationScreen, _AddMedicationScreenState, build, _buildActionButtons, _buildBody, _buildHeader, _buildInitialState (+21 more)

### Community 11 - "meds_screen.dart"
Cohesion: 0.07
Nodes (27): AppAvatarPlaceholder, _archived, badge, build, _buildContent, _buildEmptyState, _buildHeader, _buildSearch (+19 more)

### Community 12 - "my_application.cc"
Cohesion: 0.08
Nodes (14): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+6 more)

### Community 13 - "health_profile_screen.dart"
Cohesion: 0.07
Nodes (27): _addAllergy, _addAllergyFromField, _addCustomCondition, _allergies, _AllergyChips, _allergyController, badgeColor, build (+19 more)

### Community 14 - "custom_button.dart"
Cohesion: 0.07
Nodes (24): AppAvatar, build, icon, imagePath, ringColor, ringWidth, size, build (+16 more)

### Community 15 - "utils.cpp"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 16 - "custom_text_field.dart"
Cohesion: 0.09
Nodes (19): autofocus, build, controller, createState, CustomTextField, _CustomTextFieldState, FieldVariant, hasError (+11 more)

### Community 17 - "meds_data.dart"
Cohesion: 0.09
Nodes (20): allergiesCount, archived, courseDay, courseTotalDays, dose, endsOnLabel, frequency, isArchived (+12 more)

### Community 18 - "signup_screen.dart"
Cohesion: 0.10
Nodes (17): _agreeToTerms, color, _createAccount, createState, didChangeDependencies, dispose, _emailController, _emailError (+9 more)

### Community 19 - "StatelessWidget"
Cohesion: 0.11
Nodes (17): _AddMemberButton, _DoseCard, _FamilyMemberAvatar, _FilterChip, _HomeHeader, _ProgressCard, _QuickAccessSection, _StatusBadge (+9 more)

### Community 20 - "splash_screen.dart"
Cohesion: 0.17
Nodes (7): build, _controller, createState, dispose, initState, _LoadingDots, _LoadingDotsState

### Community 21 - "family_setup_screen.dart"
Cohesion: 0.17
Nodes (11): build, createState, dispose, FamilySetupScreen, _FamilySetupScreenState, _inviteCaregiver, _inviteController, _inviteError (+3 more)

### Community 22 - "reset_password_screen.dart"
Cohesion: 0.18
Nodes (9): build, createState, dispose, _emailController, _emailError, _linkSent, ResetPasswordScreen, _ResetPasswordScreenState (+1 more)

### Community 23 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 24 - "../core/constants/app_colors.dart"
Cohesion: 0.20
Nodes (6): _BenefitRow, build, icon, NotificationSetupScreen, _SettingsHintCard, text

### Community 25 - "login_screen.dart"
Cohesion: 0.20
Nodes (7): createState, dispose, _emailController, _emailError, _login, _passwordController, _passwordError

### Community 26 - "MaterialPageRoute"
Cohesion: 0.20
Nodes (9): build, build, build, _scanLabel, _addMedicine, _confirmMedicine, _continue, _allow (+1 more)

### Community 27 - "State"
Cohesion: 0.27
Nodes (8): LoginScreen, _LoginScreenState, SignupScreen, _SignupScreenState, HomeScreen, _HomeScreenState, SplashScreen, _SplashScreenState

### Community 28 - "onboarding_header.dart"
Cohesion: 0.20
Nodes (8): _BrandRow, build, _NavigationRow, onBack, OnboardingHeader, onSkip, step, totalSteps

### Community 29 - "social_icons.dart"
Cohesion: 0.22
Nodes (5): AppleLogo, build, color, GoogleLogo, size

## Knowledge Gaps
- **496 isolated node(s):** `AppColors`, `primary`, `primaryDark`, `primaryLight`, `brandTeal` (+491 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 602 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Dose` connect `dose_action_sheet.dart` to `home_screen.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Why does `OcrService` connect `ocr_service.dart` to `scan_label_screen.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **Why does `DetectedMedicine` connect `ocr_service.dart` to `review_scan_screen.dart`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `AppColors`, `primary`, `primaryDark` to the rest of the system?**
  _496 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.05407925407925408 - nodes in this community are weakly interconnected._
- **Should `app_colors.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03225806451612903 - nodes in this community are weakly interconnected._
- **Should `package:flutter/material.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.045328399629972246 - nodes in this community are weakly interconnected._