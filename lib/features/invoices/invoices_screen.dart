import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for Factures et Devis
    final documents = [
      _Doc(id: '#INV-1024', client: 'Jean Tremblay', amount: '850.00 \$', type: 'Facture', status: 'Payée', date: '21 Oct'),
      _Doc(id: '#QUO-991', client: 'Marie Dubois', amount: '1,200.00 \$', type: 'Devis', status: 'En attente', date: '19 Oct'),
      _Doc(id: '#INV-1023', client: 'Restaurant Le Central', amount: '4,500.00 \$', type: 'Facture', status: 'En retard', date: '10 Oct'),
      _Doc(id: '#QUO-990', client: 'Lucie Martin', amount: '350.00 \$', type: 'Devis', status: 'Approuvé', date: '05 Oct'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Factures & Devis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: documents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final doc = documents[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _iconBg(doc.type),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_icon(doc.type), color: _iconColor(doc.type), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.client,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${doc.type} ${doc.id} • ${doc.date}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      doc.amount,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusBadge(status: doc.status),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _iconBg(String type) => type == 'Facture' ? AppColors.successSurface : AppColors.primarySurface;
  Color _iconColor(String type) => type == 'Facture' ? AppColors.success : AppColors.primary;
  IconData _icon(String type) => type == 'Facture' ? Icons.receipt_long : Icons.request_quote_outlined;
}

class _Doc {
  final String id;
  final String client;
  final String amount;
  final String type;
  final String status;
  final String date;

  _Doc({required this.id, required this.client, required this.amount, required this.type, required this.status, required this.date});
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.surfaceElevated;
    Color fg = AppColors.textSecondary;

    if (status == 'Payée' || status == 'Approuvé') {
      bg = AppColors.successSurface;
      fg = AppColors.success;
    } else if (status == 'En retard') {
      bg = AppColors.dangerSurface;
      fg = AppColors.danger;
    } else if (status == 'En attente') {
      bg = AppColors.warningSurface;
      fg = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
