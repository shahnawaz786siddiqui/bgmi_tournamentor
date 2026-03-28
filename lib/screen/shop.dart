import 'package:flutter/material.dart';

import '../services/payment_service.dart';
import '../services/tournament_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  void initState() {
    super.initState();
    TournamentService.instance.ensureUser();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF47B25);
    const darkBg = Color(0xFF121212);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Store",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // FIXED TEXT COLOR
            fontSize: 20,
          ),
        ),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: primaryColor),
        //   onPressed: () {
        //   },
        // ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: primaryColor),
            onPressed: () {},
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // ================= BALANCE CARD =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<double>(
                stream: TournamentService.instance.balanceStream(),
                builder: (context, snapshot) {
                  final balance = snapshot.data ?? 0.0;
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1E1E), Color(0xFF2A2A2A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Your Balance",
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  "₹${balance >= 1000 ? (balance / 1000).toStringAsFixed(1) + "k" : balance.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.currency_rupee, color: Colors.orange),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: primaryColor,
                            size: 28,
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),

            // ================= SECTION TITLE =================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Tournament Credits",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ================= GRID =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.78,
                children: [
                  CreditCardWidget("80 Credits", "₹80", "STARTER", 80, 80),
                  CreditCardWidget("400 Credits", "₹400", "POPULAR", 400, 400),
                  CreditCardWidget("800 Credits", "₹800", "15% OFF", 800, 800),
                  CreditCardWidget("1600 Credits", "₹1600", "BEST VALUE", 1600, 1600),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ================= ELITE PASS =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2B2B2B), Color(0xFF1A1A1A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: primaryColor.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "SEASON 12",
                        style: TextStyle(
                            color: Colors.white, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "ROYALE ELITE PASS",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text("✔ Access to all Elite Tournaments",
                        style: TextStyle(color: Colors.white60)),
                    const Text("✔ 2x Bonus Reward Multiplier",
                        style: TextStyle(color: Colors.white60)),
                    const Text("✔ Exclusive Profile Badge",
                        style: TextStyle(color: Colors.white60)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          "UPGRADE NOW - ₹499",
                          style: TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= MODERN CREDIT CARD =================

class CreditCardWidget extends StatelessWidget {
  final String title;
  final String price;
  final String badge;
  final int credits;
  /// Price in rupees (₹) for Razorpay - e.g. 80 for ₹80
  final int priceInRupees;

  const CreditCardWidget(
      this.title, this.price, this.badge, this.credits, this.priceInRupees,
      {super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF47B25);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
        border:
        Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                    color: Colors.white, fontSize: 9),
              ),
            ),
          ),
          const Spacer(),
          const Icon(Icons.currency_rupee,
              size: 40, color: primaryColor),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(price,
              style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(5),
                ),
              ),
              onPressed: () {
                PaymentService.instance.openPayment(
                  amountRupees: priceInRupees,
                  credits: credits,
                  description: '$title - $credits credits',
                  onSuccess: () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment successful! ₹$priceInRupees paid. $credits credits added to wallet.'),
                        ),
                      );
                    }
                  },
                  onFailure: () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment failed or cancelled.'),
                        ),
                      );
                    }
                  },
                );
              },
              child: const Text("BUY"),
            ),
          )
        ],
      ),
    );
  }
}