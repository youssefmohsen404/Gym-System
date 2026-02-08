import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'presentation/viewmodels/gym_viewmodel.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';
import 'presentation/views/dashboard_screen.dart';
import 'presentation/views/members_screen.dart';
import 'presentation/views/check_in_screen.dart';
import 'presentation/views/membership_plans_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'data/services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // If we still have data in SharedPreferences from the old implementation, migrate it once.
  await DatabaseService().migrateFromSharedPreferences();

  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GymViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
      ],
      child: LifecycleWatcher(
        child: Builder(
          builder: (context) {
            final theme = Provider.of<ThemeViewModel>(context);
            return MaterialApp(
              title: 'XBOOST SYSTEM',
              debugShowCheckedModeBanner: false,
              theme: theme.themeData,
              home: const MainScreen(),
            );
          },
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class LifecycleWatcher extends StatefulWidget {
  final Widget child;
  const LifecycleWatcher({required this.child, super.key});

  @override
  State<LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    try {
      final provider = Provider.of<GymViewModel>(context, listen: false);
      provider.flushToDisk().then((_) => DatabaseService().close());
    } catch (e) {
      if (kDebugMode) print('Error flushing on dispose: $e');
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Flush to disk on pause/detached/inactive states to minimize risk of lost data
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      try {
        final provider = Provider.of<GymViewModel>(context, listen: false);
        provider.flushToDisk().then((_) => DatabaseService().close());
      } catch (e) {
        if (kDebugMode) print('Error flushing on lifecycle change: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _shouldOpenAddDialog = false;
  int? _membersTabIndex;

  void _handleNavigateToMembers({bool openAddDialog = false, int? tabIndex}) {
    setState(() {
      _shouldOpenAddDialog = openAddDialog;
      _membersTabIndex = tabIndex;
      _selectedIndex = 1;
    });
  }

  void _resetAddMemberDialogFlag() {
    if (_shouldOpenAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _shouldOpenAddDialog = false;
            _membersTabIndex = null; // Reset tab index after navigation
          });
        }
      });
    }
  }

  List<Widget> get _screens => [
    DashboardScreen(
      onNavigateToMembers: () => _handleNavigateToMembers(openAddDialog: true),
      onNavigateToCheckIn: () => setState(() => _selectedIndex = 2),
      onNavigateToPlans: () => setState(() => _selectedIndex = 3),
      onNavigateToExpiredUnpaid: () => _handleNavigateToMembers(tabIndex: 1),
      onNavigateToExpiringSoon: () => _handleNavigateToMembers(tabIndex: 2),
    ),
    MembersScreen(
      autoOpenAddDialog: _shouldOpenAddDialog,
      onDialogOpened: _resetAddMemberDialogFlag,
      initialTabIndex: _membersTabIndex,
    ),
    const CheckInScreen(),
    const MembershipPlansScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
                if (index != 1) {
                  _membersTabIndex =
                      null; // Reset tab index when switching away
                  _shouldOpenAddDialog =
                      false; // Reset dialog flag when switching away
                } else {
                  // Reset dialog flag when directly clicking Members tab
                  _shouldOpenAddDialog = false;
                }
              });
            },
            extended: true,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outlined),
                selectedIcon: Icon(Icons.people),
                label: Text('Members'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.login_outlined),
                selectedIcon: Icon(Icons.login),
                label: Text('Check In/Out'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.card_membership_outlined),
                selectedIcon: Icon(Icons.card_membership),
                label: Text('Plans'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
