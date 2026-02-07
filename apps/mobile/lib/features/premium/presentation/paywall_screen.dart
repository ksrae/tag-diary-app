import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:mobile/features/premium/application/purchase_provider.dart';
import 'package:mobile/features/premium/data/purchase_repository.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final purchaseRepo = ref.watch(purchaseRepositoryProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('프리미엄 업그레이드'),
      ),
      body: FutureBuilder<Offerings?>(
        future: purchaseRepo.getOfferings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError || snapshot.data == null || snapshot.data!.current == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text('상품 정보를 불러올 수 없습니다.'),
                   const SizedBox(height: 16),
                   FilledButton(
                     onPressed: () => setState(() {}), 
                     child: const Text('다시 시도')
                   ),
                ],
              ),
            );
          }

          final offering = snapshot.data!.current!;
          final packages = offering.availablePackages;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text(
                    'Pro 버전으로 업그레이드하세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AI 일기 생성, 무제한 사진 첨부, 1년 전 추억 알림 등\n모든 프리미엄 기능을 이용할 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  
                  if (_isLoading)
                     const Center(child: Padding(
                       padding: EdgeInsets.all(20.0),
                       child: CircularProgressIndicator(),
                     ))
                  else
                    ...packages.map((package) => _buildPackageCard(context, package)),

                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _isLoading ? null : _restorePurchases,
                    child: const Text('이미 구매하셨나요? 구매 복원하기'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, Package package) {
    final product = package.storeProduct;
    final isMonthly = package.packageType == PackageType.monthly;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isMonthly ? BorderSide.none : BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      child: InkWell(
        onTap: () => _purchasePackage(package),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.priceString,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  if (!isMonthly)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'BEST',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() => _isLoading = true);
    
    try {
      final isPro = await ref.read(isProProvider.notifier).purchasePackage(package);
      
      if (mounted) {
        if (isPro) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('구매가 완료되었습니다! 감사합니다.')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구매 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    
    try {
      final isPro = await ref.read(isProProvider.notifier).restorePurchases();
      
      if (mounted) {
        if (isPro) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('구매가 복원되었습니다!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('복원할 구매 내역이 없습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('복원 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
