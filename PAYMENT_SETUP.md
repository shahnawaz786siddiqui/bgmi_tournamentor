# Payment gateway setup (Razorpay / PhonePe / UPI)

## Razorpay checkout

When users tap **BUY** on a credit pack in the **Shop**, the app opens **Razorpay** checkout. Razorpay supports:

- **Cards** (credit/debit)
- **UPI** (Google Pay, PhonePe, Paytm, etc.)
- **Net banking**
- **Wallets**

So users can pay via PhonePe or any option Razorpay shows.

## Add your Razorpay key

1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/) and sign up/login.
2. Get your **Key ID**:  
   **Settings → API Keys** → use **Test** key for development (`rzp_test_...`) or **Live** key for production (`rzp_live_...`).
3. In this project, open **`lib/services/payment_service.dart`**.
4. Replace the placeholder:
   ```dart
   const String razorpayKeyId = 'rzp_test_XXXXXXXX'; // TODO: Add your Razorpay key
   ```
   with your actual key, e.g.:
   ```dart
   const String razorpayKeyId = 'rzp_test_AbCdEfGhIjKlMnOp';
   ```

## Amounts in rupees (₹)

- All wallet **balance** is stored and shown in **rupees (₹)**.
- Razorpay amount is sent in **paise** (₹1 = 100 paise); the app converts automatically.
- Credit pack prices: ₹80, ₹400, ₹800, ₹1600 — user pays that amount and gets the corresponding credits in their wallet (in ₹).

## Testing

- Use **Test mode** and Razorpay test cards (see [Razorpay test cards](https://razorpay.com/docs/payments/payments/test-card-details/)) or test UPI.
- After successful payment, credits are added to the user’s Firestore balance and the balance updates everywhere (Profile, Shop, Earn screen).
