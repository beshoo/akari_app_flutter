import 'package:flutter/material.dart';
import '../pages/share_form_page.dart';
import '../data/models/share_model.dart';

class NavigationHelper {
  /// Navigate to create a new share
  static void navigateToCreateShare(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ShareFormPage(
          mode: ShareFormMode.create,
        ),
      ),
    );
  }

  /// Navigate to update an existing share
  static void navigateToUpdateShare(BuildContext context, Share share) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareFormPage(
          mode: ShareFormMode.update,
          existingShare: share,
        ),
      ),
    );
  }

  /// Navigate to create a share with specific transaction type
  static void navigateToCreateShareWithType(BuildContext context, String transactionType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareFormPage(
          mode: ShareFormMode.create,
          // You can extend the ShareFormPage to accept initial transaction type
        ),
      ),
    );
  }
} 