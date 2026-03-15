import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Screens
import 'package:mobile_flutter/presentation/screens/home/home_screen.dart';
import 'package:mobile_flutter/presentation/screens/map/map_screen.dart';
import 'package:mobile_flutter/presentation/screens/notifications/notifications_screen.dart';
import 'package:mobile_flutter/presentation/screens/report/report_screen.dart';
import 'package:mobile_flutter/presentation/screens/profile/profile_screen.dart';
import 'package:mobile_flutter/presentation/screens/auth/login_screen.dart';
import 'package:mobile_flutter/presentation/screens/splash/splash_screen.dart';

// Providers
import 'package:mobile_flutter/presentation/providers/auth_provider.dart';
export 'package:mobile_flutter/presentation/providers/auth_provider.dart' show AuthStatus;
import 'package:mobile_flutter/presentation/providers/report_provider.dart';
import 'package:mobile_flutter/presentation/providers/settings_provider.dart';
import 'package:mobile_flutter/presentation/providers/post_provider.dart';
import 'package:mobile_flutter/presentation/providers/zone_provider.dart';
import 'package:mobile_flutter/presentation/providers/location_provider.dart';
import 'package:mobile_flutter/presentation/providers/notification_provider.dart';

// Widgets
import 'package:mobile_flutter/presentation/widgets/zone_warning_banner.dart';

// Data sources & Repositories
import 'package:mobile_flutter/data/datasources/local/post_local_datasource.dart';
import 'package:mobile_flutter/data/repositories/post_repository_impl.dart';

class SafeZoneApp extends StatelessWidget {
  const SafeZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => ZoneProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),

        // Post Provider với dependencies
        ChangeNotifierProvider(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            return PostProvider(
              repository: PostRepositoryImpl(),
              localDatasource: PostLocalDatasource(),
              currentUser: authProvider.user,
            );
          },
        ),
      ],
      child: MaterialApp(
        title: 'SafeZone',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// Wrapper to handle auth state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check auth status on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();

      // Initialize mock data - chỉ khi app khởi động
      _initializeMockData();
    });
  }

  void _initializeMockData() {
    // Đợi một chút để đảm bảo provider đã được khởi tạo
    Future.delayed(const Duration(milliseconds: 500), () {
      final authProvider = context.read<AuthProvider>();
      final postProvider = context.read<PostProvider>();

      // Update current user in PostProvider
      if (authProvider.user != null) {
        postProvider.setCurrentUser(authProvider.user);
        print('Updated PostProvider with current user: ${authProvider.user?.name}');
      }

      // Load posts from API/database instead of using mock data
      print('🔄 Loading posts from database...');
      postProvider.refreshPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show splash screen while checking auth
        if (authProvider.status == AuthStatus.initial ||
            authProvider.status == AuthStatus.loading) {
          return const SplashScreen();
        }

        // If authenticated, show main screen
        if (authProvider.status == AuthStatus.authenticated) {
          return const MainScreen();
        }

        // Otherwise show login screen
        return const LoginScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MapScreen(),
    NotificationsScreen(),
    ReportScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Fetch zones and start location tracking for zone warnings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ZoneProvider>().fetchZones();
      context.read<LocationProvider>().startTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Zone warning banner - shows when user is in epidemic zone
          const ZoneWarningBanner(),
          // Main content
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Bản đồ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Báo cáo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}