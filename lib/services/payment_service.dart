import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'tournament_service.dart';

/// Replace with your Razorpay Key ID from https://dashboard.razorpay.com/app/keys
/// Use test key (rzp_test_...) for testing, live key (rzp_live_...) for production.
const String razorpayKeyId = 'rzp_test_XXXXXXXX'; // TODO: Add your Razorpay key

class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  Razorpay? _razorpay;
  int? _creditsToAdd;
  void Function()? _onSuccessCallback;
  void Function()? _onFailure;

  void _initRazorpay() {
    if (_razorpay != null) return;
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final credits = _creditsToAdd;
    final onSuccess = _onSuccessCallback;
    _creditsToAdd = null;
    _onSuccessCallback = null;
    _onFailure = null;
    if (credits != null && credits > 0) {
      await TournamentService.instance.addBalance(credits.toDouble());
      onSuccess?.call();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _creditsToAdd = null;
    _onSuccessCallback = null;
    _onFailure?.call();
    _onFailure = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // User chose external wallet (e.g. Paytm, PhonePe) - Razorpay handles it
    // Success will come via EVENT_PAYMENT_SUCCESS when done
  }

  /// Opens Razorpay checkout. [amountRupees] is in ₹ (e.g. 80 for ₹80).
  /// [credits] are added to wallet on payment success.
  void openPayment({
    required int amountRupees,
    required int credits,
    required String description,
    void Function()? onSuccess,
    void Function()? onFailure,
  }) {
    _initRazorpay();
    _creditsToAdd = credits;
    _onSuccessCallback = onSuccess;
    _onFailure = onFailure;

    final amountPaise = amountRupees * 100; // Razorpay expects paise

    final options = {
      'key': razorpayKeyId,
      'amount': amountPaise,
      'currency': 'INR',
      'name': 'BGMI Tournamentor',
      'description': description,
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      _creditsToAdd = null;
      _onSuccessCallback = null;
      _onFailure = null;
      onFailure?.call();
    }
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _creditsToAdd = null;
    _onSuccessCallback = null;
    _onFailure = null;
  }
}
