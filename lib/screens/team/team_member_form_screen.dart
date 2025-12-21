import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/team_member.dart';

class TeamMemberFormScreen extends StatefulWidget {
  final TeamMember? member;
  final List<TeamRole> availableRoles;

  const TeamMemberFormScreen({
    super.key,
    this.member,
    required this.availableRoles,
  });

  @override
  State<TeamMemberFormScreen> createState() => _TeamMemberFormScreenState();
}

class _TeamMemberFormScreenState extends State<TeamMemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedRole;
  bool _isActive = true;
  bool _isSaving = false;
  bool _obscurePassword = true;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _nameController.text = widget.member!.name;
      _emailController.text = widget.member!.email;
      _selectedRole = widget.member!.role;
      _isActive = widget.member!.isActive;
    } else if (widget.availableRoles.isNotEmpty) {
      _selectedRole = widget.availableRoles.first.value;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecteer een rol'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'is_active': _isActive,
      };

      // Password required for new users
      if (!_isEditing) {
        data['password'] = _passwordController.text;
      } else if (_passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }

      if (_isEditing) {
        await ApiClient.instance.put('${ApiConfig.users}/${widget.member!.id}', data: data);
      } else {
        await ApiClient.instance.post(ApiConfig.users, data: data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Teamlid bijgewerkt' : 'Teamlid toegevoegd'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        String errorMessage = 'Kon niet opslaan';
        if (e.toString().contains('email')) {
          errorMessage = 'Dit e-mailadres is al in gebruik';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Teamlid bewerken' : 'Nieuw teamlid'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naam',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vul een naam in';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mailadres',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vul een e-mailadres in';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Vul een geldig e-mailadres in';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: _isEditing ? 'Nieuw wachtwoord (optioneel)' : 'Wachtwoord',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (!_isEditing && (value == null || value.isEmpty)) {
                  return 'Vul een wachtwoord in';
                }
                if (value != null && value.isNotEmpty && value.length < 8) {
                  return 'Wachtwoord moet minimaal 8 tekens bevatten';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Role selection
            const Text(
              'Rol',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...widget.availableRoles.map((role) => _buildRoleOption(role)),
            const SizedBox(height: 24),

            // Active toggle
            SwitchListTile(
              title: const Text('Actief'),
              subtitle: const Text('Inactieve leden kunnen niet inloggen'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              secondary: Icon(
                _isActive ? Icons.check_circle : Icons.cancel,
                color: _isActive ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Over teamrollen',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Teamleden krijgen toegang tot je VerhuurAgenda op basis van hun rol. '
                    'Ze loggen in met hun eigen e-mailadres en wachtwoord.',
                    style: TextStyle(color: Colors.blue[700], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSaving ? 'Opslaan...' : 'Opslaan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption(TeamRole role) {
    final isSelected = _selectedRole == role.value;
    final color = _getRoleColor(role.color);

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role.value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String colorName) {
    switch (colorName) {
      case 'purple':
        return Colors.purple;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
