import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:proyecto_final/presentation/screens/history_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _totalScans = 0;
  Map<String, int> _breedsCount = {};
  Map<String, int> _scansByDay = {
    'Lun': 0, 'Mar': 0, 'Mié': 0, 'Jue': 0, 'Vie': 0, 'Sáb': 0, 'Dom': 0
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      // Obtener todos los escaneos
      final snapshot = await _firestore.collection('historial').get();
      final scans = snapshot.docs;
      
      _totalScans = scans.length;
      
      // Contar razas
      _breedsCount = {};
      for (var doc in scans) {
        final breed = doc['breed'] as String? ?? 'Desconocido';
        _breedsCount[breed] = (_breedsCount[breed] ?? 0) + 1;
      }
      
      // Contar escaneos por día de la semana
      _scansByDay = {'Lun': 0, 'Mar': 0, 'Mié': 0, 'Jue': 0, 'Vie': 0, 'Sáb': 0, 'Dom': 0};
      for (var doc in scans) {
        final timestamp = doc['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final weekday = timestamp.toDate().weekday;
          // weekday: 1=Lunes, 7=Domingo
          final dayName = _getDayName(weekday);
          _scansByDay[dayName] = (_scansByDay[dayName] ?? 0) + 1;
        }
      }
      
    } catch (e) {
      print('Error cargando estadísticas: $e');
    }
    
    setState(() => _isLoading = false);
  }

  String _getDayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[weekday - 1];
  }

  List<MapEntry<String, int>> _getTopBreeds() {
    final entries = _breedsCount.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: const Color(0xFFE85D04),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
            tooltip: 'Ver historial',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de resumen
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    
                    // Gráfico 1: TOP 5 razas
                    if (_breedsCount.isNotEmpty) ...[
                      const Text(
                        '🏆 Razas más escaneadas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildTopBreedsChart(),
                    ],
                    const SizedBox(height: 32),
                    
                    // Gráfico 2: Escaneos por día
                    if (_totalScans > 0) ...[
                      const Text(
                        '📅 Escaneos por día',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildWeeklyChart(),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final topBreeds = _getTopBreeds();
    final mostScannedBreed = topBreeds.isNotEmpty ? topBreeds.first.key : 'Ninguna';
    final mostScannedCount = topBreeds.isNotEmpty ? topBreeds.first.value : 0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCircle(
                  label: 'Total\nEscaneos',
                  value: _totalScans.toString(),
                  icon: Icons.camera_alt,
                  color: Colors.blue,
                ),
                _StatCircle(
                  label: 'Razas\nÚnicas',
                  value: _breedsCount.length.toString(),
                  icon: Icons.pets,
                  color: Colors.green,
                ),
                _StatCircle(
                  label: 'Top Raza',
                  value: mostScannedBreed,
                  subtitle: '$mostScannedCount veces',
                  icon: Icons.emoji_events,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBreedsChart() {
    final topBreeds = _getTopBreeds();
    if (topBreeds.isEmpty) return const SizedBox.shrink();
    
    double maxValue = topBreeds.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();
    
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue + 1,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < topBreeds.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        topBreeds[index].key.length > 10 
                            ? '${topBreeds[index].key.substring(0, 9)}...' 
                            : topBreeds[index].key,
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 50,
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
          barGroups: List.generate(topBreeds.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: topBreeds[index].value.toDouble(),
                  color: Colors.orange,
                  width: 30,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final days = _scansByDay.keys.toList();
    final values = _scansByDay.values.toList();
    final maxValue = values.isEmpty ? 5.0 : values.reduce((a, b) => a > b ? a : b).toDouble() + 1;
    
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 35),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(days[index], style: const TextStyle(fontSize: 12)),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 35,
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
          barGroups: List.generate(days.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index].toDouble(),
                  color: Colors.teal,
                  width: 30,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// Widget auxiliar para las estadísticas circulares
class _StatCircle extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCircle({
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}