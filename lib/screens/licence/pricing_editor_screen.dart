import 'package:flutter/material.dart';

import '../../core/licence_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/pricing_package.dart';

class PricingEditorScreen extends StatefulWidget {
  const PricingEditorScreen({super.key});

  @override
  State<PricingEditorScreen> createState() => _PricingEditorScreenState();
}

class _PricingEditorScreenState extends State<PricingEditorScreen> {
  late List<PricingPackage> packages;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    packages = List.from(LicenceController.instance.packages);
  }

  Future<void> _save() async {
    setState(() => saving = true);
    await LicenceController.instance.savePackages(packages);
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          backgroundColor: Color(0xFF059669), content: Text('Plans saved')),
    );
  }

  Future<void> _edit(int index) async {
    final p = packages[index];
    final name = TextEditingController(text: p.name);
    final price = TextEditingController(text: p.priceLabel);
    final period = TextEditingController(text: p.period);
    final features = TextEditingController(text: p.features.join('\n'));
    var highlighted = p.highlighted;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Edit ${p.name}'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Plan name')),
                  TextField(
                      controller: price,
                      decoration: const InputDecoration(
                          labelText: 'Price label (e.g. ₦45,000)')),
                  TextField(
                      controller: period,
                      decoration: const InputDecoration(
                          labelText: 'Period (e.g. per term)')),
                  TextField(
                      controller: features,
                      maxLines: 5,
                      decoration: const InputDecoration(
                          labelText: 'Features (one per line)')),
                  SwitchListTile(
                    title: const Text('Mark as popular'),
                    value: highlighted,
                    onChanged: (v) => setLocal(() => highlighted = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Apply')),
          ],
        ),
      ),
    );

    if (ok == true) {
      setState(() {
        packages[index] = p.copyWith(
          name: name.text.trim(),
          priceLabel: price.text.trim(),
          period: period.text.trim(),
          features: features.text
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          highlighted: highlighted,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('Edit plans & prices'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? 'Saving…' : 'Save',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final p = packages[i];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.cardBorder(context)),
            ),
            tileColor: AppColors.card(context),
            title: Text('${p.name} · ${p.priceLabel}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${p.period} · ${p.features.length} features'),
            trailing: const Icon(Icons.edit_rounded),
            onTap: () => _edit(i),
          );
        },
      ),
    );
  }
}
