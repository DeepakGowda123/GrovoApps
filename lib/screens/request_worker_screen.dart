import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestWorkerScreen extends StatefulWidget {
  const RequestWorkerScreen({super.key});

  @override
  State<RequestWorkerScreen> createState() => _RequestWorkerScreenState();
}

class _RequestWorkerScreenState extends State<RequestWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // Dummy fields
  String? _selectedWorkType;
  String? _selectedCropType;
  bool _isAadharVerified = false;
  String? _aadharNumber;

  //variables
  String? _locationText;
  Position? _currentPosition;
  bool _isGettingLocation = false;

  String? _selectedGender;
  String? _workDurationType;
  int? _customHours;
  double? _calculatedAmount;

  String? _userPhoneNumber;



  final List<String> workTypes = ['Plowing', 'Harvesting', 'Irrigation'];
  final List<String> cropTypes = ['Wheat', 'Rice', 'Sugarcane'];


  @override
  void initState() {
    super.initState();
    // Get the current user's phone number from FirebaseAuth
    _userPhoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;
  }

  //fetching location
  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

//payment calculation
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

  //verify mobile number
  void _verifyPhoneNumber(String phoneNumber) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval or instant verification
        await FirebaseAuth.instance.signInWithCredential(credential);
        setState(() => _isAadharVerified = true);
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.message}')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        _showOtpDialog(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  //to display dialog to enter mob number
  void _showOtpDialog(String verificationId) {
    final TextEditingController _otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter OTP'),
        content: TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'OTP'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final credential = PhoneAuthProvider.credential(
                verificationId: verificationId,
                smsCode: _otpController.text.trim(),
              );
              try {
                await FirebaseAuth.instance.signInWithCredential(credential);
                setState(() => _isAadharVerified = true);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone verified ✅')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid OTP ❌')),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request a Worker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildDropdown('Work Type', workTypes, (val) {
                setState(() => _selectedWorkType = val);
              }),
              const SizedBox(height: 12),
              _buildDropdown('Crop Type', cropTypes, (val) {
                setState(() => _selectedCropType = val);
              }),
              const SizedBox(height: 12),
              _isGettingLocation
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                label: Text(_locationText ?? 'Get My Farm Location'),
                onPressed: _getLocation,
              ),

              _buildDatePickerField(_startDateController, 'Start Date'),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              _buildDropdown('Worker Gender', ['Male', 'Female'], (val) {
                setState(() {
                  _selectedGender = val;
                  _calculatePayment(); // re-calculate
                });
              }),
              const SizedBox(height: 12),
              _buildDropdown('Work Duration', ['Full Day', 'Custom (Hours)'], (val) {
                setState(() {
                  _workDurationType = val;
                  _calculatePayment(); // re-calculate
                });
              }),
              if (_workDurationType == 'Custom (Hours)')
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Number of Hours',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      _customHours = int.tryParse(val);
                      _calculatePayment(); // re-calculate
                    },
                  ),
                ),


              _buildDatePickerField(_endDateController, 'End Date'),
              if (_calculatedAmount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Estimated Cost: ₹${_calculatedAmount!.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              const SizedBox(height: 12),
              _buildTextField(label: 'Notes/Description', maxLines: 3),

              const Divider(height: 30),
              _buildAadharSection(),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Proceed to Payment'),
                onPressed: () {
                  if (_formKey.currentState!.validate() && _isAadharVerified) {
                    // TODO: Integrate Razorpay & Firestore here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Submitting request... (mocked)')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please complete form and Aadhar verification')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  Widget _buildTextField({required String label, int maxLines = 1, TextInputType? inputType}) {
    return TextFormField(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      maxLines: maxLines,
      keyboardType: inputType,
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDatePickerField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2023),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
          _calculatePayment(); // 👈 ADD THIS LINE HERE
        }
      },
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }



  Widget _buildAadharSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Aadhar Verification', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (!_isAadharVerified)
          Column(
            children: [
              // Add Aadhar number field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Aadhar Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 12,
                onChanged: (value) => _aadharNumber = value,
              ),
              const SizedBox(height: 10),

              // Add Phone Number field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number (For OTP)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 10,
                onChanged: (value) => _userPhoneNumber = value,
              ),
              const SizedBox(height: 10),

              ElevatedButton(
                child: const Text('Send OTP'),
                onPressed: () {
                  if (_aadharNumber != null && _aadharNumber!.length == 12) {
                    // Ensure phone number is provided
                    if (_userPhoneNumber != null && _userPhoneNumber!.length == 10) {
                      _verifyPhoneNumber('+91$_userPhoneNumber');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid phone number')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter valid Aadhar number')),
                    );
                  }
                },
              ),
            ],
          )
        else
          const Text('✅ Aadhar Verified', style: TextStyle(color: Colors.green)),
      ],
    );
  }
}
