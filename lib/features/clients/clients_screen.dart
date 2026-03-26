import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/client.dart';

final _clientsProvider = FutureProvider<List<Client>>((ref) async {
  final data = await SupabaseConfig.client
      .from(kTableClients)
      .select()
      .eq('business_id', kDevBusinessId)
      .order('name');
  return (data as List).map((e) => Client.fromJson(e)).toList();
});

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(_clientsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Text('Clients',
                  style: Theme.of(context).textTheme.headlineLarge),
            ),
            Expanded(
              child: clientsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (clients) {
                  if (clients.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 48, color: AppColors.textTertiary),
                          SizedBox(height: 12),
                          Text('Aucun client enregistré',
                              style:
                                  TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: clients.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (ctx, i) => _ClientTile(client: clients[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final Client client;
  const _ClientTile({required this.client});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        backgroundColor: AppColors.primarySurface,
        child: Text(
          client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(client.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (client.phone != null)
            Text(client.phone!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          if (client.city != null)
            Text(client.city!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: () => context.push('/clients/${client.id}'),
    );
  }
}

