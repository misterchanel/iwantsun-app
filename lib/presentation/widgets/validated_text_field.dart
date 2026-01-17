import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iwantsun/core/theme/app_colors.dart';

/// État de validation d'un champ
enum ValidationState {
  initial, // Pas encore validé
  validating, // En cours de validation
  valid, // Valide
  invalid, // Invalide
}

/// Résultat de validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? helpText;

  const ValidationResult.valid({this.helpText})
      : isValid = true,
        errorMessage = null;

  const ValidationResult.invalid(this.errorMessage, {this.helpText})
      : isValid = false;

  const ValidationResult.initial()
      : isValid = true,
        errorMessage = null,
        helpText = null;
}

/// Type de fonction de validation
typedef Validator = FutureOr<ValidationResult> Function(String value);

/// Champ de texte avec validation en temps réel
class ValidatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helpText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final Validator? validator;
  final Duration validationDelay;
  final bool validateOnChange;
  final bool validateOnBlur;
  final bool showValidationIcon;
  final List<String>? autocompleteOptions;
  final Function(String)? onAutocompleteSelected;

  const ValidatedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helpText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.validator,
    this.validationDelay = const Duration(milliseconds: 500),
    this.validateOnChange = true,
    this.validateOnBlur = true,
    this.showValidationIcon = true,
    this.autocompleteOptions,
    this.onAutocompleteSelected,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField>
    with SingleTickerProviderStateMixin {
  ValidationState _validationState = ValidationState.initial;
  String? _errorMessage;
  String? _currentHelpText;
  Timer? _debounceTimer;
  final FocusNode _focusNode = FocusNode();
  bool _hasBeenFocused = false;

  late AnimationController _iconAnimationController;
  late Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();

    _currentHelpText = widget.helpText;

    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    if (widget.validateOnChange) {
      widget.controller.addListener(_onTextChanged);
    }

    if (widget.validateOnBlur) {
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!widget.validateOnChange) return;
    if (!_hasBeenFocused) return;

    // Annuler le timer précédent
    _debounceTimer?.cancel();

    // Réinitialiser l'état si le champ est vide
    if (widget.controller.text.isEmpty) {
      setState(() {
        _validationState = ValidationState.initial;
        _errorMessage = null;
        _currentHelpText = widget.helpText;
      });
      return;
    }

    // Attendre avant de valider (debounce)
    _debounceTimer = Timer(widget.validationDelay, () {
      _validate();
    });

    // Afficher l'état de validation en cours
    if (_validationState != ValidationState.validating) {
      setState(() {
        _validationState = ValidationState.validating;
      });
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _hasBeenFocused = true;
    } else {
      // Valider au blur si activé
      if (widget.validateOnBlur && widget.controller.text.isNotEmpty) {
        _validate();
      }
    }
  }

  Future<void> _validate() async {
    if (widget.validator == null) return;

    final value = widget.controller.text;
    if (value.isEmpty) {
      setState(() {
        _validationState = ValidationState.initial;
        _errorMessage = null;
        _currentHelpText = widget.helpText;
      });
      return;
    }

    setState(() {
      _validationState = ValidationState.validating;
    });

    try {
      final result = await widget.validator!(value);

      if (mounted) {
        setState(() {
          if (result.isValid) {
            _validationState = ValidationState.valid;
            _errorMessage = null;
            _currentHelpText = result.helpText ?? widget.helpText;
            _iconAnimationController.forward(from: 0.0);
          } else {
            _validationState = ValidationState.invalid;
            _errorMessage = result.errorMessage;
            _currentHelpText = result.helpText ?? widget.helpText;
            _iconAnimationController.forward(from: 0.0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationState = ValidationState.invalid;
          _errorMessage = 'Erreur de validation';
          _currentHelpText = widget.helpText;
        });
      }
    }
  }

  Color _getBorderColor() {
    switch (_validationState) {
      case ValidationState.initial:
      case ValidationState.validating:
        return AppColors.mediumGray.withOpacity(0.3);
      case ValidationState.valid:
        return AppColors.successGreen;
      case ValidationState.invalid:
        return AppColors.errorRed;
    }
  }

  Widget? _buildValidationIcon() {
    if (!widget.showValidationIcon) return null;

    IconData? icon;
    Color? color;

    switch (_validationState) {
      case ValidationState.validating:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
          ),
        );
      case ValidationState.valid:
        icon = Icons.check_circle;
        color = AppColors.successGreen;
        break;
      case ValidationState.invalid:
        icon = Icons.error;
        color = AppColors.errorRed;
        break;
      default:
        return null;
    }

    return ScaleTransition(
      scale: _iconScaleAnimation,
      child: Icon(icon, color: color, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ de texte avec autocomplete si activé
        if (widget.autocompleteOptions != null)
          _buildAutocompleteField()
        else
          _buildStandardField(),

        // Message d'aide ou d'erreur
        if (_errorMessage != null || _currentHelpText != null) ...[
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _errorMessage != null
                ? _buildErrorMessage()
                : _buildHelpMessage(),
          ),
        ],
      ],
    );
  }

  Widget _buildStandardField() {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: AppColors.primaryOrange)
            : null,
        suffixIcon: widget.suffixIcon != null
            ? IconButton(
                icon: Icon(widget.suffixIcon),
                onPressed: widget.onSuffixIconTap,
                color: AppColors.primaryOrange,
              )
            : _buildValidationIcon(),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _getBorderColor(), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _getBorderColor(), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _getBorderColor(), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        counterText: '', // Cacher le compteur par défaut
      ),
    );
  }

  Widget _buildAutocompleteField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return widget.autocompleteOptions!.where((option) {
          return option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        widget.controller.text = selection;
        widget.onAutocompleteSelected?.call(selection);
        _validate();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Synchroniser avec notre controller
        controller.text = widget.controller.text;
        controller.addListener(() {
          widget.controller.text = controller.text;
        });

        return TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: AppColors.primaryOrange)
                : null,
            suffixIcon: _buildValidationIcon(),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _getBorderColor(), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _getBorderColor(), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _getBorderColor(), width: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline,
          color: AppColors.errorRed,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _errorMessage!,
            style: const TextStyle(
              color: AppColors.errorRed,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpMessage() {
    if (_currentHelpText == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          color: AppColors.mediumGray,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _currentHelpText!,
            style: TextStyle(
              color: AppColors.darkGray.withOpacity(0.7),
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Validateurs prédéfinis
class Validators {
  /// Valide qu'un champ n'est pas vide
  static ValidationResult required(String value) {
    if (value.trim().isEmpty) {
      return const ValidationResult.invalid('Ce champ est requis');
    }
    return const ValidationResult.valid();
  }

  /// Valide un email
  static ValidationResult email(String value) {
    if (value.trim().isEmpty) {
      return const ValidationResult.invalid('L\'email est requis');
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return const ValidationResult.invalid(
        'Entrez une adresse email valide',
        helpText: 'Format: exemple@domaine.com',
      );
    }

    return const ValidationResult.valid(
      helpText: 'Format d\'email valide',
    );
  }

  /// Valide un nom de localisation
  static ValidationResult location(String value) {
    if (value.trim().isEmpty) {
      return const ValidationResult.invalid('La localisation est requise');
    }

    if (value.trim().length < 2) {
      return const ValidationResult.invalid(
        'Entrez au moins 2 caractères',
        helpText: 'Exemples: Paris, Lyon, New York',
      );
    }

    return const ValidationResult.valid(
      helpText: 'Appuyez sur Entrée pour rechercher',
    );
  }

  /// Valide un nombre dans une plage
  static Validator numberInRange(double min, double max, {String? unit}) {
    return (String value) {
      if (value.trim().isEmpty) {
        return const ValidationResult.invalid('Ce champ est requis');
      }

      final number = double.tryParse(value);
      if (number == null) {
        return const ValidationResult.invalid('Entrez un nombre valide');
      }

      if (number < min || number > max) {
        return ValidationResult.invalid(
          'La valeur doit être entre $min et $max${unit != null ? " $unit" : ""}',
        );
      }

      return ValidationResult.valid(
        helpText: 'Entre $min et $max${unit != null ? " $unit" : ""}',
      );
    };
  }

  /// Combine plusieurs validateurs
  static Validator combine(List<Validator> validators) {
    return (String value) async {
      for (final validator in validators) {
        final result = await validator(value);
        if (!result.isValid) {
          return result;
        }
      }
      return const ValidationResult.valid();
    };
  }
}
