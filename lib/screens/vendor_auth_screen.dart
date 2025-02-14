


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:grovo_app/screens/AnimatedSplashScreen.dart';
// import 'vendor_dashboard_screen.dart';

// class VendorAuthScreen extends StatefulWidget {
//   @override
//   _VendorAuthScreenState createState() => _VendorAuthScreenState();
// }

// class _VendorAuthScreenState extends State<VendorAuthScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _shopNameController = TextEditingController();
//   final TextEditingController _gstController = TextEditingController();
//   final TextEditingController _locationController = TextEditingController();
//   final TextEditingController _mobileController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();
//   bool isLogin = true;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool _obscurePassword = true;
//   bool _isLoading = false;

//   void toggleAuthMode() {
//     setState(() {
//       isLogin = !isLogin;
//     });
//   }

//   Future<bool> _isGstUnique(String gstNumber) async {
//     final snapshot = await _firestore
//         .collection('vendors')
//         .where('gstNumber', isEqualTo: gstNumber)
//         .get();
//     return snapshot.docs.isEmpty;
//   }

//   Future<void> _authenticate() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _isLoading = true;
//     });

//     String email = '${_mobileController.text}@grovo.com';
//     String password = _passwordController.text;

//     try {
//       if (isLogin) {
//         // Login
//         UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//           email: email,
//           password: password,
//         );

//         if (userCredential.user != null) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => VendorDashboardScreen(user: userCredential.user),
//             ),
//           );
//         }
//       } else {
//         // Validate GST number uniqueness
//         bool isGstValid = await _isGstUnique(_gstController.text.trim());
//         if (!isGstValid) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('This GST number is already registered.')),
//           );
//           setState(() {
//             _isLoading = false;
//           });
//           return;
//         }

//         // Sign-Up
//         UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//           email: email,
//           password: password,
//         );

//         // Save all vendor details in Firestore
//         await _firestore.collection('vendors').doc(userCredential.user!.uid).set({
//           'name': _nameController.text.trim(),
//           'shopName': _shopNameController.text.trim(),
//           'gstNumber': _gstController.text.trim(),
//           'location': _locationController.text.trim(),
//           'mobile': _mobileController.text.trim(),
//         });

