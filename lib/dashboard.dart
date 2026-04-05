import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'main.dart';


const Color kPrimary = Color(0xFF2E7D32);
const Color kBackground = Color(0xFFF1F6F1);
const Color kGreen = Color(0xFF43A047);
const Color kLightGreen = Color(0xFFE8F5E9);



class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  void _goToHome() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _goToAddPlant() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _goToSettings() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const AddPlantPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: _goToHome,
                hoverColor: kLightGreen,
                icon: Icon(
                  Icons.home_rounded,
                  size: 30,
                  color: _selectedIndex == 0 ? kGreen : const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 50),
              IconButton(
                onPressed: _goToSettings,
                hoverColor: kLightGreen,
                icon: Icon(
                  Icons.settings_rounded,
                  size: 30,
                  color: _selectedIndex == 2 ? kGreen : const Color(0xFF66BB6A),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kGreen,
        hoverColor: const Color(0xFF2E7D32),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onPressed: _goToAddPlant,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class PlantData {
  final String name;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final int soilHumidity;
  final int soilTemp;
  final int light;
  final int airHumidity;
  final int airTemp;
  final int score;
  final String nextWatering;

  const PlantData({
    required this.name,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.soilHumidity,
    required this.soilTemp,
    required this.light,
    required this.airHumidity,
    required this.airTemp,
    required this.score,
    required this.nextWatering,
  });
}

const List<PlantData> plants = [
  PlantData(
    name: 'Mint',
    status: 'Good',
    statusColor: Colors.green,
    icon: Icons.eco_rounded,
    iconBg: Color(0xFFE8F5E9),
    iconColor: Color(0xFF2E7D32),
    soilHumidity: 70,
    soilTemp: 24,
    light: 650,
    airHumidity: 56,
    airTemp: 25,
    score: 86,
    nextWatering: 'in 15h 34m',
  ),
  PlantData(
    name: 'Basil',
    status: 'Okay',
    statusColor: Colors.orange,
    icon: Icons.spa_rounded,
    iconBg: Color(0xFFFFF3E0),
    iconColor: Color(0xFFFB8C00),
    soilHumidity: 52,
    soilTemp: 28,
    light: 480,
    airHumidity: 49,
    airTemp: 27,
    score: 73,
    nextWatering: 'in 9h 10m',
  ),
  PlantData(
    name: 'Peace Lily',
    status: 'Bad',
    statusColor: Colors.red,
    icon: Icons.local_florist_rounded,
    iconBg: Color(0xFFFCE4EC),
    iconColor: Color(0xFFD81B60),
    soilHumidity: 26,
    soilTemp: 33,
    light: 180,
    airHumidity: 38,
    airTemp: 31,
    score: 42,
    nextWatering: 'Now',
  ),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Zr3ahTech',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: GridView.builder(
          itemCount: plants.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final plant = plants[index];
            return PlantCard(plant: plant);
          },
        ),
      ),
    );
  }
}

class PlantCard extends StatefulWidget {
  final PlantData plant;

  const PlantCard({super.key, required this.plant});

  @override
  State<PlantCard> createState() => _PlantCardState();
}

class _PlantCardState extends State<PlantCard> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovering = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlantDetailsPage(plant: plant),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isHovering ? const Color(0xFFF7FFF7) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHovering ? kGreen : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovering
                    ? const Color(0x22000000)
                    : const Color(0x14000000),
                blurRadius: isHovering ? 14 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plant.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: plant.statusColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        plant.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: plant.iconBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        plant.icon,
                        size: 72,
                        color: plant.iconColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddPlantPage extends StatelessWidget {
  const AddPlantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Plant Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Note: Our app is designed for established plants that have already flowered. It does not support seedling plants.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _inputField('Choose Plant'),
            const SizedBox(height: 12),
            _inputField('Enter Pot size (ml)'),
            const SizedBox(height: 12),
            _inputField('Enter soil volume ratio (default 80%)'),
            const SizedBox(height: 18),
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 58,
                    color: Color(0xFF43A047),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Upload Plant Image',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Save Plant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGreen, width: 1.5),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Push Notifications (Recommended)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                secondary: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFFF9800),
                ),
                value: notifications,
                activeColor: kGreen,
                onChanged: (value) {
                  setState(() {
                    notifications = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            const SettingsTile(
              title: 'Help',
              icon: Icons.help_outline_rounded,
              iconColor: Colors.blue,
            ),
            const SettingsTile(
              title: 'About Us',
              icon: Icons.info_outline_rounded,
              iconColor: Colors.green,
            ),
            const SettingsTile(
              title: 'Send Feedback',
              icon: Icons.feedback_outlined,
              iconColor: Colors.orange,
            ),
            const SettingsTile(
              title: 'Contact Us',
              icon: Icons.mail_outline_rounded,
              iconColor: Colors.purple,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // 1. Tell Firebase to log the current user out
                  await FirebaseAuth.instance.signOut();

                  // 2. Redirect the user back to the LoginScreen
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const SettingsTile({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovering = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isHovering ? const Color(0xFFF7FFF7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovering ? kGreen : Colors.transparent,
            width: 1.3,
          ),
        ),
        child: ListTile(
          leading: Icon(widget.icon, color: widget.iconColor),
          title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 18,
            color: kGreen,
          ),
        ),
      ),
    );
  }
}

