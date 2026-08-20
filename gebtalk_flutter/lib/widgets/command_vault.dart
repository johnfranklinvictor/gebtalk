import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../models/chat_models.dart';

class CommandVaultWidget extends StatefulWidget {
  final Contact staff;
  final List<Contact> assignedCustomers;
  final bool isExpanded;
  final bool canManage;
  final VoidCallback onToggle;
  final VoidCallback onAddCustomer;
  final VoidCallback onDelete;
  final Function(Contact) onRemoveCustomer;
  final Function(Contact) onReassignCustomer;

  const CommandVaultWidget({
    super.key,
    required this.staff,
    required this.assignedCustomers,
    required this.isExpanded,
    this.canManage = false,
    required this.onToggle,
    required this.onAddCustomer,
    required this.onDelete,
    required this.onRemoveCustomer,
    required this.onReassignCustomer,
  });

  @override
  State<CommandVaultWidget> createState() => _CommandVaultWidgetState();
}

class _CommandVaultWidgetState extends State<CommandVaultWidget>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int activeCustomers = widget.assignedCustomers.length;
    int priorityCustomers = widget.assignedCustomers.where((c) => c.tags.any((t) => t.name.toLowerCase() == 'high priority' || t.name.toLowerCase() == 'vip')).length;
    int signalsSent = widget.assignedCustomers.length * 3;

    return MouseRegion(
      onEnter: (_) { if (mounted) setState(() => _isHovered = true); },
      onExit: (_) { if (mounted) setState(() => _isHovered = false); },
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: widget.isExpanded ? 0.75 : 0.45),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isExpanded
                  ? AppColors.primary
                  : (_isHovered ? AppColors.primaryLight.withValues(alpha: 0.6) : AppColors.glassBorder),
              width: widget.isExpanded ? 2.0 : (_isHovered ? 1.5 : 1.0),
            ),
            boxShadow: widget.isExpanded
                ? [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 25, spreadRadius: 1),
                    BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 15, offset: const Offset(0, 8)),
                  ]
                : [
                    BoxShadow(
                      color: _isHovered ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                      blurRadius: 12,
                    ),
                    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Vault Door Panel)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isExpanded
                          ? [AppColors.primary.withValues(alpha: 0.06), AppColors.deepSpaceBlack.withValues(alpha: 0.4)]
                          : [Colors.transparent, Colors.transparent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: const Border(bottom: BorderSide(color: AppColors.glassBorder, width: 0.8)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Avatar / Hologram ID Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.isExpanded
                                        ? AppColors.primary.withValues(alpha: 0.3 + (_pulseController.value * 0.4))
                                        : AppColors.electricBlue.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: widget.isExpanded ? AppColors.primary : AppColors.electricBlue, width: 1.5),
                            ),
                            child: widget.staff.avatar.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      widget.staff.avatar,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(child: Icon(Icons.person, color: AppColors.primary));
                                      },
                                    ),
                                  )
                                : const Icon(Icons.person, color: AppColors.primary),
                          ),
                          // Tech Overlay Lines
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${widget.staff.name.toUpperCase()} SECURE VAULT",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1.5,
                                fontFamily: 'Product Sans',
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 0.5),
                                  ),
                                  child: const Text(
                                    "LEVEL 4 SPECIALIST",
                                    style: TextStyle(
                                      color: AppColors.primaryLight,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "STATUS: ACTIVE",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        widget.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: widget.isExpanded ? AppColors.primary : AppColors.textMuted,
                        size: 24,
                      ),
                    ],
                  ),
                ),
                
                // Slide Doors & Emerging Content
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  child: widget.isExpanded
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppColors.deepSpaceBlack.withValues(alpha: 0.6),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.surface.withValues(alpha: 0.0),
                                AppColors.deepSpaceBlack.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Light emergence visual effect
                              Container(
                                height: 2,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, AppColors.primary, Colors.transparent],
                                  ),
                                ),
                              ),
                              
                              // Gamified Holographic stats bar
                              Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Row(
                                  children: [
                                    Expanded(child: _buildGlassStatBox("ACTIVE CLIENTS", activeCustomers.toString(), Icons.people_outline_rounded)),
                                    const SizedBox(width: 10),
                                    Expanded(child: _buildGlassStatBox("SIGNAL LOGS", signalsSent.toString(), Icons.sensors_rounded)),
                                    const SizedBox(width: 10),
                                    Expanded(child: _buildGlassStatBox("VIP LINKS", priorityCustomers.toString(), Icons.military_tech_rounded)),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0, duration: 300.ms),
                              
                              const Divider(color: AppColors.glassBorder, height: 1),
                              
                              // Actions Header (Only for CEO & Manager)
                              if (widget.canManage)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                                  child: Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: widget.onDelete,
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.secondary, size: 16),
                                        label: const Text("ABORT VAULT", style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                      ),
                                      const Spacer(),
                                      ElevatedButton.icon(
                                        onPressed: widget.onAddCustomer,
                                        icon: const Icon(Icons.add_link_rounded, color: Colors.black, size: 16),
                                        label: const Text("ASSIGN TARGETS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              // Customer list elements inside Vault
                              if (widget.assignedCustomers.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: widget.assignedCustomers.length,
                                    itemBuilder: (context, index) {
                                      final customer = widget.assignedCustomers[index];
                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppColors.glassBorder, width: 0.5),
                                        ),
                                        child: ListTile(
                                          dense: true,
                                          leading: SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: customer.avatar.isNotEmpty
                                                ? ClipOval(
                                                    child: Image.network(
                                                      customer.avatar,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: AppColors.primary.withValues(alpha: 0.1),
                                                          child: const Icon(Icons.person, color: AppColors.primary, size: 14),
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                                    child: const Icon(Icons.person, color: AppColors.primary, size: 14),
                                                  ),
                                          ),
                                          title: Text(
                                            customer.name,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                                          ),
                                          subtitle: Text(
                                            customer.phone,
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                          ),
                                          trailing: widget.canManage
                                              ? Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 18),
                                                      tooltip: 'Reassign Customer',
                                                      onPressed: () => widget.onReassignCustomer(customer),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.person_remove_rounded, color: AppColors.secondary, size: 18),
                                                      tooltip: 'Remove from Vault',
                                                      onPressed: () => widget.onRemoveCustomer(customer),
                                                    ),
                                                  ],
                                                )
                                              : null,
                                        ),
                                      ).animate().fadeIn(delay: (150 + index * 40).ms).slideX(begin: -0.05, end: 0, duration: 250.ms);
                                    },
                                  ),
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40.0),
                                  child: Center(
                                    child: Text(
                                      "VAULT EMPTY • STANDBY",
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                        letterSpacing: 3,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 0.05, end: 0, duration: 350.ms, curve: Curves.easeOutCubic).fadeIn();
  }

  Widget _buildGlassStatBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
