import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class RequestWorkerScreen extends StatefulWidget {
  final User user;
  const RequestWorkerScreen({super.key, required this.user});

  @override
  State<RequestWorkerScreen> createState() => _RequestWorkerScreenState();
}

class _RequestWorkerScreenState extends State<RequestWorkerScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Form fields
  String? _selectedWorkType;
  String? _selectedCropType;
  String? _selectedGender;
  String? _workDurationType;

  // Work information
  int? _customHours;
  double? _calculatedAmount;
  late AnimationController _animationController;

  // Location related
  String? _locationText;
  Position? _currentPosition;
  bool _isGettingLocation = false;

  // Verification related
  bool _isAadharVerified = false;
  String? _aadharNumber;
  String? _userPhoneNumber;

  // Payment
  late Razorpay _razorpay;

  // Options
  final List<String> workTypes = ['Plowing', 'Harvesting', 'Irrigation', 'Seeding', 'Fertilizing'];
  final List<String> cropTypes = ['Wheat', 'Rice', 'Sugarcane', 'Cotton', 'Corn', 'Vegetables'];

  // UI Animation
  late Animation<double> _fadeAnimation;
  int _currentStep = 0;
  final int _totalSteps = 3;

  @override
  void initState() {
    super.initState();

    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
    );

    _animationController.forward();

    // Get the current user's phone number
    _userPhoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;

    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _checkAadharVerification();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _notesController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _animationController.dispose();
    super.dispose();
  }


  void _checkAadharVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('farmers').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['aadharVerified'] == true) {
          setState(() {
            _isAadharVerified = true;
            _aadharNumber = data['aadharNumber']; // You can mask & display last 4 digits
          });
        }
      }
    }
  }

  void _startWorkerPayment() async {
    if (_calculatedAmount == null) {
      _showSnackBar('Amount not calculated');
      return;
    }

    try {
      var options = {
        'key': 'rzp_test_TTR8Gdu8mLDJUe',
        'amount': (_calculatedAmount! * 100).toInt(),
        'name': 'Worker Hiring',
        'description': 'Payment for hiring a farm worker',
        'prefill': {
          'contact': _userPhoneNumber ?? '9999999999',
          'email': 'farmer@example.com',
        },
        'external': {
          'wallets': ['paytm', 'gpay', 'phonepe'],
        },
        'theme': {
          'color': '#4CAF50',
        }
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      _showSnackBar('Failed to start payment: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _showSnackBar('Payment Successful! Request Submitted.');

    try {
      final farmerId = widget.user.uid;

      final requestData = {
        'workType': _selectedWorkType,
        'cropType': _selectedCropType,
        'location': _locationText,
        'locationLat': _currentPosition?.latitude,
        'locationLng': _currentPosition?.longitude,
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'gender': _selectedGender,
        'workDuration': _workDurationType,
        'customHours': _customHours,
        'notes': _notesController.text,
        'landlordId': FirebaseAuth.instance.currentUser!.uid, // ✅ ADD THIS
        'aadharNumber': _aadharNumber,
        'amount': _calculatedAmount,
        'status': 'paid',
        'paymentId': response.paymentId,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(farmerId)
          .collection('workerRequests')
          .add(requestData);

      // Reset form
      _formKey.currentState?.reset();
      setState(() {
        _calculatedAmount = null;
        _aadharNumber = null;
        _isAadharVerified = false;
        _locationText = null;
        _currentStep = 0; // Reset to first step
      });

      _showSuccessDialog();

    } catch (e) {
      debugPrint('Error saving request: $e');
      _showSnackBar('Error saving request: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            const Text('Success')
          ],
        ),
        content: const Text('Your worker request has been created successfully. You will be notified when workers accept your request.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showSnackBar('Payment Failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showSnackBar('Using wallet: ${response.walletName}');
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Please enable location services');
        setState(() => _isGettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      final place = placemarks.first;

      setState(() {
        _locationText = "${place.subLocality}, ${place.locality}, "
            "${place.subAdministrativeArea}, ${place.administrativeArea}";
      });
    } catch (e) {
      _showSnackBar('Failed to get location: $e');
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _calculatePayment() {
    if (_selectedGender == null ||
        _workDurationType == null ||
        _startDateController.text.isEmpty ||
        _endDateController.text.isEmpty) {
      setState(() => _calculatedAmount = null);
      return;
    }

    final start = DateFormat('yyyy-MM-dd').parse(_startDateController.text);
    final end = DateFormat('yyyy-MM-dd').parse(_endDateController.text);
    final days = end.difference(start).inDays + 1;

    double ratePerDay = _selectedGender == 'Male' ? 500 : 400;
    double ratePerHour = _selectedGender == 'Male' ? 85 : 65;

    setState(() {
      if (_workDurationType == 'Full Day') {
        _calculatedAmount = ratePerDay * days;
      } else if (_customHours != null && _customHours! > 0) {
        _calculatedAmount = ratePerHour * _customHours! * days;
      } else {
        _calculatedAmount = null;
      }
    });
  }

  void _verifyPhoneNumber(String phoneNumber) async {
    _showSnackBar('Sending OTP to $phoneNumber...');

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          // 🔗 Link phone to current user (instead of signing in)
          await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);

          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // 🔥 Save aadharVerified and aadharNumber in Firestore
            await FirebaseFirestore.instance.collection('farmers').doc(user.uid).set({
              'aadharVerified': true,
              'aadharNumber': _aadharNumber, // Make sure _aadharNumber is already filled
            }, SetOptions(merge: true));
          }

          setState(() => _isAadharVerified = true);
          _showSnackBar('Phone verified automatically ✅');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'provider-already-linked') {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await FirebaseFirestore.instance.collection('farmers').doc(user.uid).set({
                'aadharVerified': true,
                'aadharNumber': _aadharNumber,
              }, SetOptions(merge: true));
            }

            setState(() => _isAadharVerified = true);
            _showSnackBar('Phone already verified ✅');
          } else {
            _showSnackBar('Verification error: ${e.message}');
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        _showSnackBar('Verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        _showOtpDialog(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }



  void _showOtpDialog(String verificationId) {
    final TextEditingController _otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Enter OTP', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the 6-digit code sent to your phone'),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '······',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final smsCode = _otpController.text.trim();
              final credential = PhoneAuthProvider.credential(
                verificationId: verificationId,
                smsCode: smsCode,
              );

              try {
                final user = FirebaseAuth.instance.currentUser;

                if (user != null) {
                  // 🔗 Don't sign in — link the credential
                  await user.linkWithCredential(credential);

                  // ✅ Save Aadhar info
                  await FirebaseFirestore.instance.collection('farmers').doc(user.uid).set({
                    'aadharVerified': true,
                    'aadharNumber': _aadharNumber,
                  }, SetOptions(merge: true));

                  setState(() => _isAadharVerified = true);
                  Navigator.pop(context);
                  _showSnackBar('Phone verified ✅');
                } else {
                  _showSnackBar('No logged-in user found ❌');
                }
              } on FirebaseAuthException catch (e) {
                if (e.code == 'provider-already-linked') {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance.collection('farmers').doc(user.uid).set({
                      'aadharVerified': true,
                      'aadharNumber': _aadharNumber,
                    }, SetOptions(merge: true));

                    setState(() => _isAadharVerified = true);
                    Navigator.pop(context);
                    _showSnackBar('Phone already verified ✅');
                  }
                } else {
                  _showSnackBar('Verification failed: ${e.message}');
                }
              } catch (e) {
                _showSnackBar('Invalid OTP ❌');
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Request a Worker'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[800],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      children: List.generate(_totalSteps, (index) {
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: index <= _currentStep ? Colors.green : Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ['Work Details', 'Verification', 'Payment'][_currentStep],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800]
                          ),
                        ),
                        Text(
                          'Step ${_currentStep + 1} of $_totalSteps',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: [
                      _buildWorkDetailsStep(),
                      _buildVerificationStep(),
                      _buildPaymentStep(),
                    ][_currentStep],
                  ),
                ),
              ),

              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prevStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.green[700]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Previous', style: TextStyle(color: Colors.green[700])),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentStep == _totalSteps - 1) {
                            if (_formKey.currentState!.validate() && _isAadharVerified) {
                              _startWorkerPayment();
                            } else {
                              _showSnackBar('Please complete all required fields and verify Aadhar');
                            }
                          } else {
                            // Validate current step before proceeding
                            bool canProceed = true;

                            if (_currentStep == 0) {
                              // Validate work details
                              canProceed = _selectedWorkType != null &&
                                  _selectedCropType != null &&
                                  _locationText != null &&
                                  _startDateController.text.isNotEmpty &&
                                  _endDateController.text.isNotEmpty &&
                                  _selectedGender != null &&
                                  _workDurationType != null;

                              if (_workDurationType == 'Custom (Hours)' && (_customHours == null || _customHours! <= 0)) {
                                canProceed = false;
                              }
                            }

                            if (_currentStep == 1) {
                              // Verify Aadhar
                              canProceed = _isAadharVerified;
                            }

                            if (canProceed) {
                              _nextStep();
                            } else {
                              _showSnackBar('Please complete all required fields');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentStep == _totalSteps - 1 ? 'Pay & Submit' : 'Continue',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Work Type'),
        const SizedBox(height: 8),
        _buildDropdown('Select work type', workTypes, (val) {
          setState(() => _selectedWorkType = val);
        }),

        const SizedBox(height: 24),
        _buildSectionTitle('Crop Type'),
        const SizedBox(height: 8),
        _buildDropdown('Select crop type', cropTypes, (val) {
          setState(() => _selectedCropType = val);
        }),

        const SizedBox(height: 24),
        _buildSectionTitle('Location'),
        const SizedBox(height: 8),
        _buildLocationSelector(),

        const SizedBox(height: 24),
        _buildSectionTitle('Work Period'),
        const SizedBox(height: 8),
        _buildDateField(_startDateController, 'Start Date', Icons.calendar_today),
        const SizedBox(height: 12),
        _buildDateField(_endDateController, 'End Date', Icons.calendar_today),

        const SizedBox(height: 24),
        _buildSectionTitle('Worker Preference'),
        const SizedBox(height: 8),
        _buildGenderSelector(),

        const SizedBox(height: 24),
        _buildSectionTitle('Work Duration'),
        const SizedBox(height: 8),
        _buildDurationSelector(),

        if (_workDurationType == 'Custom (Hours)') ...[
          const SizedBox(height: 16),
          _buildHoursInput(),
        ],

        const SizedBox(height: 24),
        _buildSectionTitle('Additional Notes'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _notesController,
          hintText: 'Add any special requirements or notes for the worker...',
          maxLines: 3,
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.green[700], size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Aadhar Verification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (!_isAadharVerified) ...[
                const Text(
                  'Please verify your identity by providing your Aadhar number and verifying your phone.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                _buildTextField(
                  prefixIcon: Icons.credit_card,
                  hintText: 'Enter 12-digit Aadhar Number',
                  maxLength: 12,
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _aadharNumber = value,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  prefixIcon: Icons.phone_android,
                  hintText: 'Phone Number (for OTP verification)',
                  maxLength: 10,
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => _userPhoneNumber = value,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.message),
                    label: const Text('Send OTP', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (_aadharNumber != null && _aadharNumber!.length == 12) {
                        if (_userPhoneNumber != null && _userPhoneNumber!.length == 10) {
                          _verifyPhoneNumber('+91$_userPhoneNumber');
                        } else {
                          _showSnackBar('Enter a valid phone number');
                        }
                      } else {
                        _showSnackBar('Enter valid Aadhar number');
                      }
                    },
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Verification Complete',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              if (_aadharNumber != null)
                                Text(
                                  'Aadhar Number: XXXX XXXX ${_aadharNumber!.substring(_aadharNumber!.length - 4)}',
                                  style: TextStyle(color: Colors.grey[700]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPaymentStep() {
    final bool canProceed = _calculatedAmount != null && _isAadharVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const Divider(height: 30),

              _buildSummaryItem('Work Type', _selectedWorkType ?? 'Not selected'),
              _buildSummaryItem('Crop Type', _selectedCropType ?? 'Not selected'),
              _buildSummaryItem('Location', _locationText ?? 'Not selected'),
              _buildSummaryItem('Period', '${_startDateController.text} to ${_endDateController.text}'),
              _buildSummaryItem('Worker', _selectedGender ?? 'Not selected'),
              _buildSummaryItem(
                  'Duration',
                  _workDurationType == 'Full Day'
                      ? 'Full Day'
                      : '$_customHours hours per day'
              ),

              const Divider(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  Text(
                    '₹${_calculatedAmount?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Icon(Icons.payments_outlined, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Secure Online Payment',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pay using Credit/Debit Card, UPI, Wallet or Net Banking',
                style: TextStyle(color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Replace network images with local placeholders or handle them properly
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Replaced network images with local image placeholders
                    // You should replace these with local assets or properly sized images
                    Image.network(
                      'https://cdn.razorpay.com/logo.svg', // Replace with your local asset
                      height: 30,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 30, width: 60, color: Colors.grey[300]),
                    ),
                    const SizedBox(width: 8),
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Visa_logo.png/640px-Visa_logo.png', // Replace with your local asset
                      height: 20,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 20, width: 40, color: Colors.grey[300]),
                    ),
                    const SizedBox(width: 8),
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/772px-Mastercard-logo.svg.png',// Replace with your local asset
                      height: 20,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 20, width: 40, color: Colors.grey[300]),
                    ),
                    const SizedBox(width: 8),
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/UPI-Logo-vector.svg/640px-UPI-Logo-vector.svg.png', // Replace with your local asset
                      height: 20,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 20, width: 40, color: Colors.grey[300]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.green[800],
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> options, Function(String?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.green[700]),
        isExpanded: true,
        validator: (value) => value == null ? 'Required' : null,
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon, color: Colors.green[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2030),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.green[700]!,
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            controller.text = DateFormat('yyyy-MM-dd').format(picked);
            _calculatePayment();
          }
        },
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? hintText,
    int maxLines = 1,
    int? maxLength,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          counterText: '',
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.green[700]) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: _getLocation,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.green[700],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isGettingLocation
                    ? Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green[700]!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Getting location...'),
                  ],
                )
                    : Text(
                  _locationText ?? 'Tap to get farm location',
                  style: TextStyle(
                    color: _locationText == null ? Colors.grey[600] : Colors.black,
                  ),
                ),
              ),
              if (_locationText != null)
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.green[700]),
                  onPressed: _getLocation,
                  tooltip: 'Refresh location',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSelectionCard(
            isSelected: _selectedGender == 'Male',
            onTap: () => setState(() {
              _selectedGender = 'Male';
              _calculatePayment();
            }),
            icon: Icons.man,
            label: 'Male',
            description: '₹500/day',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSelectionCard(
            isSelected: _selectedGender == 'Female',
            onTap: () => setState(() {
              _selectedGender = 'Female';
              _calculatePayment();
            }),
            icon: Icons.woman,
            label: 'Female',
            description: '₹400/day',
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSelectionCard(
            isSelected: _workDurationType == 'Full Day',
            onTap: () => setState(() {
              _workDurationType = 'Full Day';
              _calculatePayment();
            }),
            icon: Icons.wb_sunny,
            label: 'Full Day',
            description: '8 hours',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSelectionCard(
            isSelected: _workDurationType == 'Custom (Hours)',
            onTap: () => setState(() {
              _workDurationType = 'Custom (Hours)';
              _calculatePayment();
            }),
            icon: Icons.schedule,
            label: 'Custom Hours',
            description: 'Hourly rate',
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required String description,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.green[700] : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green[700] : Colors.black,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: 'Enter hours per day',
          prefixIcon: Icon(Icons.access_time, color: Colors.green[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: TextInputType.number,
        onChanged: (val) {
          _customHours = int.tryParse(val);
          _calculatePayment();
        },
      ),
    );
  }
}