import 'package:bgmi_tournamentor/screen/notifications_screen.dart';
import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(
                "assets/images/Image+Border.png"),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Row(
              children: [
                Text(
                  "BATTLEGROUNDS",
                  style: TextStyle(
                      fontSize: 18,
                    fontFamily: "SpaceGrotesk",
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                      ),
                ),Text(
                  " PRO",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: "SpaceGrotesk",
                    color: Color(0xffF47B25),
                  ),
                ),
              ],
            ),
          ),
          const NotificationBellButton(),
        ],
      ),
    );
  }
}