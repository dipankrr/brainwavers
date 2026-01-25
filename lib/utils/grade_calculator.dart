class GradeCalculator {
  // Grading system (customizable)
  static const Map<String, double> gradeRanges = {
    'A+': 90.0,
    'A': 80.0,
    'B+': 70.0,
    'B': 60.0,
    'C': 50.0,
    'D': 40.0,
    'F': 0.0,
  };

  // Calculate grade based on percentage
  static String calculateGrade(double percentage) {
    if (percentage >= gradeRanges['A+']!) return 'A+';
    if (percentage >= gradeRanges['A']!) return 'A';
    if (percentage >= gradeRanges['B+']!) return 'B+';
    if (percentage >= gradeRanges['B']!) return 'B';
    if (percentage >= gradeRanges['C']!) return 'C';
    if (percentage >= gradeRanges['D']!) return 'D';
    return 'F';
  }

  // Calculate percentage
  static double calculatePercentage(int obtained, int total) {
    if (total == 0) return 0.0;
    return (obtained / total) * 100;
  }

  // Check if passed (D and above is pass)
  static bool isPassed(String grade) {
    return grade != 'F';
  }
}

class GradeUtils {
  static String gradeFromPercentage(double percent) {
    if (percent >= 90) return 'AA';
    if (percent >= 80) return 'A';
    if (percent >= 70) return 'B';
    if (percent >= 60) return 'C';
    if (percent >= 50) return 'D';
    return 'E';
  }

  static String gradeFromMarks(int obtained, int total) {
    if (total == 0) return '-';
    final percent = (obtained / total) * 100;
    return gradeFromPercentage(percent);
  }
}
