import 'package:flutter/material.dart';
import '../models/fish_item.dart';

class FishDetailScreen extends StatelessWidget {
  final FishItem fish;

  const FishDetailScreen({super.key, required this.fish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 32),
                  _buildMetricDashboard(),
                  const SizedBox(height: 32),
                  _buildDescriptionSection(),
                  const SizedBox(height: 32),
                  _buildAIOptimizationSection(),
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildActionFooter(),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.blue.shade50,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Center(child: Text(fish.icon, style: const TextStyle(fontSize: 100))),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fish.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                Row(
                  children: [
                    Text("Konkani: ${fish.konkani}", style: TextStyle(fontSize: 14, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Text("Marathi: ${fish.marathi}", style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            _buildTrendBadge(),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendBadge() {
    bool isUp = fish.trend == 'up';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUp ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(isUp ? Icons.trending_up : Icons.trending_down, color: isUp ? Colors.green : Colors.red, size: 20),
          Text(isUp ? 'PRICE UP' : 'STABLE', style: TextStyle(color: isUp ? Colors.green : Colors.red, fontSize: 8, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildMetricDashboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildMetricRow(Icons.currency_rupee, "Market Price", "₹${fish.avgPrice.toInt()}/kg", Colors.green),
          const Divider(height: 24),
          _buildMetricRow(Icons.waves, "Habitat", fish.water, Colors.blue),
          const Divider(height: 24),
          _buildMetricRow(Icons.calendar_month, "Best Season", fish.season, Colors.orange),
          const Divider(height: 24),
          _buildMetricRow(Icons.location_on, "Common Area", fish.location, Colors.red),
          const Divider(height: 24),
          _buildMetricRow(Icons.access_time, "Catch Time", fish.catchingTime, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("BIOLOGY & USES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Text(fish.description, style: const TextStyle(fontSize: 16, color: Color(0xFF475569), height: 1.6)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Text("Best for: ${fish.uses}", style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildAIOptimizationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade700]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("AI RECOMMENDATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Based on today's environmental conditions, ${fish.name} is ${fish.isBanned ? 'NOT ALLOWED due to monsoon fishing ban.' : 'HIGHLY RECOMMENDED as market demand is peaking and sea conditions are stable.'}",
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleBadge(Icons.star, "Demand: ${fish.demand}/5"),
              _buildSimpleBadge(Icons.check_circle, "Verified"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('VIEW NEARBY MARKETS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
