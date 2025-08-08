enum JenisIzin { IZIN, SAKIT, CUTI }

enum StatusIzin { PENDING, APPROVED, REJECTED }

class IzinUtils {
  static String getJenisIzinText(JenisIzin jenis) {
    switch (jenis) {
      case JenisIzin.IZIN:
        return 'Izin';
      case JenisIzin.SAKIT:
        return 'Sakit';
      case JenisIzin.CUTI:
        return 'Cuti';
    }
  }

  static String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