class PlantDetailsPage extends StatefulWidget {
  final PlantData plant;

  const PlantDetailsPage({super.key, required this.plant});

  @override
  State<PlantDetailsPage> createState() => _PlantDetailsPageState();
}

class _PlantDetailsPageState extends State<PlantDetailsPage> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(plant.name),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: _topButton(
                    'Data overview',
                    Icons.analytics_outlined,
                    const Color(0xFF1E88E5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _topButton(
                    'Edit Plant Profile',
                    Icons.settings,
                    const Color(0xFF43A047),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: _tabButton('Stats', 0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tabButton('Graphs', 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: selectedTab == 0 ? _statsView(plant) : _graphsView(),
          ),
        ],
      ),
    );
  }

  Widget _topButton(String text, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    final isSelected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statsView(PlantData plant) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      children: [
        MetricCard(
          title: 'Soil Humidity',
          value: '${plant.soilHumidity} %',
          status: plant.soilHumidity >= 60
              ? 'Good'
              : plant.soilHumidity >= 40
              ? 'Okay'
              : 'Bad',
          statusColor: plant.soilHumidity >= 60
              ? Colors.green
              : plant.soilHumidity >= 40
              ? Colors.orange
              : Colors.red,
          icon: Icons.water_drop_outlined,
          iconColor: Colors.blue,
          iconBg: const Color(0xFFE3F2FD),
        ),
        MetricCard(
          title: 'Soil Temperature',
          value: '${plant.soilTemp} °C',
          status: plant.soilTemp <= 28 ? 'Good' : 'Bad',
          statusColor: plant.soilTemp <= 28 ? Colors.green : Colors.red,
          icon: Icons.thermostat_outlined,
          iconColor: Colors.deepOrange,
          iconBg: const Color(0xFFFFF3E0),
        ),
        MetricCard(
          title: 'Light',
          value: '${plant.light} Lux',
          status: plant.light >= 500
              ? 'Good'
              : plant.light >= 250
              ? 'Okay'
              : 'Bad',
          statusColor: plant.light >= 500
              ? Colors.green
              : plant.light >= 250
              ? Colors.orange
              : Colors.red,
          icon: Icons.wb_sunny_outlined,
          iconColor: Colors.amber,
          iconBg: const Color(0xFFFFFDE7),
        ),
        MetricCard(
          title: 'Air Humidity',
          value: '${plant.airHumidity} %',
          status: plant.airHumidity >= 45 ? 'Good' : 'Bad',
          statusColor: plant.airHumidity >= 45 ? Colors.green : Colors.red,
          icon: Icons.cloud_outlined,
          iconColor: Colors.lightBlue,
          iconBg: const Color(0xFFE1F5FE),
        ),
        MetricCard(
          title: 'Air Temperature',
          value: '${plant.airTemp} °C',
          status: plant.airTemp <= 28 ? 'Good' : 'Bad',
          statusColor: plant.airTemp <= 28 ? Colors.green : Colors.red,
          icon: Icons.thermostat_auto_outlined,
          iconColor: Colors.redAccent,
          iconBg: const Color(0xFFFFEBEE),
        ),
        MetricCard(
          title: 'Plant Score',
          value: '${plant.score} point',
          status: plant.score >= 70
              ? 'Good'
              : plant.score >= 50
              ? 'Okay'
              : 'Bad',
          statusColor: plant.score >= 70
              ? Colors.green
              : plant.score >= 50
              ? Colors.orange
              : Colors.red,
          icon: Icons.favorite_border,
          iconColor: Colors.pink,
          iconBg: const Color(0xFFFCE4EC),
        ),
        MetricCard(
          title: 'Next Watering',
          value: plant.nextWatering,
          status: plant.nextWatering == 'Now' ? 'Urgent' : 'Predicted',
          statusColor: plant.nextWatering == 'Now' ? Colors.red : Colors.blue,
          icon: Icons.access_time,
          iconColor: Colors.purple,
          iconBg: const Color(0xFFF3E5F5),
        ),
      ],
    );
  }

  Widget _graphsView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      children: const [
        GraphCard(title: 'Light Intensity (Lux)'),
        SizedBox(height: 12),
        GraphCard(title: 'Air Humidity'),
        SizedBox(height: 12),
        GraphCard(title: 'Air Temperature °C'),
        SizedBox(height: 12),
        GraphCard(title: 'Soil Humidity'),
        SizedBox(height: 12),
        GraphCard(title: 'Soil Temperature °C'),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconBg,
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GraphCard extends StatelessWidget {
  final String title;

  const GraphCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: CustomPaint(
        painter: SimpleGraphPainter(),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (double i = 40; i < size.height; i += 35) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        gridPaint,
      );
    }

    final path = Path();
    path.moveTo(10, size.height - 35);
    path.lineTo(size.width * 0.18, size.height - 70);
    path.lineTo(size.width * 0.32, size.height - 45);
    path.lineTo(size.width * 0.48, size.height - 85);
    path.lineTo(size.width * 0.62, size.height - 75);
    path.lineTo(size.width * 0.78, size.height - 105);
    path.lineTo(size.width - 10, size.height - 50);

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

