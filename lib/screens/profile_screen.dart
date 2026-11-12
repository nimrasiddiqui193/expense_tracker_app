import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUpdatingProfile = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  String get _displayName {
    final name = _user?.displayName?.trim();
    return name != null && name.isNotEmpty ? name : 'User';
  }

  String get _email => _user?.email ?? 'No email available';

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const EditProfileScreen()));

    if (updated == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Log out?'),
            content: const Text(
              'Are you sure you want to log out of your account?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Log out'),
              ),
            ],
          ),
    );

    if (shouldLogout != true || !context.mounted) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to log out. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _sectionTitle(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _accountInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeMode mode,
    required ThemeMode selectedMode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final selected = selectedMode == mode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:
            selected
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color:
              selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.55)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: RadioListTile<ThemeMode>(
        value: mode,
        groupValue: selectedMode,
        onChanged: (value) {
          if (value != null) {
            ThemeController.setMode(value);
          }
        },
        secondary: Icon(
          icon,
          color:
              selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        activeColor: theme.colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _displayName;
    final email = _email;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 43,
                    backgroundColor: Colors.white.withValues(alpha: 0.17),
                    child: Text(
                      initial,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isUpdatingProfile ? null : _openEditProfile,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit Profile'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          _sectionTitle(
            context,
            title: 'Account Information',
            subtitle: 'Your registered account details',
          ),
          const SizedBox(height: 14),

          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _accountInfoTile(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  title: 'Full Name',
                  value: name,
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
                _accountInfoTile(
                  context: context,
                  icon: Icons.email_outlined,
                  title: 'Email Address',
                  value: email,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          _sectionTitle(
            context,
            title: 'Appearance',
            subtitle: 'Choose how Expense Tracker looks on your device.',
          ),
          const SizedBox(height: 15),

          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.mode,
            builder: (context, selectedMode, child) {
              return Column(
                children: [
                  _buildThemeOption(
                    context: context,
                    mode: ThemeMode.system,
                    selectedMode: selectedMode,
                    icon: Icons.settings_suggest_rounded,
                    title: 'System default',
                    subtitle: 'Follow your device settings',
                  ),
                  _buildThemeOption(
                    context: context,
                    mode: ThemeMode.light,
                    selectedMode: selectedMode,
                    icon: Icons.light_mode_rounded,
                    title: 'Light mode',
                    subtitle: 'A clean, bright appearance',
                  ),
                  _buildThemeOption(
                    context: context,
                    mode: ThemeMode.dark,
                    selectedMode: selectedMode,
                    icon: Icons.dark_mode_rounded,
                    title: 'Dark mode',
                    subtitle: 'Comfortable in low light',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.45),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EDIT PROFILE SCREEN
// -----------------------------------------------------------------------------

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isSaving = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    final parts = (_user?.displayName ?? '').trim().split(RegExp(r'\s+'));

    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      _firstNameController.text = parts.first;
    }

    if (parts.length > 1) {
      _lastNameController.text = parts.skip(1).join(' ');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  String get _previewName {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();

    return '$first $last'.trim();
  }

  String get _previewInitials {
    final parts =
        _previewName.split(' ').where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.35,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final user = _user;

    if (user == null) {
      _showMessage('Please sign in again to update your profile.');
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = '$firstName $lastName'.trim();

    if (fullName == (user.displayName ?? '').trim()) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await user.updateDisplayName(fullName);
      await user.reload();

      if (!mounted) return;

      Navigator.pop(context, true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      _showMessage(error.message ?? 'Could not update your profile.');
    } catch (_) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      _showMessage('Something went wrong. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildSectionHeading({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = _user?.email ?? 'No email available';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), centerTitle: false),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.22,
                            ),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _previewInitials,
                          key: ValueKey(_previewInitials),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Personal Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Update your details below.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _buildSectionHeading(
                context: context,
                title: 'Basic Details',
                subtitle: 'Keep your personal information up to date.',
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: _firstNameController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.name,
                maxLength: 30,
                decoration: _inputDecoration(
                  label: 'First Name',
                  hint: 'Enter your first name',
                  icon: Icons.person_outline_rounded,
                ).copyWith(counterText: ''),
                validator: (value) {
                  final name = value?.trim() ?? '';

                  if (name.isEmpty) {
                    return 'Please enter your first name.';
                  }

                  if (name.length < 2) {
                    return 'First name must have at least 2 characters.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: _lastNameController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.name,
                maxLength: 30,
                decoration: _inputDecoration(
                  label: 'Last Name',
                  hint: 'Enter your last name',
                  icon: Icons.badge_outlined,
                ).copyWith(counterText: ''),
                validator: (value) {
                  final name = value?.trim() ?? '';

                  if (name.isNotEmpty && name.length < 2) {
                    return 'Last name must have at least 2 characters.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 28),

              _buildSectionHeading(
                context: context,
                title: 'Login Information',
                subtitle: 'Your registered email address.',
              ),

              const SizedBox(height: 18),

              TextFormField(
                initialValue: email,
                readOnly: true,
                decoration: _inputDecoration(
                  label: 'Email Address',
                  hint: 'Your registered email',
                  icon: Icons.email_outlined,
                ).copyWith(suffixIcon: const Icon(Icons.lock_outline_rounded)),
              ),

              const SizedBox(height: 10),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 17,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your email address is linked to your login account '
                      'and cannot be changed from this form.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 34),

              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _isSaving
                          ? const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          )
                          : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded),
                              SizedBox(width: 9),
                              Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
