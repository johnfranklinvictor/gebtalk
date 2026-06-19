import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../providers/app_state.dart';
import '../models/chat_models.dart';

class CommandVaultWidget extends StatefulWidget {
  final Contact staff;
  final List<Contact> assignedCustomers;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onAddCustomer;
  final VoidCallback onDelete;
  final Function(Contact) onRemoveCustomer;
  final Function(Contact) onReassignCustomer;

  const CommandVaultWidget({
    Key? key,
    required this.staff,
    required this.assignedCustomers,
    required this.isExpanded,
    required this.onToggle,
    required this.onAddCustomer,
    required this.onDelete,
    required this.onRemoveCustomer,
    required this.onReassignCustomer,
  }) : super(key: key);

  @override
  State<CommandVaultWidget> createState() => _CommandVaultWidgetState();
}

class _CommandVaultWidgetState extends State<CommandVaultWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    int activeCustomers = widget.assignedCustomers.length;
    int priorityCustomers = widget.assignedCustomers.where((c) => c.tags.any((t) => t.name.toLowerCase() == 'high priority' || t.name.toLowerCase() == 'vip')).length;
    int signalsSent = widget.assignedCustomers.length * 3; // Mock gamification data

    return MouseRegion(
      onEnter: (_) { if (mounted) setState(() => _isHovered = true); },
      onExit: (_) { if (mounted) setState(() => _isHovered = false); },
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.glassBorder,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
                  ]
                : [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Vault Door)
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.headerGradient,
                    border: const Border(bottom: BorderSide(color: AppColors.glassBorder)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar / Rank
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                          image: widget.staff.avatar.isNotEmpty
                              ? DecorationImage(image: NetworkImage(widget.staff.avatar), fit: BoxFit.cover)
                              : null,
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 10)
                          ],
                        ),
                        child: widget.staff.avatar.isEmpty
                            ? const Icon(Icons.person, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${widget.staff.name.toUpperCase()} COMMAND VAULT",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Level 3 • Specialist", // Gamification mock
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        widget.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ],
                  ),
                ),
                
                // Expanded Vault Content
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: widget.isExpanded
                      ? Container(
                          color: AppColors.background,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Gamified Stats Bar
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem("Active Customers", activeCustomers.toString(), Icons.people),
                                    _buildStatItem("Signals Sent", signalsSent.toString(), Icons.cell_tower),
                                    _buildStatItem("Priority", priorityCustomers.toString(), Icons.star),
                                  ],
                                ),
                              ),
                              const Divider(color: AppColors.glassBorder, height: 1),
                              
                              // Action Buttons
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: widget.onDelete,
                                      icon: const Icon(Icons.delete, color: AppColors.secondary, size: 16),
                                      label: const Text("Delete Vault", style: TextStyle(color: AppColors.secondary)),
                                    ),
                                    if (activeCustomers == 0)
                                      const Text("Empty Vault", style: TextStyle(color: AppColors.textLight))
                                          .animate()
                                          .fade(duration: 1000.ms),
                                    const Spacer(),
                                    ElevatedButton.icon(
                                      onPressed: widget.onAddCustomer,
                                      icon: const Icon(Icons.add, color: Colors.black, size: 16),
                                      label: const Text("Assign Targets", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Customer List
                              if (widget.assignedCustomers.isNotEmpty)
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: widget.assignedCustomers.length,
                                  itemBuilder: (context, index) {
                                    final customer = widget.assignedCustomers[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.glassWhite,
                                        child: const Icon(Icons.person, color: Colors.white),
                                      ),
                                      title: Text(customer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      subtitle: Text(customer.phone, style: const TextStyle(color: AppColors.textMuted)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
                                            onPressed: () => widget.onReassignCustomer(customer),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.person_remove, color: AppColors.secondary),
                                            onPressed: () => widget.onRemoveCustomer(customer),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Center(
                                    child: Text("VAULT EMPTY", style: TextStyle(color: AppColors.textLight, letterSpacing: 4, fontWeight: FontWeight.bold)),
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
    ).animate().slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad).fadeIn();
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }
}
