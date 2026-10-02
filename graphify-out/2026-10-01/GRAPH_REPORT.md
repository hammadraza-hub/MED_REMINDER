# Graph Report - med_remind_app  (2026-10-01)

## Corpus Check
- 67 files · ~543,360 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 52 file(s) not represented in the graph (top: .xcconfig 8, (none) 7, .xml 7)

## Summary
- 1036 nodes · 1342 edges · 54 communities (42 shown, 12 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d278b813`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- win32_window.cpp
- app_colors.dart
- main_shell.dart
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
- ../core/constants/app_colors.dart
- home_data.dart
- custom_text_field.dart
- meds_data.dart
- signup_screen.dart
- StatelessWidget
- splash_screen.dart
- family_setup_screen.dart
- reset_password_screen.dart
- manifest.json
- notification_setup_screen.dart
- login_screen.dart
- MaterialPageRoute
- State
- onboarding_header.dart
- social_icons.dart
- OnCreate
- widget_test.dart
- MainActivity.kt
- LaunchImage.imageset/README.md
- schedule_screen.dart
- edit_medication_screen.dart
- add_manual_screen.dart
- calendar_screen.dart
- MessageHandler
- MessageHandler
- app_theme.dart
- Win32Window
- package:flutter/material.dart
- FlutterWindow
- Point
- Size
- HealthProfileScreen

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
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.h → windows/flutter/generated_plugin_registrant.cc

## Import Cycles
- None detected.

## Communities (54 total, 12 thin omitted)

### Community 0 - "win32_window.cpp"
Cohesion: 0.19
Nodes (10): Scale(), Create, Destroy, UpdateTheme, Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, GetWindowClass (+2 more)

### Community 1 - "app_colors.dart"
Cohesion: 0.03
Nodes (61): accentOrange, accentYellow, AppColors, avatarFill, avatarSelected, background, barEmpty, brandTeal (+53 more)

### Community 2 - "main_shell.dart"
Cohesion: 0.08
Nodes (20): AddMedicationData, badgeFor, commonFor, _database, form, isDailyDose, MedSearchResult, name (+12 more)

### Community 3 - "camera_service.dart"
Cohesion: 0.07
Nodes (18): _cameras, CameraService, capture, captureDocument, captureSquare, _controller, dispose, flashOff (+10 more)

### Community 4 - "dose_action_sheet.dart"
Cohesion: 0.05
Nodes (35): build, createState, dispose, dose, _DoseActionSheet, _DoseActionSheetState, onTaken, onUntaken (+27 more)

### Community 5 - "scan_label_screen.dart"
Cohesion: 0.05
Nodes (39): active, build, _buildBody, _buildCameraControls, _buildCameraLoading, _buildCameraPreview, _buildDetectedCard, _buildHeader (+31 more)

### Community 6 - "home_screen.dart"
Cohesion: 0.05
Nodes (36): _actionButton, _badge, _buildHomeContent, createState, dateLabel, dose, _doses, _dotStat (+28 more)

### Community 7 - "ocr_service.dart"
Cohesion: 0.05
Nodes (36): _addIfUnique, _calculateConfidence, _cleanLine, confidence, _detectForm, _detectFrequency, _detectInstructions, detectMedicine (+28 more)

### Community 8 - "AppDelegate"
Cohesion: 0.06
Nodes (14): Cocoa, file_selector_macos, Flutter, FlutterMacOS, Foundation, AppDelegate, SceneDelegate, RunnerTests (+6 more)

### Community 9 - "review_scan_screen.dart"
Cohesion: 0.05
Nodes (36): DetectedMedicine, build, _buildContent, _buildContinueButton, _buildHeader, _buildImageCard, _buildMainDetailsCard, _buildMedicineName (+28 more)

### Community 10 - "add_medication_screen.dart"
Cohesion: 0.06
Nodes (30): AddMedicationScreen, _AddMedicationScreenState, build, _buildActionButtons, _buildBody, _buildHeader, _buildInitialState, _buildManualLink (+22 more)

### Community 11 - "meds_screen.dart"
Cohesion: 0.08
Nodes (21): _archived, badge, build, _buildEmptyState, _buildHeader, _buildSearch, _buildTabs, count (+13 more)

### Community 12 - "my_application.cc"
Cohesion: 0.08
Nodes (14): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+6 more)

### Community 13 - "health_profile_screen.dart"
Cohesion: 0.07
Nodes (26): _addAllergy, _addAllergyFromField, _AddConditionButton, _addCustomCondition, _allergies, _AllergyChips, _allergyController, badgeColor (+18 more)

### Community 14 - "../core/constants/app_colors.dart"
Cohesion: 0.20
Nodes (7): AppAvatar, build, icon, imagePath, ringColor, ringWidth, size

### Community 15 - "home_data.dart"
Cohesion: 0.05
Nodes (26): dateLabel, daysLeft, details, Dose, doseAmount, DoseStatus, FamilyMember, familyMembers (+18 more)

### Community 16 - "custom_text_field.dart"
Cohesion: 0.09
Nodes (19): autofocus, build, controller, createState, CustomTextField, _CustomTextFieldState, FieldVariant, hasError (+11 more)

### Community 17 - "meds_data.dart"
Cohesion: 0.05
Nodes (33): allergiesCount, archived, courseDay, courseTotalDays, dose, endsOnLabel, frequency, isArchived (+25 more)

### Community 18 - "signup_screen.dart"
Cohesion: 0.10
Nodes (17): _agreeToTerms, color, _createAccount, createState, didChangeDependencies, dispose, _emailController, _emailError (+9 more)

### Community 19 - "StatelessWidget"
Cohesion: 0.10
Nodes (20): _AddMemberButton, _DoseCard, _FamilyMemberAvatar, _FilterChip, _HomeHeader, _ProgressCard, _QuickAccessSection, _StatusBadge (+12 more)

### Community 20 - "splash_screen.dart"
Cohesion: 0.15
Nodes (9): build, _controller, createState, dispose, initState, _LoadingDots, _LoadingDotsState, SplashScreen (+1 more)

### Community 21 - "family_setup_screen.dart"
Cohesion: 0.17
Nodes (11): build, createState, dispose, FamilySetupScreen, _FamilySetupScreenState, _inviteCaregiver, _inviteController, _inviteError (+3 more)

### Community 22 - "reset_password_screen.dart"
Cohesion: 0.18
Nodes (9): build, createState, dispose, _emailController, _emailError, _linkSent, ResetPasswordScreen, _ResetPasswordScreenState (+1 more)

### Community 23 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 24 - "notification_setup_screen.dart"
Cohesion: 0.18
Nodes (8): _allow, _BenefitRow, build, icon, NotificationSetupScreen, _notNow, _SettingsHintCard, text

### Community 25 - "login_screen.dart"
Cohesion: 0.17
Nodes (10): build, createState, dispose, _emailController, _emailError, _login, LoginScreen, _LoginScreenState (+2 more)

### Community 26 - "MaterialPageRoute"
Cohesion: 0.17
Nodes (11): build, build, _continueToSchedule, _addManually, _scanLabel, _addMedicine, _buildContent, _confirmAndContinue (+3 more)

### Community 27 - "State"
Cohesion: 0.32
Nodes (6): SignupScreen, _SignupScreenState, HomeScreen, _HomeScreenState, MedsScreen, _MedsScreenState

### Community 28 - "onboarding_header.dart"
Cohesion: 0.22
Nodes (8): _BrandRow, build, _NavigationRow, onBack, OnboardingHeader, onSkip, step, totalSteps

### Community 29 - "social_icons.dart"
Cohesion: 0.22
Nodes (5): AppleLogo, build, color, GoogleLogo, size

### Community 30 - "OnCreate"
Cohesion: 0.20
Nodes (5): RegisterPlugins(), OnCreate, GetClientArea, OnCreate, SetChildContent

### Community 41 - "schedule_screen.dart"
Cohesion: 0.04
Nodes (47): _addDoseTime, build, _buildConfirmButton, _buildContent, _buildCycleCard, _buildCycleRow, _buildDateRangeCard, _buildDaySelector (+39 more)

### Community 42 - "edit_medication_screen.dart"
Cohesion: 0.05
Nodes (43): build, _buildContent, _buildFormGrid, _buildHeader, _buildInstructions, _buildInventoryCard, _buildNameField, _buildNotes (+35 more)

### Community 43 - "add_manual_screen.dart"
Cohesion: 0.05
Nodes (37): AddManualScreen, _AddManualScreenState, build, _buildColorButton, _buildForm, _buildFormCard, _buildHeader, _buildInteractionCard (+29 more)

### Community 44 - "calendar_screen.dart"
Cohesion: 0.06
Nodes (34): build, _buildCalendarCard, _buildHeader, _buildMonthGrid, _buildSelectedDateCard, _buildWeekGrid, CalendarScreen, _CalendarScreenState (+26 more)

### Community 46 - "MessageHandler"
Cohesion: 0.36
Nodes (5): EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle, MessageHandler, WndProc

### Community 47 - "app_theme.dart"
Cohesion: 0.22
Nodes (7): AppTheme, borderColor, darkNavy, inputBg, lightBg, primaryGreen, textMuted

### Community 48 - "Win32Window"
Cohesion: 0.25
Nodes (8): OnDestroy, Win32Window, child_content_, OnDestroy, quit_on_close_, SetQuitOnClose, Show, window_handle_

### Community 49 - "package:flutter/material.dart"
Cohesion: 0.29
Nodes (6): _agreeToTerms, build, CreateAccountScreen, _CreateAccountScreenState, createState, _obscurePassword

### Community 50 - "FlutterWindow"
Cohesion: 0.33
Nodes (3): FlutterWindow, flutter_controller_, project_

### Community 51 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 52 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

## Knowledge Gaps
- **649 isolated node(s):** `AppColors`, `primary`, `primaryDark`, `primaryLight`, `brandTeal` (+644 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 755 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `win32_window.cpp`, `MessageHandler`, `MessageHandler`, `home_data.dart`, `FlutterWindow`, `Point`, `Size`, `OnCreate`?**
  _High betweenness centrality (0.058) - this node is a cross-community bridge._
- **Why does `Point` connect `Point` to `Win32Window`, `win32_window.cpp`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `AppColors`, `primary`, `primaryDark` to the rest of the system?**
  _649 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_colors.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03225806451612903 - nodes in this community are weakly interconnected._
- **Should `main_shell.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `camera_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07142857142857142 - nodes in this community are weakly interconnected._
- **Should `dose_action_sheet.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._