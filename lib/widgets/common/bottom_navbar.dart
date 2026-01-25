import 'package:flutter/material.dart';

import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/students/add_edit_student_screen.dart';
import '../../screens/students/students_list_screen.dart';


// A global notifier for the selected bottom tab
ValueNotifier<int> bottomNavIndex = ValueNotifier<int>(0);


/// Returns the index of the current tab based on the screen type.
int getCurrentIndex(BuildContext context) {
  final widget = ModalRoute.of(context)?.settings.arguments;

  if (widget is DashboardScreen) return 0;
  if (widget is AddEditStudentScreen) return 1;
  if (widget is StudentsListScreen) return 2;

  return 0; // default tab
}

/// Handle bottom nav taps and navigate
void handleNavTap(BuildContext context, int index) {
  bottomNavIndex.value = index;  // highlight tab

  switch (index) {
    case 0:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
      break;

    case 1:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
      );
      break;

    case 2:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentsListScreen()),
      );
      break;

    case 3:
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Settings coming soon")));
      break;
  }
}



Widget? buildBottomNav(
    BuildContext context, [
      bool visible = true,
    ]) {
  final width = MediaQuery.of(context).size.width;

  if (width >= 700) return null;

  return AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    height: visible ? kBottomNavigationBarHeight : 0,
    child: visible
        ? ValueListenableBuilder<int>(
      valueListenable: bottomNavIndex,
      builder: (_, index, __) {
        return BottomNavigationBar(
          currentIndex: index,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: (i) => handleNavTap(context, i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard, size: 20,),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_add_alt_1, size: 20,),
              label: "Ad",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list, size: 20,),
              label: "s",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings, size: 20,),
              label: "",
            ),
          ],
        );
      },
    )
        : null,
  );
}


