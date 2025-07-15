import 'package:flutter/material.dart';
import '../pages/share_form_page.dart';
import '../pages/apartment_form_page.dart';
import '../pages/property_details_page.dart';
import '../data/models/share_model.dart';
import '../data/models/apartment_model.dart';

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

  /// Navigate to unified details page for apartment
  static void navigateToApartmentDetails(BuildContext context, int apartmentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailsPage(
          id: apartmentId,
          itemType: "apartment",
        ),
      ),
    );
  }

  /// Navigate to unified details page for share
  static void navigateToShareDetails(BuildContext context, int shareId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailsPage(
          id: shareId,
          itemType: "share",
        ),
      ),
    );
  }

  /// Navigate to create an apartment
  static void navigateToCreateApartment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApartmentFormPage(
          mode: ApartmentFormMode.create,
        ),
      ),
    );
  }

  /// Navigate to update an existing apartment
  static void navigateToUpdateApartment(BuildContext context, Apartment apartment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApartmentFormPage(
          mode: ApartmentFormMode.update,
          existingApartment: apartment,
        ),
      ),
    );
  }

  /// Generic navigation to details page based on type
  static void navigateToDetails(BuildContext context, int id, String itemType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailsPage(
          id: id,
          itemType: itemType,
        ),
      ),
    );
  }
} 