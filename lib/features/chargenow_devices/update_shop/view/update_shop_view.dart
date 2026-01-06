import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/chargenow_devices/update_shop/provider/update_shop_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/update_shop/view_models/update_shop_state.dart';

class UpdateShopView extends ConsumerStatefulWidget {
  const UpdateShopView({super.key});

  @override
  ConsumerState<UpdateShopView> createState() => _UpdateShopViewState();
}

class _UpdateShopViewState extends ConsumerState<UpdateShopView> {
  final TextEditingController _pNewidController = TextEditingController();
  final TextEditingController _pNameController = TextEditingController();
  final TextEditingController _pAddressController = TextEditingController();
  final TextEditingController _pJingduController = TextEditingController();
  final TextEditingController _pWeiduController = TextEditingController();
  final TextEditingController _pContentController = TextEditingController();
  final TextEditingController _pCurrencyController = TextEditingController();
  final TextEditingController _pLocationIdController = TextEditingController();
  final TextEditingController _pLogoController = TextEditingController();

  int? _selectedSceneType;
  int? _selectedStoreType;
  bool _pAuditor = false;

  final Map<int, String> sceneTypeOptions = {
    0: 'Other',
    1: 'House',
    2: 'Outside the apartment',
    3: 'Outside the hospital',
    4: 'Semi independent',
    5: 'Commercial building',
    6: 'Inside the building',
    7: 'Outside the building',
    8: 'Factory area',
    9: 'In the square',
    10: 'Outside the square',
    11: 'Amusement Park',
    12: 'Lakeside',
    13: 'Independent house',
    14: 'Independent household',
    15: 'Off court',
    16: 'Outside the group house',
    17: 'Street shop',
    18: 'Street house',
    19: 'Inside the hotel',
    20: 'Outside the hotel',
    21: 'Car',
    22: 'Bar',
    23: 'Café',
    24: 'Nightclub',
    25: 'Restaurant',
    26: 'Shopping Centre',
    27: 'Convenience Store',
    28: 'Retail Store',
    29: 'Public Transport',
    30: 'Airport',
    31: 'Stadium',
    32: 'Event',
    33: 'Hospital',
    34: 'Health/Fitness',
    35: 'University',
    36: 'Library',
  };

  final Map<int, String> storeTypeOptions = {
    0: 'Other',
    1: 'Center',
    2: 'Chinese food',
    3: 'Park',
    4: 'Leisure',
    5: 'Accommodation',
    6: 'Health care',
    7: 'Fitness',
    8: 'Venues',
    9: 'Entertainment',
    10: 'Pets',
    11: 'Education',
    12: 'Service',
    13: 'Stalls',
    14: 'Hookah',
    15: 'Games',
    16: 'Baking',
    17: 'Barbecue',
    18: 'Haircut',
    19: 'Beauty',
    20: 'Clinic',
    21: 'Car workshop',
    22: 'Car shop',
    23: 'Mail',
    24: 'Bar',
    25: 'Hotel',
    26: 'Retail',
    27: 'Restaurant bar',
    28: 'Catering',
    29: 'Drinks',
  };

  @override
  void dispose() {
    _pNewidController.dispose();
    _pNameController.dispose();
    _pAddressController.dispose();
    _pJingduController.dispose();
    _pWeiduController.dispose();
    _pContentController.dispose();
    _pCurrencyController.dispose();
    _pLocationIdController.dispose();
    _pLogoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updateShopState = ref.watch(updateShopViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Update Shop')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _pNewidController,
              decoration: const InputDecoration(labelText: 'Shop ID'),
            ),
            TextField(
              controller: _pNameController,
              decoration: const InputDecoration(labelText: 'Shop Name'),
            ),
            DropdownButtonFormField<int>(
              value: _selectedSceneType,
              decoration: const InputDecoration(labelText: 'Scene Type (optional)'),
              items: sceneTypeOptions.entries
                  .map((entry) => DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSceneType = value;
                });
              },
            ),
            DropdownButtonFormField<int>(
              value: _selectedStoreType,
              decoration: const InputDecoration(labelText: 'Store Type (optional)'),
              items: storeTypeOptions.entries
                  .map((entry) => DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStoreType = value;
                });
              },
            ),
            TextField(
              controller: _pAddressController,
              decoration: const InputDecoration(labelText: 'Address (optional)'),
            ),
            TextField(
              controller: _pJingduController,
              decoration: const InputDecoration(labelText: 'Longitude'),
            ),
            TextField(
              controller: _pWeiduController,
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
            SwitchListTile(
              title: const Text('Auditor (0: Disable, 1: Enable)'),
              value: _pAuditor,
              onChanged: (value) {
                setState(() {
                  _pAuditor = value;
                });
              },
            ),
            TextField(
              controller: _pContentController,
              decoration: const InputDecoration(labelText: 'Content (optional)'),
            ),
            TextField(
              controller: _pCurrencyController,
              decoration: const InputDecoration(labelText: 'Currency (optional, ISO Code)'),
            ),
            TextField(
              controller: _pLocationIdController,
              decoration: const InputDecoration(labelText: 'Location ID (optional, for StripePOS)'),
            ),
            TextField(
              controller: _pLogoController,
              decoration: const InputDecoration(labelText: 'Logo URL (optional)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: updateShopState.status == UpdateShopStatus.loading
                  ? null
                  : () {
                      ref.read(updateShopViewModelProvider.notifier).updateShop(
                            pNewid: _pNewidController.text,
                            pName: _pNameController.text,
                            pSceneType: _selectedSceneType,
                            pStoreType: _selectedStoreType,
                            pAddress: _pAddressController.text,
                            pJingdu: _pJingduController.text,
                            pWeidu: _pWeiduController.text,
                            pAuditor: _pAuditor ? 1 : 0,
                            pContent: _pContentController.text,
                            pCurrency: _pCurrencyController.text,
                            pLocationId: _pLocationIdController.text,
                            pLogo: _pLogoController.text,
                          );
                    },
              child: updateShopState.status == UpdateShopStatus.loading
                  ? const CircularProgressIndicator()
                  : const Text('Update Shop'),
            ),
            const SizedBox(height: 16),
            if (updateShopState.status == UpdateShopStatus.success && updateShopState.updateShopResponse != null)
              Text('Success: Shop updated successfully. ${updateShopState.updateShopResponse!.data?.toString() ?? ''}'),
            if (updateShopState.status == UpdateShopStatus.error && updateShopState.errorMsg != null)
              Text('Error: ${updateShopState.errorMsg}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(updateShopViewModelProvider.notifier).resetState();
                _pNewidController.clear();
                _pNameController.clear();
                _pAddressController.clear();
                _pJingduController.clear();
                _pWeiduController.clear();
                _pContentController.clear();
                _pCurrencyController.clear();
                _pLocationIdController.clear();
                _pLogoController.clear();
                setState(() {
                  _selectedSceneType = null;
                  _selectedStoreType = null;
                  _pAuditor = false;
                });
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}