//         // Show animated splash screen
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => AnimatedSplashScreen(
//               onDone: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => VendorAuthScreen(),
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = 'An error occurred, please try again.';
//       if (e.code == 'email-already-in-use') {
//         errorMessage = 'This mobile number is already registered.';
//       } else if (e.code == 'wrong-password') {
//         errorMessage = 'Incorrect password.';
//       } else if (e.code == 'user-not-found') {
//         errorMessage = 'No user found with this mobile number.';
//       }
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               SizedBox(height: 100),
//               Text(
//                 isLogin ? 'Vendor Login' : 'Vendor Sign-Up',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green,
//                 ),
//               ),
//               SizedBox(height: 40),
//               Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     if (!isLogin) ...[
//                       TextFormField(
//                         controller: _nameController,
//                         decoration: InputDecoration(
//                           labelText: 'Name',
//                           prefixIcon: Icon(Icons.person),
//                           border: OutlineInputBorder(),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Enter your name';
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: 20),
//                       TextFormField(
//                         controller: _shopNameController,
//                         decoration: InputDecoration(
//                           labelText: 'Shop Name',
//                           prefixIcon: Icon(Icons.store),
//                           border: OutlineInputBorder(),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Enter your shop name';
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: 20),
//                       TextFormField(
//                         controller: _gstController,
//                         decoration: InputDecoration(
//                           labelText: 'GST Number',
//                           prefixIcon: Icon(Icons.confirmation_number),
//                           border: OutlineInputBorder(),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Enter your GST number';
//                           }
//                           if (value.length != 14) {
//                             return 'GST number must be exactly 14 characters';
//                           }
//                           if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(value)) {
//                             return 'GST number must be alphanumeric';
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: 20),
//                       TextFormField(
//                         controller: _locationController,
//                         decoration: InputDecoration(
//                           labelText: 'Location',
//                           prefixIcon: Icon(Icons.location_on),
//                           border: OutlineInputBorder(),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Enter your location';
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: 20),
//                     ],
//                     TextFormField(
//                       controller: _mobileController,
//                       keyboardType: TextInputType.phone,
//                       decoration: InputDecoration(
//                         labelText: 'Mobile Number',
//                         prefixIcon: Icon(Icons.phone),
//                         border: OutlineInputBorder(),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty || value.length != 10) {
//                           return 'Enter a valid 10-digit mobile number';
//                         }
//                         if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
//                           return 'Mobile number must contain only digits';
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(height: 20),
//                     TextFormField(
//                       controller: _passwordController,
//                       obscureText: _obscurePassword,
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         prefixIcon: Icon(Icons.lock),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _obscurePassword = !_obscurePassword;
//                             });
//                           },
//                         ),
//                         border: OutlineInputBorder(),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty || value.length < 6) {
//                           return 'Password must be at least 6 characters';
//                         }
//                         if (!RegExp(r'(?=.*[!@#\$%^&*])(?=.*\d)').hasMatch(value)) {
//                           return 'Password must include a special character and a number';
//                         }
//                         return null;
//                       },
//                     ),
//                     if (!isLogin)
//                       SizedBox(height: 20),
//                     if (!isLogin)
//                       TextFormField(
//                         controller: _confirmPasswordController,
//                         obscureText: true,
//                         decoration: InputDecoration(
//                           labelText: 'Confirm Password',
//                           prefixIcon: Icon(Icons.lock_outline),
//                           border: OutlineInputBorder(),
//                         ),
//                         validator: (value) {
//                           if (value != _passwordController.text) {
//                             return 'Passwords do not match';
//                           }
//                           return null;
//                         },
//                       ),
//                     SizedBox(height: 30),
//                     _isLoading
//                         ? CircularProgressIndicator()
//                         : ElevatedButton(
//                             onPressed: _authenticate,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green,
//                               padding: EdgeInsets.symmetric(vertical: 16, horizontal: 60),
//                             ),
//                             child: Text(
//                               isLogin ? 'Login' : 'Create Account',
//                               style: TextStyle(fontSize: 18),
//                             ),
//                           ),
//                     TextButton(
//                       onPressed: toggleAuthMode,
//                       child: Text(
//                         isLogin ? 'Don’t have an account? Sign Up' : 'Already have an account? Login',
//                         style: TextStyle(color: Colors.green),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }










//=================================================NORMAL OLD LOCATION FORMATE CODE======================================================



import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grovo_app/screens/AnimatedSplashScreen.dart';
import 'vendor_dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Add this import statement


class VendorAuthScreen extends StatefulWidget {
  @override
  _VendorAuthScreenState createState() => _VendorAuthScreenState();
}

