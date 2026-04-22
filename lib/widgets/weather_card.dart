import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/weather_service.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData? weather;
  final bool isLoading;

  const WeatherCard({super.key, this.weather, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildContainer(
        child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
      );
    }

    if (weather == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          const Icon(Icons.cloud_off, color: Colors.grey),
          const SizedBox(width: 10),
          Text('Weather unavailable', style: GoogleFonts.poppins(color: Colors.grey)),
        ]),
      );
    }

    final w = weather!;
    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Text('Weather Report', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(w.icon, style: const TextStyle(fontSize: 52)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${w.temperature.toStringAsFixed(1)}°C',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      w.description,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              _extraInfo(Icons.water_drop, '${w.humidity}%'),
              const SizedBox(width: 12),
              _extraInfo(Icons.air, '${w.windspeed}km/h'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _extraInfo(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
