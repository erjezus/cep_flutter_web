import 'package:flutter/material.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/services/settings_service.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/empty_state.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';
import 'package:cep_flutter_web/widgets/app_dialog.dart';

/// Pantalla de configuración de parámetros globales. Solo accesible para admins.
class SettingsScreen extends StatefulWidget {
  final int currentUserId;
  final String currentUserRole;

  const SettingsScreen({
    required this.currentUserId,
    required this.currentUserRole,
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsService _service;

  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;
  bool _applyDeposit = false;

  bool get _isAdmin => widget.currentUserRole.toUpperCase() == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _service = SettingsService(
      adminUserId: widget.currentUserId,
      adminUserRole: widget.currentUserRole,
    );
    if (_isAdmin) {
      _loadSettings();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.getSettings();
      if (!mounted) return;
      final raw = data['apply_deposit'];
      setState(() {
        _applyDeposit = raw == true || raw == 'true';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleApplyDeposit(bool newValue) async {
    final label = newValue ? 'activar' : 'desactivar';
    final confirmed = await AppDialog.confirm(
      context,
      title: '¿${newValue ? 'Activar' : 'Desactivar'} "A cuenta"?',
      message: '¿Seguro que quieres $label el modo "A cuenta"?',
      confirmLabel: newValue ? 'Activar' : 'Desactivar',
      icon: newValue ? Icons.check_circle_outline : Icons.cancel_outlined,
    );
    if (!confirmed) return;

    setState(() => _isUpdating = true);
    try {
      await _service.setApplyDeposit(enabled: newValue);
      if (!mounted) return;
      setState(() => _applyDeposit = newValue);
      AppSnackBar.success(
        context,
        '"A cuenta" ${newValue ? 'activado' : 'desactivado'} correctamente',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _isLoading ? null : _loadSettings,
          ),
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: 700,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'No se pudo cargar la configuración',
        message: _error,
        actionLabel: 'Reintentar',
        actionIcon: Icons.refresh,
        onAction: _loadSettings,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Pagos'),
        _SettingsTile(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColors.blue,
          title: 'A cuenta',
          subtitle: _applyDeposit
              ? 'Los consumos se cargan como deuda al saldo del usuario'
              : 'Los consumos requieren pago en el momento',
          value: _applyDeposit,
          isUpdating: _isUpdating,
          onChanged: _isUpdating ? null : _toggleApplyDeposit,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Colors.grey[500],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool isUpdating;
  final ValueChanged<bool>? onChanged;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isUpdating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        value: value,
        activeColor: AppColors.primary,
        onChanged: isUpdating ? null : onChanged,
      ),
    );
  }
}
