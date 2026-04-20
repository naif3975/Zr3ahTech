
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';

import 'firebase_options.dart';
import 'main.dart';

const Color kPrimary = Color(0xFF2E7D32);
const Color kBackground = Color(0xFFF1F6F1);
const Color kGreen = Color(0xFF43A047);
const Color kLightGreen = Color(0xFFE8F5E9);

final FirebaseDatabase rtdb = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: 'https://zr3ahtck-default-rtdb.firebaseio.com/',
);

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  void _goToHome() => setState(() => _selectedIndex = 0);
  void _goToAddPlant() => setState(() => _selectedIndex = 1);
  void _goToSettings() => setState(() => _selectedIndex = 2);

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

class PlantStatusInfo {
  final String label;
  final Color color;

  const PlantStatusInfo({
    required this.label,
    required this.color,
  });
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double _subScore(double value, double min, double max) {
  if (min <= value && value <= max) return 100.0;

  if (value < min) {
    if (min == 0) return 0;
    return (100 - (((min - value) / min) * 100)).clamp(0, 100).toDouble();
  }

  if (max == 0) return 0;
  return (100 - (((value - max) / max) * 100)).clamp(0, 100).toDouble();
}

double _calculateHealthScore(
    Map<String, dynamic> profile,
    Map<dynamic, dynamic> sensorData,
    ) {
  final soilMoisture = _asDouble(sensorData['soil_moisture_percent']);
  final soilTemp = _asDouble(sensorData['soil_temp_c']);
  final airHumidity = _asDouble(sensorData['air_humidity_percent']);
  final airTemp = _asDouble(sensorData['air_temp_c']);
  final light = _asDouble(sensorData['light_lux']);

  final sm = _subScore(
    soilMoisture,
    _asDouble(profile['ideal_soil_moisture_min']),
    _asDouble(profile['ideal_soil_moisture_max']),
  );
  final sst = _subScore(
    soilTemp,
    _asDouble(profile['ideal_soil_temp_min']),
    _asDouble(profile['ideal_soil_temp_max']),
  );
  final sl = _subScore(
    light,
    _asDouble(profile['ideal_light_min']),
    _asDouble(profile['ideal_light_max']),
  );
  final sat = _subScore(
    airTemp,
    _asDouble(profile['ideal_air_temp_min']),
    _asDouble(profile['ideal_air_temp_max']),
  );
  final sah = _subScore(
    airHumidity,
    _asDouble(profile['ideal_air_humidity_min']),
    _asDouble(profile['ideal_air_humidity_max']),
  );

  return (0.35 * sm) + (0.20 * sst) + (0.20 * sl) + (0.15 * sat) + (0.10 * sah);
}

PlantStatusInfo _buildPlantStatus(
    Map<String, dynamic>? profile,
    Map<dynamic, dynamic>? sensorData,
    ) {
  if (profile == null || sensorData == null) {
    return const PlantStatusInfo(label: 'No Data', color: Colors.grey);
  }

  final healthScore = _calculateHealthScore(profile, sensorData);

  if (healthScore >= 80) {
    return const PlantStatusInfo(label: 'Good', color: Colors.green);
  } else if (healthScore >= 55) {
    return const PlantStatusInfo(label: 'Okay', color: Colors.orange);
  } else {
    return const PlantStatusInfo(label: 'Bad', color: Colors.red);
  }
}

PlantStatusInfo _buildMetricStatus(double value, double min, double max) {
  if (min == 0 && max == 0) {
    return const PlantStatusInfo(label: 'No Data', color: Colors.grey);
  }
  if (value >= min && value <= max) {
    return const PlantStatusInfo(label: 'Good', color: Colors.green);
  }

  final tolerance = ((max - min).abs() * 0.25).clamp(5, double.infinity);

  if ((value < min && value >= min - tolerance) ||
      (value > max && value <= max + tolerance)) {
    return const PlantStatusInfo(label: 'Okay', color: Colors.orange);
  }

  return const PlantStatusInfo(label: 'Bad', color: Colors.red);
}

double _calculateWaterNeedMl({
  required double targetMoisture,
  required double currentMoisture,
  required double potSize,
  required double soilRatioPercent,
}) {
  final deficit = targetMoisture - currentMoisture;
  if (deficit <= 0) return 0;
  return (deficit / 100) * (potSize * (soilRatioPercent / 100));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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
        body: const Center(
          child: Text('No logged in user found'),
        ),
      );
    }

    final userPlantsRef = rtdb.ref('user_plants/${user.uid}');
    final sensorRef = rtdb.ref('sensor_data');
    final plantLibraryRef = rtdb.ref('plant_library/plant_library');

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
      body: StreamBuilder<DatabaseEvent>(
        stream: userPlantsRef.onValue,
        builder: (context, userPlantsSnapshot) {
          if (userPlantsSnapshot.hasError) {
            return const Center(child: Text('Error loading plants'));
          }
          if (!userPlantsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userPlantsValue = userPlantsSnapshot.data!.snapshot.value;
          if (userPlantsValue == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No plants added yet.\nTap the + button to add your first plant.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          final userPlantsData =
          Map<dynamic, dynamic>.from(userPlantsValue as Map);
          final plantEntries = userPlantsData.entries.toList();

          return StreamBuilder<DatabaseEvent>(
            stream: sensorRef.onValue,
            builder: (context, sensorSnapshot) {
              final sensorData =
              sensorSnapshot.hasData &&
                  sensorSnapshot.data!.snapshot.value != null
                  ? Map<dynamic, dynamic>.from(
                sensorSnapshot.data!.snapshot.value as Map,
              )
                  : null;

              return StreamBuilder<DatabaseEvent>(
                stream: plantLibraryRef.onValue,
                builder: (context, librarySnapshot) {
                  final libraryData =
                  librarySnapshot.hasData &&
                      librarySnapshot.data!.snapshot.value != null
                      ? Map<dynamic, dynamic>.from(
                    librarySnapshot.data!.snapshot.value as Map,
                  )
                      : <dynamic, dynamic>{};

                  return ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: plantEntries.length,
                    itemBuilder: (context, index) {
                      final entry = plantEntries[index];
                      final plantId = entry.key.toString();
                      final plantData =
                      Map<String, dynamic>.from(entry.value as Map);

                      final plantName =
                          plantData['plant_name']?.toString() ?? 'Unknown Plant';
                      final potSize =
                          plantData['pot_size']?.toString() ?? '-';
                      final soilRatio =
                          plantData['soil_volume_ratio']?.toString() ?? '-';
                      final imageUrl =
                          plantData['image_url']?.toString() ?? '';
                      final plantKey =
                          plantData['plant_key']?.toString() ?? '';

                      final profile =
                      libraryData[plantKey] != null
                          ? Map<String, dynamic>.from(
                        libraryData[plantKey] as Map,
                      )
                          : null;

                      final status = _buildPlantStatus(profile, sensorData);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => PlantDetailsPage(
                                  plantId: plantId,
                                  plantData: plantData,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      width: 92,
                                      height: 92,
                                      color: const Color(0xFFE8F5E9),
                                      child:
                                      imageUrl.isNotEmpty
                                          ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                            ) {
                                          return const Icon(
                                            Icons.local_florist_rounded,
                                            color: kGreen,
                                            size: 42,
                                          );
                                        },
                                      )
                                          : const Icon(
                                        Icons.local_florist_rounded,
                                        color: kGreen,
                                        size: 42,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                plantName,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: status.color.withOpacity(
                                                  0.12,
                                                ),
                                                borderRadius:
                                                BorderRadius.circular(30),
                                              ),
                                              child: Text(
                                                status.label,
                                                style: TextStyle(
                                                  color: status.color,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Pot Size: $potSize ml',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Soil Ratio: $soilRatio%',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Tap to view live data',
                                          style: TextStyle(
                                            color: kGreen,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 18,
                                    color: kGreen,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class AddPlantPage extends StatefulWidget {
  const AddPlantPage({super.key});

  @override
  State<AddPlantPage> createState() => _AddPlantPageState();
}

class _AddPlantPageState extends State<AddPlantPage> {
  final TextEditingController potSizeController = TextEditingController();
  final TextEditingController soilRatioController = TextEditingController(
    text: '80',
  );

  Map<String, dynamic> plantLibrary = {};
  String? selectedPlantKey;
  bool isLoadingPlants = true;
  bool isSaving = false;

  Uint8List? selectedImageBytes;
  String? selectedImageName;

  @override
  void initState() {
    super.initState();
    _loadPlantLibrary();
  }

  Future<void> _loadPlantLibrary() async {
    try {
      final snapshot = await rtdb.ref('plant_library/plant_library').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

        setState(() {
          plantLibrary = data.map(
                (key, value) => MapEntry(
              key.toString(),
              Map<dynamic, dynamic>.from(value as Map),
            ),
          );
          isLoadingPlants = false;
        });
      } else {
        setState(() {
          plantLibrary = {};
          isLoadingPlants = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingPlants = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load plants: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      setState(() {
        selectedImageBytes = bytes;
        selectedImageName = file.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _savePlant() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in first')),
      );
      return;
    }

    if (selectedPlantKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a plant')),
      );
      return;
    }

    final potSizeText = potSizeController.text.trim();
    final soilRatioText = soilRatioController.text.trim();

    if (potSizeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter pot size')),
      );
      return;
    }

    final double? potSize = double.tryParse(potSizeText);
    final double? soilRatio = double.tryParse(soilRatioText);

    if (potSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pot size must be a valid number')),
      );
      return;
    }

    if (soilRatio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Soil volume ratio must be a valid number'),
        ),
      );
      return;
    }

    final selectedPlantData =
    Map<String, dynamic>.from(plantLibrary[selectedPlantKey] as Map);

    setState(() {
      isSaving = true;
    });

    try {
      final newPlantRef = rtdb.ref('user_plants/${user.uid}').push();

      await newPlantRef.set({
        'plant_key': selectedPlantKey,
        'plant_name': selectedPlantData['name'] ?? selectedPlantKey,
        'pot_size': potSize,
        'soil_volume_ratio': soilRatio,
        'image_url': '',
        'created_at': ServerValue.timestamp,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plant saved successfully')),
        );

        potSizeController.clear();
        soilRatioController.text = '80';

        setState(() {
          selectedPlantKey = null;
          selectedImageBytes = null;
          selectedImageName = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save plant: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    potSizeController.dispose();
    soilRatioController.dispose();
    super.dispose();
  }

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
            if (isLoadingPlants)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading plants...'),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: selectedPlantKey,
                decoration: InputDecoration(
                  hintText: 'Choose Plant',
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
                items:
                plantLibrary.entries.map((entry) {
                  final plantData = Map<String, dynamic>.from(
                    entry.value as Map,
                  );
                  final plantName =
                      plantData['name']?.toString() ?? entry.key;

                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(plantName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPlantKey = value;
                  });
                },
              ),
            const SizedBox(height: 12),
            TextField(
              controller: potSizeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter Pot size (ml)',
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
            ),
            const SizedBox(height: 12),
            TextField(
              controller: soilRatioController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter soil volume ratio (default 80%)',
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
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black12),
                ),
                child:
                selectedImageBytes != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.memory(
                    selectedImageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
                    : const Column(
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
            ),
            const SizedBox(height: 10),
            if (selectedImageName != null)
              Text(
                selectedImageName!,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _savePlant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child:
                isSaving
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
                    : const Text(
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
                  await FirebaseAuth.instance.signOut();

                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
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
  final String plantId;
  final Map<String, dynamic> plantData;

  const PlantDetailsPage({
    super.key,
    required this.plantId,
    required this.plantData,
  });

  @override
  State<PlantDetailsPage> createState() => _PlantDetailsPageState();
}

class _PlantDetailsPageState extends State<PlantDetailsPage> {
  int selectedTab = 0;
  int selectedTimeRangeHours = 24; // Default to showing the last 24 hours

  Future<void> _showEditPlantDialog() async {
    final potController = TextEditingController(
      text: widget.plantData['pot_size']?.toString() ?? '',
    );
    final ratioController = TextEditingController(
      text: widget.plantData['soil_volume_ratio']?.toString() ?? '80',
    );

    await showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text('Edit Plant Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: potController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pot Size (ml)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ratioController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Soil Volume Ratio (%)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                  isSaving
                      ? null
                      : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                        title: const Text('Delete Plant'),
                        content: const Text(
                          'Are you sure you want to delete this plant?',
                        ),
                        actions: [
                          TextButton(
                            onPressed:
                                () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed:
                                () => Navigator.pop(context, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await rtdb
                            .ref(
                          'user_plants/${user.uid}/${widget.plantId}',
                        )
                            .remove();

                        if (mounted) {
                          Navigator.pop(context);
                          Navigator.pop(this.context);
                          ScaffoldMessenger.of(
                            this.context,
                          ).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Plant deleted successfully',
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text(
                    'Delete Plant',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                  isSaving
                      ? null
                      : () async {
                    final user = FirebaseAuth.instance.currentUser;
                    final pot = double.tryParse(potController.text.trim());
                    final ratio = double.tryParse(
                      ratioController.text.trim(),
                    );

                    if (user == null || pot == null || ratio == null) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter valid numeric values'),
                        ),
                      );
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                    });

                    await rtdb
                        .ref(
                      'user_plants/${user.uid}/${widget.plantId}',
                    )
                        .update({
                      'pot_size': pot,
                      'soil_volume_ratio': ratio,
                    });

                    if (mounted) {
                      setState(() {
                        widget.plantData['pot_size'] = pot;
                        widget.plantData['soil_volume_ratio'] = ratio;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Plant updated successfully'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kGreen),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plantName = widget.plantData['plant_name']?.toString() ?? 'Plant';

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Plant Details'),
            SizedBox(width: 8),
            Icon(Icons.circle, color: Colors.lightGreenAccent, size: 12),
          ],
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream:
        rtdb
            .ref(
          'plant_library/plant_library/${widget.plantData['plant_key']}',
        )
            .onValue,
        builder: (context, profileSnapshot) {
          final profile =
          profileSnapshot.hasData &&
              profileSnapshot.data!.snapshot.value != null
              ? Map<String, dynamic>.from(
            profileSnapshot.data!.snapshot.value as Map,
          )
              : <String, dynamic>{};

          return StreamBuilder<DatabaseEvent>(
            stream: rtdb.ref('sensor_data').onValue,
            builder: (context, sensorSnapshot) {
              if (sensorSnapshot.hasError) {
                return const Center(child: Text('Error loading sensor data'));
              }

              if (!sensorSnapshot.hasData ||
                  sensorSnapshot.data?.snapshot.value == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final sensorData = Map<dynamic, dynamic>.from(
                sensorSnapshot.data!.snapshot.value as Map,
              );

              final status = _buildPlantStatus(profile, sensorData);
              final double healthScore =
              profile.isNotEmpty
                  ? _calculateHealthScore(profile, sensorData).toDouble()
                  : 0.0;

              final targetMoisture =
                  (_asDouble(profile['ideal_soil_moisture_min']) +
                      _asDouble(profile['ideal_soil_moisture_max'])) /
                      2;

              final currentMoisture = _asDouble(
                sensorData['soil_moisture_percent'],
              );
              final potSize = _asDouble(widget.plantData['pot_size']);
              final soilRatio = _asDouble(widget.plantData['soil_volume_ratio']);

              final double waterNeeded =
              profile.isNotEmpty
                  ? _calculateWaterNeedMl(
                targetMoisture: targetMoisture,
                currentMoisture: currentMoisture,
                potSize: potSize,
                soilRatioPercent: soilRatio == 0 ? 80 : soilRatio,
              )
                  : 0.0;

              return Column(
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.analytics_outlined,
                                  size: 18,
                                  color: Color(0xFF1E88E5),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    plantName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showEditPlantDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.settings,
                                    size: 18,
                                    color: Color(0xFF43A047),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Edit Plant Profile',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                        Expanded(child: _tabButton('Stats', 0)),
                        const SizedBox(width: 8),
                        Expanded(child: _tabButton('Graphs', 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child:
                    selectedTab == 0
                        ? _statsView(
                      sensorData,
                      profile,
                      status,
                      healthScore,
                      waterNeeded,
                    )
                        : _graphsView(),
                  ),
                ],
              );
            },
          );
        },
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

  Widget _statsView(
      Map<dynamic, dynamic> sensorData,
      Map<String, dynamic> profile,
      PlantStatusInfo status,
      double healthScore,
      double waterNeeded,
      ) {
    final soilMoisture = _asDouble(sensorData['soil_moisture_percent']);
    final soilTemp = _asDouble(sensorData['soil_temp_c']);
    final light = _asDouble(sensorData['light_lux']);
    final airHumidity = _asDouble(sensorData['air_humidity_percent']);
    final airTemp = _asDouble(sensorData['air_temp_c']);

    final soilMoistureStatus = _buildMetricStatus(
      soilMoisture,
      _asDouble(profile['ideal_soil_moisture_min']),
      _asDouble(profile['ideal_soil_moisture_max']),
    );
    final soilTempStatus = _buildMetricStatus(
      soilTemp,
      _asDouble(profile['ideal_soil_temp_min']),
      _asDouble(profile['ideal_soil_temp_max']),
    );
    final lightStatus = _buildMetricStatus(
      light,
      _asDouble(profile['ideal_light_min']),
      _asDouble(profile['ideal_light_max']),
    );
    final airHumidityStatus = _buildMetricStatus(
      airHumidity,
      _asDouble(profile['ideal_air_humidity_min']),
      _asDouble(profile['ideal_air_humidity_max']),
    );
    final airTempStatus = _buildMetricStatus(
      airTemp,
      _asDouble(profile['ideal_air_temp_min']),
      _asDouble(profile['ideal_air_temp_max']),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: status.color.withOpacity(0.12),
                child: Icon(Icons.eco, color: status.color),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Plant Status',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Text(
                status.label,
                style: TextStyle(
                  color: status.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFCE4EC),
                child: Icon(Icons.favorite_border, color: Colors.pink),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Health Score',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Text(
                '${healthScore.toStringAsFixed(0)} / 100',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFF3E5F5),
                child: Icon(Icons.waterfall_chart, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Water Recommendation',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Text(
                waterNeeded > 0
                    ? '${waterNeeded.toStringAsFixed(0)} ml'
                    : 'No need',
                style: TextStyle(
                  color: waterNeeded > 0 ? Colors.blue : Colors.green,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        MetricCard(
          title: 'Soil Humidity',
          value: '${soilMoisture.toStringAsFixed(1)} %',
          status: soilMoistureStatus.label,
          statusColor: soilMoistureStatus.color,
          icon: Icons.water_drop_outlined,
          iconColor: Colors.blue,
          iconBg: const Color(0xFFE3F2FD),
        ),
        MetricCard(
          title: 'Soil Temperature',
          value: '${soilTemp.toStringAsFixed(1)} °C',
          status: soilTempStatus.label,
          statusColor: soilTempStatus.color,
          icon: Icons.thermostat_outlined,
          iconColor: Colors.deepOrange,
          iconBg: const Color(0xFFFFF3E0),
        ),
        MetricCard(
          title: 'Light',
          value: '${light.toStringAsFixed(1)} Lux',
          status: lightStatus.label,
          statusColor: lightStatus.color,
          icon: Icons.wb_sunny_outlined,
          iconColor: Colors.amber,
          iconBg: const Color(0xFFFFFDE7),
        ),
        MetricCard(
          title: 'Air Humidity',
          value: '${airHumidity.toStringAsFixed(1)} %',
          status: airHumidityStatus.label,
          statusColor: airHumidityStatus.color,
          icon: Icons.cloud_outlined,
          iconColor: Colors.lightBlue,
          iconBg: const Color(0xFFE1F5FE),
        ),
        MetricCard(
          title: 'Air Temperature',
          value: '${airTemp.toStringAsFixed(1)} °C',
          status: airTempStatus.label,
          statusColor: airTempStatus.color,
          icon: Icons.thermostat_auto_outlined,
          iconColor: Colors.redAccent,
          iconBg: const Color(0xFFFFEBEE),
        ),
      ],
    );
  }

  Widget _graphsView() {
    // 1. Calculate the exact Unix timestamp for the cutoff based on user selection
    int cutoffTimestamp = (DateTime.now()
        .subtract(Duration(hours: selectedTimeRangeHours))
        .millisecondsSinceEpoch / 1000).floor();

    return Column(
      children: [
        // 2. The Time Range Toggle Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1H')),
                ButtonSegment(value: 6, label: Text('6H')),
                ButtonSegment(value: 24, label: Text('24H')),
                ButtonSegment(value: 168, label: Text('7D')),
              ],
              selected: {selectedTimeRangeHours},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  selectedTimeRangeHours = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: const Color(0xFFE8F5E9), // Light green tint
                selectedForegroundColor: kGreen,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. The Filtered Firebase Stream
        Expanded(
          child: StreamBuilder<DatabaseEvent>(
            // NEW QUERY: Order by the timestamp, and only grab points after our cutoff
            stream: rtdb.ref('sensor_history')
                .orderByChild('timestamp')
                .startAt(cutoffTimestamp)
                .onValue,
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Error loading history'));
              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: kGreen),
                      SizedBox(height: 16),
                      Text('Fetching data...', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                );
              }

              // Parse the history data
              final historyMap = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);

              return InteractiveMasterGraph(historyData: historyMap);
            },
          ),
        ),
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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

class InteractiveMasterGraph extends StatefulWidget {
  final Map<dynamic, dynamic> historyData;

  const InteractiveMasterGraph({super.key, required this.historyData});

  @override
  State<InteractiveMasterGraph> createState() => _InteractiveMasterGraphState();
}

class _InteractiveMasterGraphState extends State<InteractiveMasterGraph> {
  String selectedMetric = 'light_lux';

  @override
  Widget build(BuildContext context) {
    var sortedKeys = widget.historyData.keys.toList()..sort();

    List<FlSpot> spots = [];
    List<int> timestamps = [];
    double index = 0;

    for (var key in sortedKeys) {
      var entry = Map<dynamic, dynamic>.from(widget.historyData[key] as Map);
      double val = double.tryParse(entry[selectedMetric]?.toString() ?? '0') ?? 0.0;
      int ts = int.tryParse(entry['timestamp']?.toString() ?? '0') ?? 0;

      spots.add(FlSpot(index, val));
      timestamps.add(ts);
      index++;
    }

    // NEW: Calculate Exact Stats for the Bottom Row
    double exactMin = spots.isEmpty ? 0 : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double exactMax = spots.isEmpty ? 0 : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    double sum = spots.isEmpty ? 0 : spots.map((e) => e.y).reduce((a, b) => a + b);
    double avg = spots.isEmpty ? 0 : sum / spots.length;

    // Graph Y-Axis Scaling logic
    double minY = exactMin;
    double maxY = exactMax;
    if (minY == maxY) {
      minY -= 5;
      maxY += 5;
    }

    Color lineColor;
    String graphTitle;

    switch (selectedMetric) {
      case 'soil_moisture_percent':
        lineColor = Colors.blue;
        graphTitle = 'Soil Humidity (%)';
        break;
      case 'soil_temp_c':
        lineColor = Colors.deepOrange;
        graphTitle = 'Soil Temperature (°C)';
        break;
      case 'air_humidity_percent':
        lineColor = Colors.lightBlue;
        graphTitle = 'Air Humidity (%)';
        break;
      case 'air_temp_c':
        lineColor = Colors.redAccent;
        graphTitle = 'Air Temperature (°C)';
        break;
      default:
        lineColor = Colors.amber;
        graphTitle = 'Light Intensity (Lux)';
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              _buildToggleButton('Light', 'light_lux', Icons.wb_sunny, Colors.amber),
              _buildToggleButton('Soil Hum', 'soil_moisture_percent', Icons.water_drop, Colors.blue),
              _buildToggleButton('Soil Temp', 'soil_temp_c', Icons.thermostat, Colors.deepOrange),
              _buildToggleButton('Air Hum', 'air_humidity_percent', Icons.cloud, Colors.lightBlue),
              _buildToggleButton('Air Temp', 'air_temp_c', Icons.thermostat_auto, Colors.redAccent),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 350, // Increased height to make room for the bottom text
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                graphTitle,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: spots.isEmpty
                    ? const Center(child: Text("Waiting for data..."))
                    : LineChart(
                  LineChartData(
                    minY: minY - (maxY - minY) * 0.1,
                    maxY: maxY + (maxY - minY) * 0.2,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: spots.length > 4 ? (spots.length / 4).ceilToDouble() : 1,
                          getTitlesWidget: (value, meta) {
                            if (value % meta.appliedInterval != 0) {
                              return const SizedBox.shrink();
                            }
                            int idx = value.toInt();
                            if (idx < 0 || idx >= timestamps.length || timestamps[idx] == 0) {
                              return const SizedBox.shrink();
                            }
                            DateTime time = DateTime.fromMillisecondsSinceEpoch(timestamps[idx] * 1000);
                            String hour = time.hour.toString().padLeft(2, '0');
                            String min = time.minute.toString().padLeft(2, '0');
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('$hour:$min', style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) => Colors.black87,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            int idx = spot.x.toInt();
                            String timeStr = "";
                            if (idx >= 0 && idx < timestamps.length && timestamps[idx] != 0) {
                              DateTime time = DateTime.fromMillisecondsSinceEpoch(timestamps[idx] * 1000);
                              timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}\n";
                            }
                            return LineTooltipItem(
                              '$timeStr${spot.y.toStringAsFixed(1)}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: lineColor,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: lineColor.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
              ),
              const SizedBox(height: 12), // Spacer below the graph

              // NEW: The Summary Stats Row!
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Min', exactMin.toStringAsFixed(1), lineColor),
                    _buildStatItem('Avg', avg.toStringAsFixed(1), lineColor),
                    _buildStatItem('Max', exactMax.toStringAsFixed(1), lineColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget to build the individual text blocks for Min/Avg/Max
  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor, // Matches the color of the graph line!
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, String metricKey, IconData icon, Color color) {
    bool isSelected = selectedMetric == metricKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        avatar: Icon(icon, color: isSelected ? Colors.white : color, size: 18),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        selectedColor: color,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        onSelected: (bool selected) {
          setState(() {
            selectedMetric = metricKey;
          });
        },
      ),
    );
  }
}
