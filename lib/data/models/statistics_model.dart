// Statistics Model
class DiseaseStats {
  final int total;
  final Map<String, int> byDisease;
  final Map<String, int> byStatus;
  final List<RegionStat> byRegion;
  final TrendStat trend;

  DiseaseStats({
    required this.total,
    required this.byDisease,
    required this.byStatus,
    required this.byRegion,
    required this.trend,
  });

  factory DiseaseStats.fromJson(Map<String, dynamic> json) {
    final summary = _toMap(json['summary']);
    final total = _toInt(
      json['total'] ?? summary['total'] ?? summary['total_cases'],
    );

    return DiseaseStats(
      total: total,
      byDisease: _toCountMap(
        json['byDisease'] ?? json['by_disease'] ?? json['diseaseStats'],
        keyCandidates: const ['name', 'key', 'diseaseType', 'disease_type'],
      ),
      byStatus: _toCountMap(
        json['byStatus'] ?? json['by_status'] ?? json['statusStats'],
        keyCandidates: const ['name', 'key', 'status'],
      ),
      byRegion: _toRegionList(json['byRegion'] ?? json['topRegions']),
      trend: TrendStat.fromJson(
        _toMap(json['trend'] ?? json['comparison'] ?? summary),
      ),
    );
  }
}

class RegionStat {
  final String regionCode;
  final String name;
  final int count;

  RegionStat({
    required this.regionCode,
    required this.name,
    required this.count,
  });

  factory RegionStat.fromJson(Map<String, dynamic> json) {
    return RegionStat(
      regionCode: (json['regionCode'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['regionName'] ?? '').toString(),
      count: _toInt(json['count'] ?? json['total']),
    );
  }
}

class TrendStat {
  final int today;
  final int yesterday;
  final int thisWeek;
  final int lastWeek;
  final int percentChange;

  TrendStat({
    required this.today,
    required this.yesterday,
    required this.thisWeek,
    required this.lastWeek,
    required this.percentChange,
  });

  factory TrendStat.fromJson(Map<String, dynamic> json) {
    final current = _toInt(json['current_period']);
    final previous = _toInt(json['previous_period']);
    final percent = previous == 0
        ? (current > 0 ? 100 : 0)
        : (((current - previous) / previous) * 100).round();

    return TrendStat(
      today: _toInt(json['today']),
      yesterday: _toInt(json['yesterday']),
      thisWeek: _toInt(json['thisWeek']),
      lastWeek: _toInt(json['lastWeek']),
      percentChange: _toInt(
        json['percentChange'] ?? json['percent_change'] ?? percent,
      ),
    );
  }
}

class TimelineData {
  final List<TimelinePoint> timeline;

  TimelineData({required this.timeline});

  factory TimelineData.fromJson(Map<String, dynamic> json) {
    final source =
        json['timeline'] ?? json['byDay'] ?? json['by_day'] ?? const [];
    return TimelineData(
      timeline:
          (source as List?)?.map((e) => TimelinePoint.fromJson(e)).toList() ??
          [],
    );
  }
}

class TimelinePoint {
  final String date;
  final int count;

  TimelinePoint({required this.date, required this.count});

  factory TimelinePoint.fromJson(Map<String, dynamic> json) {
    return TimelinePoint(
      date: (json['date'] ?? json['day'] ?? '').toString(),
      count: _toInt(json['count'] ?? json['total']),
    );
  }
}

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

Map<String, int> _toCountMap(
  dynamic raw, {
  required List<String> keyCandidates,
}) {
  if (raw is Map) {
    return raw.map((k, v) => MapEntry(k.toString(), _toInt(v)));
  }

  if (raw is List) {
    final result = <String, int>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      String key = '';
      for (final candidate in keyCandidates) {
        final value = map[candidate];
        if (value != null && value.toString().isNotEmpty) {
          key = value.toString();
          break;
        }
      }
      if (key.isEmpty) continue;
      result[key] = _toInt(map['count'] ?? map['total'] ?? map['value']);
    }
    return result;
  }

  return <String, int>{};
}

List<RegionStat> _toRegionList(dynamic raw) {
  if (raw is! List) return <RegionStat>[];
  return raw
      .whereType<Map>()
      .map((e) => RegionStat.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}
