import 'package:brainwavers/screens/students/verify_students_screen.dart';
import 'package:flutter/material.dart';
import 'package:brainwavers/screens/academic_data/classes_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/navigation/route_observer.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/cards/stats_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';
import '../academic_data/academic_years_screen.dart';
import '../academic_data/subjects_screen.dart';
import '../auth/login_screen.dart';
import '../franchise/create_franchise_screen.dart';
import '../marks/marks_management_screen.dart';
import '../students/add_edit_student_screen.dart';
import '../students/students_list_screen.dart';



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware{

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    _loadDashboardStats();
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardStats();
    });
  }

  Future<void> _loadDashboardStats() async {
    final dashboardProvider =
    Provider.of<DashboardProvider>(context, listen: false);
    await dashboardProvider.loadDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background2,
      appBar: CustomAppBar(
        title: 'Dashboard',
        showBackButton: false,
        actions: [
          const Text("Logout"),
          IconButton(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout))
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, _) {
          if (dashboardProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashboardProvider.error != null) {
            return Center(
              child: Text(
                dashboardProvider.error!,
                style: AppTextStyles.bodyMedium(context),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(
              ResponsiveUtils.responsiveValue(context, 16.0, 20.0, 24.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(context),
                const SizedBox(height: 32),
                _buildStatsSection(context, dashboardProvider),
                const SizedBox(height: 32),
                _buildQuickActionsSection(context),
              ],
            ),
          );
        },
      ),
    );
  }


  void _logout(BuildContext context) async {
    // Sign out from Supabase
     await Supabase.instance.client.auth.signOut();


      // Clear SharedPreferences (logout the user)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);  // Optionally clear other data

     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Text('Logout successful'),
         backgroundColor: Colors.green,
       ),
     );
      // After successful logout, navigate to the login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(), // Your login screen here
        ),
      );

    }
  }

  // -------------------- WELCOME --------------------

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "admin")
        Text(
          'Welcome, Admin!',
          style: AppTextStyles.headlineLarge(context),
        ),
        if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")
          Text(
            'Welcome, Super Admin!',
            style: AppTextStyles.headlineLarge(context),
          ),
        const SizedBox(height: 8),
        Text(
          'Brainwavers',
          style: AppTextStyles.bodyMedium(context)!.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // -------------------- STATS (REAL DATA) --------------------

  Widget _buildStatsSection(
      BuildContext context,
      DashboardProvider dashboardProvider,
      ) {
    final crossAxisCount =
    ResponsiveUtils.responsiveValue(context, 2, 3, 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: AppTextStyles.titleLarge(context),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: crossAxisCount as int,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            StatsCard(
              title: 'Total Students',
              value: dashboardProvider.totalStudents.toString(),
              icon: Icons.people,
            ),
            StatsCard(
              title: 'Active Courses',
              value: dashboardProvider.totalClasses.toString(),
              icon: Icons.class_,
            ),
            StatsCard(
              title: 'Subjects',
              value: dashboardProvider.totalSubjects.toString(),
              icon: Icons.subject,
            ),
            StatsCard(
              title: 'Academic Years',
              value: dashboardProvider.totalAcademicYears.toString(),
              icon: Icons.calendar_today,
            ),
          ],
        ),
      ],
    );
  }

  // -------------------- QUICK ACTIONS (UNCHANGED) --------------------

  Widget _buildQuickActionsSection(BuildContext context) {
    final crossAxisCount =
    ResponsiveUtils.responsiveValue(context, 2, 3, 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.titleLarge(context),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: crossAxisCount as int,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "admin")
            _buildActionCard(
              context,
              'Your Students',
              Icons.people_outline,
              Colors.green,
                  () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StudentsListScreen(),
                ),
              ),
            ),
            if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")
              _buildActionCard(
                context,
                'Franchises',
                Icons.store,
                Colors.blue,
                    () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FranchiseScreen(),
                  ),
                ),
              ),
            if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")
            _buildActionCard(
              context,
              'Verify Student',
              Icons.verified,
              Colors.blue,
                  () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VerifyStudentScreen(),
                ),
              ),
            ),
            _buildActionCard(
              context,
              'Add Student',
              Icons.add,
              Colors.black,
                  () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddEditStudentScreen(),
                ),
              ),
            ),

            // _buildActionCard(
            //   context,
            //   'PDF Gen',
            //   Icons.print,
            //   Colors.blue,
            //       () => Navigator.of(context).push(
            //     MaterialPageRoute(
            //       builder: (_) => const GenPDFsScreen(),
            //     ),
            //   ),
            // ),
            // _buildActionCard(
            //   context,
            //   'Marks',
            //   Icons.assignment,
            //   Colors.green,
            //       () => Navigator.of(context).push(
            //     MaterialPageRoute(
            //       builder: (_) => const MarksManagementScreen(),
            //     ),
            //   ),
            // ),
            _buildActionCard(
              context,
              'Subjects',
              Icons.subject,
              Colors.orange,
                  () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubjectsScreen(),
                ),
              ),
            ),
            _buildActionCard(
              context,
              'Academic Years',
              Icons.calendar_month,
              Colors.red,
                  () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AcademicYearsScreen(),
                ),
              ),
            ),
            _buildActionCard(
              context,
              'Courses',
              Icons.school,
              Colors.teal,
                  () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ClassesScreen(),
                ),
              ),
            ),
            if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "admin")
            _buildActionCard(
              context,
              'Marks',
              Icons.assignment,
              Colors.teal,
                  () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MarksManagementScreen(),
                ),
              ),
            ),
            if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")
              _buildActionCard(
                context,
                'Others',
                Icons.miscellaneous_services,
                Colors.blue,
                  (){}
              ),
            // _buildActionCard(
            //   context,
            //   'Result',
            //   Icons.assignment,
            //   Colors.red,
            //       () => Navigator.of(context).push(
            //     MaterialPageRoute(
            //       builder: (_) => const ResultsScreen(),
            //     ),
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: ResponsiveUtils.responsiveValue(context, 32.0, 36.0, 40.0),
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.bodyMedium(context)!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to $route - Coming Soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

