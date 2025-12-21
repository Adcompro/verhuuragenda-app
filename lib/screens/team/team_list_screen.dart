import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../models/team_member.dart';
import 'team_member_form_screen.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  List<TeamMember> _members = [];
  List<TeamRole> _availableRoles = [];
  bool _isLoading = true;
  String? _error;
  bool _upgradeRequired = false;

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _upgradeRequired = false;
    });

    try {
      final response = await ApiClient.instance.get(ApiConfig.users);
      final List<dynamic> data = response.data['data'] ?? [];
      final List<dynamic> roles = response.data['available_roles'] ?? [];

      setState(() {
        _members = data.map((json) => TeamMember.fromJson(json)).toList();
        _availableRoles = roles.map((json) => TeamRole.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (e.toString().contains('403') || e.toString().contains('upgrade_required')) {
        setState(() {
          _upgradeRequired = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Kon teamleden niet laden: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToForm(TeamMember? member) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TeamMemberFormScreen(
          member: member,
          availableRoles: _availableRoles,
        ),
      ),
    );
    if (result == true) {
      _loadTeamMembers();
    }
  }

  Future<void> _deleteMember(TeamMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Teamlid verwijderen'),
        content: Text('Weet je zeker dat je "${member.name}" wilt verwijderen uit je team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiClient.instance.delete('${ApiConfig.users}/${member.id}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teamlid verwijderd'), backgroundColor: Colors.green),
          );
        }
        _loadTeamMembers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kon niet verwijderen: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team'),
      ),
      body: _buildBody(),
      floatingActionButton: !_upgradeRequired && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToForm(null),
              icon: const Icon(Icons.person_add),
              label: const Text('Nieuw lid'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_upgradeRequired) {
      return _buildUpgradePrompt();
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTeamMembers,
                icon: const Icon(Icons.refresh),
                label: const Text('Opnieuw proberen'),
              ),
            ],
          ),
        ),
      );
    }

    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nog geen teamleden',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Voeg teamleden toe om samen te werken',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeamMembers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          return _TeamMemberCard(
            member: member,
            onTap: member.isOwner ? null : () => _navigateToForm(member),
            onDelete: member.isOwner ? null : () => _deleteMember(member),
          );
        },
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Premium functie',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Teambeheer is alleen beschikbaar met een Premium abonnement. '
              'Upgrade om teamleden toe te voegen en samen te werken.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to subscription screen
                  Navigator.pushNamed(context, '/subscription');
                },
                icon: const Icon(Icons.star),
                label: const Text('Bekijk Premium'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final TeamMember member;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _TeamMemberCard({
    required this.member,
    this.onTap,
    this.onDelete,
  });

  Color get _roleColor {
    if (member.isOwner) return Colors.purple;
    switch (member.role) {
      case 'manager':
        return Colors.blue;
      case 'medewerker':
        return Colors.green;
      case 'schoonmaker':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _roleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            member.roleLabel ?? member.role,
                            style: TextStyle(
                              fontSize: 12,
                              color: _roleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.email,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (member.status != null && member.status != 'active') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            member.status == 'pending' ? Icons.hourglass_empty : Icons.block,
                            size: 14,
                            color: member.status == 'pending' ? Colors.orange : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            member.statusLabel ?? member.status!,
                            style: TextStyle(
                              fontSize: 12,
                              color: member.status == 'pending' ? Colors.orange : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Delete button (not for owner)
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
