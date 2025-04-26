// go_button.dart (or wherever you keep buildGoButton)
import 'package:flutter/material.dart';
import '../api/api_service.dart'; // adjust path if needed

Widget buildGoButton({
  required BuildContext context,
  required String startingPoint,
  required String destination,
}) {
  return ElevatedButton(
    onPressed: () async {
      // 1) Determine the current time‐bucket
      final hour = DateTime.now().hour;
      final timeOfDay = hour < 9
          ? "From 6 AM To 9 AM"
          : hour < 12
          ? "From 9 AM To 12 PM"
          : hour < 15
          ? "From 12 PM To 3 PM"
          : hour < 18
          ? "From 3 PM To 6 PM"
          : "From 6 PM To 9 PM";

      // 2) Check if it’s Friday or Saturday (weekend)
      final now = DateTime.now();
      final isWeekend = (now.weekday == DateTime.friday ||
          now.weekday == DateTime.saturday)
          ? "yes"
          : "no";

      // 3) Hard‐coded age & gender for now:
      final age = 23;
      final gender = "female";

      // 4) Call the API
      final result = await ApiService.fetchWaitingTime(
        age: age,
        gender: gender,
        from: startingPoint,
        to: destination,
        time: timeOfDay,
        isRainy: "no",
        isWeekend: isWeekend,
      );

      // 5) Show result or error
      if (result != null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Estimated Waiting Time"),
              content: Text(result),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to get waiting time prediction")),
        );
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF175579),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
    ),
    child: const Text("GO", style: TextStyle(fontSize: 16, color: Colors.white)),
  );
}
