import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Initial check
    _checkCurrentConnectivity();
    // Stream listener
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });
  }

  Future<void> _checkCurrentConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hasConnection = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    setState(() {
      _isOffline = !hasConnection;
    });
  }

  Future<void> _manualRetry() async {
    setState(() {
      _isChecking = true;
    });
    
    // Simulate a brief delay for elegant loading micro-animation
    await Future.delayed(const Duration(milliseconds: 1200));
    
    final result = await Connectivity().checkConnectivity();
    final hasConnection = result.isNotEmpty && !result.contains(ConnectivityResult.none);
    
    if (mounted) {
      setState(() {
        _isOffline = !hasConnection;
        _isChecking = false;
      });
      
      if (hasConnection) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi, color: Colors.white),
                SizedBox(width: 12),
                Text("Internet connection restored!", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) {
      return widget.child;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Blurs the underlying application child (Glassmorphism look)
          widget.child,
          
          // Premium Overlay Cover
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E1B4B).withOpacity(0.92),
                  const Color(0xFF311042).withOpacity(0.94),
                  Colors.black.withOpacity(0.96),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    
                    // Animated-like Glowing Offline Icon
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.35),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.18),
                            blurRadius: 44,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.wifi_off_rounded,
                        size: 78,
                        color: Colors.redAccent.shade200,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Main Title
                    const Text(
                      "No Internet Connection",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Subtitle
                    Text(
                      "Please check your internet connection or Wi-Fi settings to continue using the application.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.65),
                        height: 1.5,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Beautiful custom Retry Button with loading indicators
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isChecking ? null : _manualRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E1B4B),
                          elevation: 8,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isChecking
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 22),
                                  SizedBox(width: 10),
                                  Text(
                                    "Retry",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
