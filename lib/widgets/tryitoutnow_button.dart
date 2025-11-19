import 'package:flutter/material.dart';

class TryItOutNowButton extends StatelessWidget {
  const TryItOutNowButton({super.key});

  void _onPressed(BuildContext context) {
    Navigator.pushNamed(context, '/demo');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: () => _onPressed(context),
        child: const Text('Try It Out Now', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
