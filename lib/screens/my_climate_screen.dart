import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import '../data/coord_history.dart';
import '../theme/app_theme.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

class DayForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final double precipitation;
  final double windspeed;
  final int weatherCode;

  const DayForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitation,
    required this.windspeed,
    required this.weatherCode,
  });
}

class WeatherData {
  final double currentTemp;
  final int currentCode;
  final double currentWind;
  final List<DayForecast> daily;
  final double lat;
  final double lon;

  const WeatherData({
    required this.currentTemp,
    required this.currentCode,
    required this.currentWind,
    required this.daily,
    required this.lat,
    required this.lon,
  });

  factory WeatherData.fromJson(
      Map<String, dynamic> json, double lat, double lon) {
    final cw = json['current_weather'] as Map<String, dynamic>;
    final d = json['daily'] as Map<String, dynamic>;

    final dates = (d['time'] as List).cast<String>();
    final maxTemps = (d['temperature_2m_max'] as List)
        .map((v) => (v as num?)?.toDouble() ?? 0.0)
        .toList();
    final minTemps = (d['temperature_2m_min'] as List)
        .map((v) => (v as num?)?.toDouble() ?? 0.0)
        .toList();
    final precip = (d['precipitation_sum'] as List)
        .map((v) => (v as num?)?.toDouble() ?? 0.0)
        .toList();
    final wind = (d['windspeed_10m_max'] as List)
        .map((v) => (v as num?)?.toDouble() ?? 0.0)
        .toList();
    final codes = (d['weathercode'] as List)
        .map((v) => (v as num?)?.toInt() ?? 0)
        .toList();

    final days = <DayForecast>[];
    for (int i = 0; i < dates.length; i++) {
      days.add(DayForecast(
        date: DateTime.parse(dates[i]),
        maxTemp: maxTemps[i],
        minTemp: minTemps[i],
        precipitation: precip[i],
        windspeed: wind[i],
        weatherCode: codes[i],
      ));
    }

    return WeatherData(
      currentTemp: (cw['temperature'] as num).toDouble(),
      currentCode: (cw['weathercode'] as num).toInt(),
      currentWind: (cw['windspeed'] as num).toDouble(),
      daily: days,
      lat: lat,
      lon: lon,
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _weatherIcon(int code) {
  if (code == 0) return '☀️';
  if (code <= 3) return '⛅';
  if (code == 45 || code == 48) return '🌫️';
  if ({51, 53, 55, 61, 63, 65}.contains(code)) return '🌧️';
  if ({71, 73, 75}.contains(code)) return '❄️';
  if ({80, 81, 82}.contains(code)) return '🌦️';
  if ({95, 96, 99}.contains(code)) return '⛈️';
  return '🌤️';
}

String _weatherLabel(int code) {
  if (code == 0) return 'Clear sky';
  if (code <= 3) return 'Partly cloudy';
  if (code == 45 || code == 48) return 'Foggy';
  if (code == 51 || code == 53 || code == 55) return 'Drizzle';
  if (code == 61 || code == 63 || code == 65) return 'Rain';
  if (code == 71 || code == 73 || code == 75) return 'Snow';
  if (code == 80 || code == 81 || code == 82) return 'Showers';
  if (code == 95 || code == 96 || code == 99) return 'Thunderstorm';
  return 'Cloudy';
}

String _dayLabel(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[d.weekday - 1];
}

String _farmingAdvice(List<DayForecast> days) {
  if (days.isEmpty) return '✅ Weather conditions look favorable for farming';
  final avgMax = days.map((d) => d.maxTemp).reduce((a, b) => a + b) / days.length;
  final totalRain = days.map((d) => d.precipitation).reduce((a, b) => a + b);
  final maxWind = days.map((d) => d.windspeed).reduce((a, b) => a > b ? a : b);

  if (avgMax > 35) return '⚠️ High heat alert — consider irrigation scheduling';
  if (totalRain > 50) return '💧 Good rainfall expected — minimal irrigation needed';
  if (totalRain == 0) return '🏜️ No rain forecast — irrigation strongly recommended';
  if (maxWind > 50) return '🌬️ Strong winds expected — protect fragile crops';
  return '✅ Weather conditions look favorable for farming this week';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class MyClimateScreen extends StatefulWidget {
  const MyClimateScreen({super.key});

  @override
  State<MyClimateScreen> createState() => _MyClimateScreenState();
}

class _MyClimateScreenState extends State<MyClimateScreen> {
  bool _loading = true;
  String? _error;
  WeatherData? _weather;

  static const _blue = Color(0xFF1B6E8C);
  static const _blueDark = Color(0xFF0F3D54);
  static const _blueLight = Color(0xFF3A9EC0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final coords = await CoordHistory.load();
      final double lat;
      final double lon;
      if (coords.isNotEmpty) {
        lat = coords.first.lat;
        lon = coords.first.lon;
      } else {
        lat = 33.8;
        lon = 9.5;
      }

      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum'
        ',windspeed_10m_max,weathercode'
        '&current_weather=true'
        '&timezone=Africa%2FTunis',
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Weather API error ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _weather = WeatherData.fromJson(json, lat, lon);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          _Header(blue: _blue, blueDark: _blueDark),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF1B6E8C)),
                    ),
                  )
                : _error != null
                    ? _ErrorView(message: _error!, onRetry: _load)
                    : _Body(
                        weather: _weather!,
                        blue: _blue,
                        blueDark: _blueDark,
                        blueLight: _blueLight,
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Color blue;
  final Color blueDark;
  const _Header({required this.blue, required this.blueDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        22,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [blueDark, blue],
        ),
      ),
      child: Row(
        children: [
          const Text('🌤️', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Climate',
                style: AppTextStyles.headingXL.copyWith(fontSize: 24),
              ),
              Text(
                'Real-time weather for your farm',
                style: AppTextStyles.bodyS.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌩️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Could not load weather',
              style: AppTextStyles.headingS.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyS.copyWith(color: AppColors.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B6E8C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Body (scrollable) ────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final WeatherData weather;
  final Color blue;
  final Color blueDark;
  final Color blueLight;

  const _Body({
    required this.weather,
    required this.blue,
    required this.blueDark,
    required this.blueLight,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
      children: [
        // PART 1 — Current weather card
        _CurrentWeatherCard(weather: weather, blue: blue, blueDark: blueDark)
            .animate()
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.04, end: 0, duration: 350.ms),
        const SizedBox(height: 16),

        // PART 2 — 7-day forecast row
        _ForecastRow(days: weather.daily, blue: blue)
            .animate(delay: 60.ms)
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.04, end: 0, duration: 350.ms),
        const SizedBox(height: 16),

        // PART 3 — Temperature chart
        _TemperatureChart(days: weather.daily, blue: blue, blueLight: blueLight)
            .animate(delay: 120.ms)
            .fadeIn(duration: 350.ms),
        const SizedBox(height: 16),

        // PART 4 — Rainfall chart
        _RainfallChart(days: weather.daily, blue: blue)
            .animate(delay: 180.ms)
            .fadeIn(duration: 350.ms),
        const SizedBox(height: 16),

        // PART 5 — Summary 2×2 grid
        _SummaryGrid(days: weather.daily)
            .animate(delay: 240.ms)
            .fadeIn(duration: 350.ms),
        const SizedBox(height: 16),

        // PART 6 — Farming advice card
        _FarmingAdviceCard(days: weather.daily, blue: blue)
            .animate(delay: 300.ms)
            .fadeIn(duration: 350.ms),
      ],
    );
  }
}

// ─── PART 1: Current Weather Card ────────────────────────────────────────────

class _CurrentWeatherCard extends StatelessWidget {
  final WeatherData weather;
  final Color blue;
  final Color blueDark;

  const _CurrentWeatherCard({
    required this.weather,
    required this.blue,
    required this.blueDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [blueDark, blue],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: blue.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Weather',
                  style: AppTextStyles.bodyS.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${weather.currentTemp.toStringAsFixed(1)}°C',
                  style: AppTextStyles.headingXL.copyWith(fontSize: 42, height: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  _weatherLabel(weather.currentCode),
                  style: AppTextStyles.bodyM.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.air_rounded,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${weather.currentWind.toStringAsFixed(0)} km/h wind',
                      style: AppTextStyles.bodyS.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            _weatherIcon(weather.currentCode),
            style: const TextStyle(fontSize: 72),
          ),
        ],
      ),
    );
  }
}

// ─── PART 2: 7-Day Forecast Row ───────────────────────────────────────────────

class _ForecastRow extends StatelessWidget {
  final List<DayForecast> days;
  final Color blue;
  const _ForecastRow({required this.days, required this.blue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Forecast',
            style: AppTextStyles.headingS.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _ForecastDay(day: days[i], blue: blue),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastDay extends StatelessWidget {
  final DayForecast day;
  final Color blue;
  const _ForecastDay({required this.day, required this.blue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _dayLabel(day.date),
            style: AppTextStyles.bodyS.copyWith(
              fontSize: 11,
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(_weatherIcon(day.weatherCode),
              style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            '${day.maxTemp.toStringAsFixed(0)}°',
            style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.ink),
          ),
          Text(
            '${day.minTemp.toStringAsFixed(0)}°',
            style: AppTextStyles.bodyS.copyWith(
                fontSize: 11, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

// ─── PART 3: Temperature Chart ────────────────────────────────────────────────

class _TemperatureChart extends StatelessWidget {
  final List<DayForecast> days;
  final Color blue;
  final Color blueLight;

  const _TemperatureChart({
    required this.days,
    required this.blue,
    required this.blueLight,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    final maxTemps = days.map((d) => d.maxTemp).toList();
    final minTemps = days.map((d) => d.minTemp).toList();
    final allTemps = [...maxTemps, ...minTemps];
    final rawMin = allTemps.reduce((a, b) => a < b ? a : b);
    final rawMax = allTemps.reduce((a, b) => a > b ? a : b);
    final range = rawMax - rawMin;
    final padding = range < 8 ? (8 - range) / 2 : 2.0;
    final yMin = (rawMin - padding).floorToDouble();
    final yMax = (rawMax + padding).ceilToDouble();

    final maxSpots = maxTemps
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final minSpots = minTemps
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.thermostat_rounded,
                  size: 18, color: Color(0xFF1B6E8C)),
              const SizedBox(width: 8),
              Text('Temperature (°C)',
                  style: AppTextStyles.headingS.copyWith(fontSize: 15)),
              const Spacer(),
              _LegendDot(color: const Color(0xFFE63946), label: 'Max'),
              const SizedBox(width: 12),
              _LegendDot(color: const Color(0xFF1B6E8C), label: 'Min'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (days.length - 1).toDouble(),
                minY: yMin,
                maxY: yMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (yMax - yMin) / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.inkMuted.withValues(alpha: 0.12),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: (yMax - yMin) / 4,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}°',
                        style: AppTextStyles.bodyS.copyWith(
                            fontSize: 9, color: AppColors.inkMuted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox();
                        return Text(
                          _dayLabel(days[i].date),
                          style: AppTextStyles.bodyS.copyWith(
                              fontSize: 9, color: AppColors.inkMuted),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  _line(maxSpots, const Color(0xFFE63946)),
                  _line(minSpots, blue),
                ],
                lineTouchData: const LineTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
          radius: 3.5,
          color: color,
          strokeWidth: 1.5,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.bodyS.copyWith(
                fontSize: 11, color: AppColors.inkMuted)),
      ],
    );
  }
}

// ─── PART 4: Rainfall Chart ───────────────────────────────────────────────────

class _RainfallChart extends StatelessWidget {
  final List<DayForecast> days;
  final Color blue;

  const _RainfallChart({required this.days, required this.blue});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final totalRain =
        days.map((d) => d.precipitation).reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_rounded,
                  size: 18, color: Color(0xFF1B6E8C)),
              const SizedBox(width: 8),
              Text('Rainfall (mm)',
                  style: AppTextStyles.headingS.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          if (totalRain == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Text('🏜️', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    'No rainfall expected this week',
                    style: AppTextStyles.bodyM.copyWith(
                        color: AppColors.inkMuted, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: _computeMaxY(days),
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.inkMuted.withValues(alpha: 0.12),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= days.length) {
                            return const SizedBox();
                          }
                          return Text(
                            _dayLabel(days[i].date),
                            style: AppTextStyles.bodyS.copyWith(
                                fontSize: 9, color: AppColors.inkMuted),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(0),
                          style: AppTextStyles.bodyS.copyWith(
                              fontSize: 9, color: AppColors.inkMuted),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: days.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.precipitation,
                          color: blue.withValues(alpha: 0.80),
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5)),
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(enabled: false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _computeMaxY(List<DayForecast> days) {
    final maxP =
        days.map((d) => d.precipitation).reduce((a, b) => a > b ? a : b);
    if (maxP <= 5) return 10;
    if (maxP <= 20) return (maxP * 1.3).ceilToDouble();
    return (maxP * 1.2).ceilToDouble();
  }
}

// ─── PART 5: Summary 2×2 Grid ────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  final List<DayForecast> days;
  const _SummaryGrid({required this.days});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    final avgMax = days.map((d) => d.maxTemp).reduce((a, b) => a + b) /
        days.length;
    final avgMin = days.map((d) => d.minTemp).reduce((a, b) => a + b) /
        days.length;
    final totalRain =
        days.map((d) => d.precipitation).reduce((a, b) => a + b);
    final maxWind =
        days.map((d) => d.windspeed).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Summary',
            style: AppTextStyles.headingS.copyWith(fontSize: 15)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: '🌡️',
                label: 'Avg High',
                value: '${avgMax.toStringAsFixed(1)}°C',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: '🌙',
                label: 'Avg Low',
                value: '${avgMin.toStringAsFixed(1)}°C',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: '💧',
                label: 'Total Rain',
                value: '${totalRain.toStringAsFixed(1)} mm',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: '💨',
                label: 'Max Wind',
                value: '${maxWind.toStringAsFixed(0)} km/h',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyS.copyWith(
                    fontSize: 10, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.label.copyWith(fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── PART 6: Farming Advice Card ─────────────────────────────────────────────

class _FarmingAdviceCard extends StatelessWidget {
  final List<DayForecast> days;
  final Color blue;

  const _FarmingAdviceCard({required this.days, required this.blue});

  @override
  Widget build(BuildContext context) {
    final advice = _farmingAdvice(days);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: blue.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.agriculture_rounded,
                size: 22, color: Color(0xFF1B6E8C)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Farming Advice',
                  style: AppTextStyles.headingS.copyWith(
                      fontSize: 14, color: const Color(0xFF1B6E8C)),
                ),
                const SizedBox(height: 4),
                Text(
                  advice,
                  style: AppTextStyles.bodyM.copyWith(
                    fontSize: 13,
                    color: AppColors.ink,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
