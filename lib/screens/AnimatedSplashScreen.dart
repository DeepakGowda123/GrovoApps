// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart'; // Add this package for animations

// class AnimatedSplashScreen extends StatelessWidget {
//   final VoidCallback onDone;

//   const AnimatedSplashScreen({required this.onDone, Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Add a Lottie animation
//             Lottie.asset(
//               'assets/congrats_animation.json', // Add a Lottie animation file here
//               width: 200,
//               height: 200,
//               repeat: false,
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Account Created Successfully!',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }






//==================================================================================================================



import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Add this package for animations

class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback onDone;

  const AnimatedSplashScreen({required this.onDone, Key? key}) : super(key: key);

  @override
  _AnimatedSplashScreenState createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Trigger the onDone callback after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add a Lottie animation
            Lottie.asset(
              'assets/congrats_animation.json', // Add a Lottie animation file here
              width: 200,
              height: 200,
              repeat: false,
            ),
            SizedBox(height: 20),
            Text(
              'Account Created Successfully!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
