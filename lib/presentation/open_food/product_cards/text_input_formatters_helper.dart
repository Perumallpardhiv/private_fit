// ignore_for_file: parameter_assignments, prefer_asserts_with_message, lines_longer_than_80_chars

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:private_fit/presentation/open_food/product_cards/strings_helper.dart';

/// Custom formatter for text field, where only one decimal separator is allowed
/// This separator is based on [NumberFormat], so it can be "." or "," depending
/// on the user's language.
///
/// Only languages with a space character (eg: French) as a group separator will
/// have access to all features.
///
/// Also, if a separator is already displayed, it will be move to the new
/// position
class DecimalSeparatorRewriter extends TextInputFormatter {
  DecimalSeparatorRewriter(NumberFormat format)
      : _decimalSeparator = format.symbols.DECIMAL_SEP,
        _separatorToReplace = _findSeparatorToReplace(format);

  final String _decimalSeparator;
  final String? _separatorToReplace;

  static String? _findSeparatorToReplace(NumberFormat format) {
    if (!format.symbols.GROUP_SEP.isASpaceCharacter) {
      return null;
    }

    switch (format.symbols.DECIMAL_SEP) {
      case '.':
        return ',';
      default:
        return '.';
    }
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newTextValue = newValue.text;

    // Replace all invalid separators
    newTextValue = replaceSeparator(newTextValue);

    // If there is more than one separator, move to the new one
    final separatorResult = moveSeparator(
      oldValue.text,
      newTextValue,
      newValue.selection,
    );

    final newTextLength = separatorResult.newText.length;

    return newValue.copyWith(
      text: separatorResult.newText,
      selection: newValue.selection.copyWith(
        baseOffset: math.min(separatorResult.newBasePosition, newTextLength),
        extentOffset:
            math.min(separatorResult.newExtentPosition, newTextLength),
      ),
    );
  }

  MoveSeparatorResult moveSeparator(
    String oldText,
    String newText,
    TextSelection newValueTextSelection,
  ) {
    final initialSeparatorPosition = oldText.indexOf(_decimalSeparator);
    var separatorPositions = newText.indexesOf(_decimalSeparator);

    var oldBaseSelectionPosition = newValueTextSelection.baseOffset;
    var oldExtentSelectionPosition = newValueTextSelection.extentOffset;

    // If there is more than one separator, only keep the first one
    if (separatorPositions.length > 2) {
      newText = newText.replaceAllIgnoreFirst(_decimalSeparator, '');
      separatorPositions = newText.indexesOf(_decimalSeparator);
    }

    if (separatorPositions.length == 2) {
      // Move to the new separator
      if (separatorPositions[0] == initialSeparatorPosition) {
        newText = newText.removeCharacterAt(initialSeparatorPosition);

        // Move the cursor to the new position
        if (oldBaseSelectionPosition == oldExtentSelectionPosition &&
            separatorPositions[1] == (oldExtentSelectionPosition - 1)) {
          oldBaseSelectionPosition--;
          oldExtentSelectionPosition--;
        }
      } else {
        newText = newText.removeCharacterAt(separatorPositions[1]);
      }
    }

    return MoveSeparatorResult(
      newText: newText,
      newBasePosition: oldBaseSelectionPosition,
      newExtentPosition: oldExtentSelectionPosition,
    );
  }

  /// Replaces a "." by a "," or a "," by a "." only if
  /// the group separator is an empty character
  String replaceSeparator(String newTextValue) {
    if (_separatorToReplace != null &&
        newTextValue.contains(_separatorToReplace!)) {
      return newTextValue.replaceAll(
        _separatorToReplace!,
        _decimalSeparator,
      );
    } else {
      return newTextValue;
    }
  }
}

@immutable
class MoveSeparatorResult {
  const MoveSeparatorResult({
    required this.newText,
    required this.newBasePosition,
    required this.newExtentPosition,
  })  : assert(newBasePosition >= 0),
        assert(newExtentPosition >= 0);

  final String newText;
  final int newBasePosition;
  final int newExtentPosition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveSeparatorResult &&
          runtimeType == other.runtimeType &&
          newText == other.newText &&
          newBasePosition == other.newBasePosition &&
          newExtentPosition == other.newExtentPosition;

  @override
  int get hashCode =>
      newText.hashCode ^ newBasePosition.hashCode ^ newExtentPosition.hashCode;

  @override
  String toString() {
    return 'MoveSeparatorResult{newText: $newText, newBasePosition: $newBasePosition, newExtentPosition: $newExtentPosition}';
  }
}