class _VendorAuthScreenState extends State<VendorAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool isLogin = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _obscurePassword = true;
  bool _isLoading = false;

  void toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  Future<bool> _isGstUnique(String gstNumber) async {
    final snapshot = await _firestore
        .collection('vendors')
        .where('gstNumber', isEqualTo: gstNumber)
        .get();
    return snapshot.docs.isEmpty;
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String email = '${_mobileController.text}@grovo.com';
    String password = _passwordController.text;

    try {
      if (isLogin) {
        // Login
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VendorDashboardScreen(user: userCredential.user!), // Pass user
            ),
          );
        }
      } else {
        // Validate GST number uniqueness
        bool isGstValid = await _isGstUnique(_gstController.text.trim());
        if (!isGstValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This GST number is already registered.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Sign-Up
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Save all vendor details in Firestore
        await _firestore.collection('vendors').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'shopName': _shopNameController.text.trim(),
          'gstNumber': _gstController.text.trim(),
          'location': _locationController.text.trim(),
          'mobile': _mobileController.text.trim(),
        });

        // Show animated splash screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AnimatedSplashScreen(
              onDone: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VendorAuthScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred, please try again.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This mobile number is already registered.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this mobile number.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100),
              Text(
                isLogin ? 'Vendor Login' : 'Vendor Sign-Up',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _shopNameController,
                        decoration: InputDecoration(
                          labelText: 'Shop Name',
                          prefixIcon: Icon(Icons.store),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your shop name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _gstController,
                        decoration: InputDecoration(
                          labelText: 'GST Number',
                          prefixIcon: Icon(Icons.confirmation_number),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your GST number';
                          }
                          if (value.length != 14) {
                            return 'GST number must be exactly 14 characters';
                          }
                          if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(value)) {
                            return 'GST number must be alphanumeric';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your location';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                    ],
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length != 10) {
                          return 'Enter a valid 10-digit mobile number';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Mobile number must contain only digits';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        if (!RegExp(r'(?=.*[!@#\$%^&*])(?=.*\d)').hasMatch(value)) {
                          return 'Password must include a special character and a number';
                        }
                        return null;
                      },
                    ),
                    if (!isLogin)
                      SizedBox(height: 20),
                    if (!isLogin)
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    SizedBox(height: 30),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _authenticate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 60),
                            ),
                            child: Text(
                              isLogin ? 'Login' : 'Create Account',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                    TextButton(
                      onPressed: toggleAuthMode,
                      child: Text(
                        isLogin ? 'Don’t have an account? Sign Up' : 'Already have an account? Login',
                        style: TextStyle(color: Colors.green),
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
}








//===========================================================================================================


















// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:grovo_app/screens/AnimatedSplashScreen.dart';
// import 'package:grovo_app/screens/vendor_dashboard_screen.dart';
// import 'package:grovo_app/services/location_service.dart';

// class VendorAuthScreen extends StatefulWidget {
//   @override
//   _VendorAuthScreenState createState() => _VendorAuthScreenState();
// }

// class _VendorAuthScreenState extends State<VendorAuthScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _shopNameController = TextEditingController();
//   final TextEditingController _gstController = TextEditingController();
//   final TextEditingController _mobileController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();
//   bool isLogin = true;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool _obscurePassword = true;
//   bool _isLoading = false;

//   // For location dropdowns
//   final LocationService _locationService = LocationService();
//   String? selectedCountry;
//   String? selectedState;
//   String? selectedDistrict;

//   List<String> countries = [];
//   List<String> states = [];
//   List<String> districts = [];

//   bool isLoadingCountries = false;
//   bool isLoadingStates = false;
//   bool isLoadingDistricts = false;

//   void toggleAuthMode() {
//     setState(() {
//       isLogin = !isLogin;
//     });
//   }

//   Future<bool> _isGstUnique(String gstNumber) async {
//     final snapshot = await _firestore
//         .collection('vendors')
//         .where('gstNumber', isEqualTo: gstNumber)
//         .get();
//     return snapshot.docs.isEmpty;
//   }

//   Future<void> _authenticate() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _isLoading = true;
//     });

//     String email = '${_mobileController.text}@grovo.com';
//     String password = _passwordController.text;

//     try {
//       if (isLogin) {
//         // Login
//         UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//           email: email,
//           password: password,
//         );

//         if (userCredential.user != null) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => VendorDashboardScreen(user: userCredential.user),
//             ),
//           );
//         }
//       } else {
//         // Validate GST number uniqueness
//         bool isGstValid = await _isGstUnique(_gstController.text.trim());
//         if (!isGstValid) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('This GST number is already registered.')),
//           );
//           setState(() {
//             _isLoading = false;
//           });
//           return;
//         }

//         // Sign-Up
//         UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//           email: email,
//           password: password,
//         );

//         // Save all vendor details in Firestore
//         await _firestore.collection('vendors').doc(userCredential.user!.uid).set({
//           'name': _nameController.text.trim(),
//           'shopName': _shopNameController.text.trim(),
//           'gstNumber': _gstController.text.trim(),
//           'location': {
//             'country': selectedCountry,
//             'state': selectedState,
//             'district': selectedDistrict,
//           },
//           'mobile': _mobileController.text.trim(),
//         });

//         // Show animated splash screen
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => AnimatedSplashScreen(
//               onDone: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => VendorAuthScreen(),
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = 'An error occurred, please try again.';
//       if (e.code == 'email-already-in-use') {
//         errorMessage = 'This mobile number is already registered.';
//       } else if (e.code == 'wrong-password') {
//         errorMessage = 'Incorrect password.';
//       } else if (e.code == 'user-not-found') {
//         errorMessage = 'No user found with this mobile number.';
//       }
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadCountries();
//   }

//   // Load countries from API
//   Future<void> _loadCountries() async {
//     setState(() {
//       isLoadingCountries = true;
//     });

//     try {
//       countries = await _locationService.fetchCountries();
//     } catch (e) {
//       print('Error loading countries: $e');
//     } finally {
//       setState(() {
//         isLoadingCountries = false;
//       });
//     }
//   }

//   // Load states based on selected country
//   Future<void> _loadStates(String country) async {
//     setState(() {
//       isLoadingStates = true;
//     });

//     try {
//       states = await _locationService.fetchStates(country);
//       selectedState = null;
//       districts.clear();
//     } catch (e) {
//       print('Error loading states: $e');
//     } finally {
//       setState(() {
//         isLoadingStates = false;
//       });
//     }
//   }

//   // Load districts based on selected state
//   Future<void> _loadDistricts(String state) async {
//     setState(() {
//       isLoadingDistricts = true;
//     });

//     try {
//       districts = await _locationService.fetchDistricts(state);
//       selectedDistrict = null;
//     } catch (e) {
//       print('Error loading districts: $e');
//     } finally {
//       setState(() {
//         isLoadingDistricts = false;
//       });
//     }
//   }

//   @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     body: ListView(
//       padding: const EdgeInsets.all(16.0),
//       children: [
//         SizedBox(height: 100),
//         Text(
//           isLogin ? 'Vendor Login' : 'Vendor Sign-Up',
//           style: TextStyle(
//             fontSize: 28,
//             fontWeight: FontWeight.bold,
//             color: Colors.green,
//           ),
//         ),
//         SizedBox(height: 40),
//         Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               if (!isLogin) ...[
//                 // Name, Shop Name, GST Number, and Location Fields
//                 TextFormField(
//                   controller: _nameController,
//                   decoration: InputDecoration(
//                     labelText: 'Name',
//                     prefixIcon: Icon(Icons.person),
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Enter your name';
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(height: 20),
//                 TextFormField(
//                   controller: _shopNameController,
//                   decoration: InputDecoration(
//                     labelText: 'Shop Name',
//                     prefixIcon: Icon(Icons.store),
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Enter your shop name';
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(height: 20),
//                 TextFormField(
//                   controller: _gstController,
//                   decoration: InputDecoration(
//                     labelText: 'GST Number',
//                     prefixIcon: Icon(Icons.confirmation_number),
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Enter your GST number';
//                     }
//                     if (value.length != 14) {
//                       return 'GST number must be exactly 14 characters';
//                     }
//                     if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(value)) {
//                       return 'GST number must be alphanumeric';
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(height: 20),
//                 // Location Label with Icon
//                 TextFormField(
//                   decoration: InputDecoration(
//                     labelText: 'Location',
//                     prefixIcon: Icon(Icons.location_on),
//                     border: OutlineInputBorder(),
//                   ),
//                   readOnly: true, // This will prevent typing
//                 ),
//                 SizedBox(height: 20),
//                 // Location Dropdowns (Country, State, District)

//                 DropdownButtonFormField<String>(
//                   value: selectedCountry,
//                   hint: Text('Select Country'),
//                   onChanged: (value) {
//                     setState(() {
//                       selectedCountry = value;
//                       _loadStates(value!);
//                     });
//                   },
//                   items: isLoadingCountries
//                       ? [
//                           DropdownMenuItem(
//                             child: Center(child: CircularProgressIndicator()),
//                           ),
//                         ]
//                       : countries.map((country) {
//                           return DropdownMenuItem(
//                             value: country,
//                             child: Text(country),
//                           );
//                         }).toList(),
//                   decoration: InputDecoration(
//                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                     border: OutlineInputBorder(),
//                   ),
//                   menuMaxHeight: 400,
//                 ),

//                 SizedBox(height: 20),

//                 //state dropdown
//                 if (selectedCountry != null)
//                   DropdownButtonFormField<String>(
//                     value: selectedState,
//                     hint: Text('Select State'),
//                     onChanged: (value) {
//                       setState(() {
//                         selectedState = value;
//                         _loadDistricts(value!);
//                       });
//                     },
//                     items: isLoadingStates
//                         ? [
//                             DropdownMenuItem(
//                               child: Center(child: CircularProgressIndicator()),
//                             ),
//                           ]
//                         : states.map((state) {
//                             return DropdownMenuItem(
//                               value: state,
//                               child: Text(state),
//                             );
//                           }).toList(),
//                     decoration: InputDecoration(
//                       contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                       border: OutlineInputBorder(),
//                     ),
//                     menuMaxHeight: 200,
//                   ),

//                 SizedBox(height: 20),

//                 //district dropdown
//                 if (selectedState != null)
//                   DropdownButtonFormField<String>(
//                     value: selectedDistrict,
//                     hint: Text('Selected District'),
//                     onChanged: (value) {
//                       setState(() {
//                         selectedDistrict = value;
//                       });
//                     },
//                     items: isLoadingDistricts
//                         ? [
//                             DropdownMenuItem(
//                               child: Center(child: CircularProgressIndicator()),
//                             ),
//                           ]
//                         : districts.map((district) {
//                             return DropdownMenuItem(
//                               value: district,
//                               child: Text(district),
//                             );
//                           }).toList(),
//                     decoration: InputDecoration(
//                       contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                       border: OutlineInputBorder(),
//                     ),
//                     menuMaxHeight: 200,
//                   ),
//               ],
//               // Mobile number and Password Fields
//               SizedBox(height: 20),
//               TextFormField(
//                 controller: _mobileController,
//                 decoration: InputDecoration(
//                   labelText: 'Mobile Number',
//                   prefixIcon: Icon(Icons.phone),
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Enter your mobile number';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 20),
//               TextFormField(
//                 controller: _passwordController,
//                 obscureText: _obscurePassword,
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   prefixIcon: Icon(Icons.lock),
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _obscurePassword = !_obscurePassword;
//                       });
//                     },
//                   ),
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Enter a password';
//                   }
//                   if (value.length < 6) {
//                     return 'Password must be at least 6 characters';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 20),
//               if (!isLogin)
//                 TextFormField(
//                   controller: _confirmPasswordController,
//                   obscureText: _obscurePassword,
//                   decoration: InputDecoration(
//                     labelText: 'Confirm Password',
//                     prefixIcon: Icon(Icons.lock),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _obscurePassword = !_obscurePassword;
//                         });
//                       },
//                     ),
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Confirm your password';
//                     }
//                     if (value != _passwordController.text) {
//                       return 'Passwords do not match';
//                     }
//                     return null;
//                   },
//                 ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _authenticate,
//                 child: _isLoading
//                     ? CircularProgressIndicator()
//                     : Text(isLogin ? 'Login' : 'Create Account'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: 20),
//         TextButton(
//           onPressed: toggleAuthMode,
//           child: Text(isLogin
//               ? 'Don\'t have an account? Sign Up'
//               : 'Already have an account? Login'),
//         ),
//       ],
//     ),
//   );
// }
// }



