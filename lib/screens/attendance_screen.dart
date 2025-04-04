import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  bool isConnected = false; // This will be updated based on actual BLE connection status

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _showEnrollmentDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return FutureBuilder(
          future: Future.delayed(const Duration(seconds: 2)),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Dialog(
                backgroundColor: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Enrolling...'),
                    ],
                  ),
                ),
              );
            }
            return Dialog(
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/tick.json',
                      width: 100,
                      height: 100,
                      repeat: false,
                      onLoaded: (composition) {
                        Future.delayed(composition.duration).then((_) {
                          Navigator.of(context).pop();
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              const SizedBox(height: 12),
              // Sync with device button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Write the syncing logic here
                    setState(() {
                      isConnected = !isConnected; // Toggle for testing, replace with actual BLE logic
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isConnected ? 'Disconnect Device' : 'Sync with Device',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Connection status indicator
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _blinkController,
                    builder: (context, child) {
                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected
                              ? Color.lerp(
                                  Colors.green,
                                  Colors.green.withOpacity(0.3),
                                  _blinkController.value,
                                )
                              : Colors.red,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'Device connected' : 'Device not connected',
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              // Students section
              const Text(
                'Students',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: 5, // Replace with actual student count
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2D2F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Profile picture
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[800],
                            child: Text(
                              'S${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Student info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Student${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'UID: 12345${index + 7}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Attendance Status Indicator
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              width: 70, // Fixed width for consistent sizing
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: [const Color.fromARGB(69, 76, 175, 79), const Color.fromARGB(69, 244, 67, 54), const Color.fromARGB(69, 255, 153, 0)][index % 3],
                                borderRadius: BorderRadius.circular(20),
                                //border colour changes with attendance status
                                border: Border.all(
                                  color: [Colors.green, Colors.red, const Color(0xFFFF9800)][index % 3],
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  ['Present', 'Absent', 'Late'][index % 3],
                                  style: TextStyle(
                                    color: [Colors.green, Colors.red, const Color(0xFFFF9800)][index % 3],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Enroll button
                          ElevatedButton(
                            onPressed: () => _showEnrollmentDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF243647),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Enroll'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Save Attendance button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle save attendance
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Attendance',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
