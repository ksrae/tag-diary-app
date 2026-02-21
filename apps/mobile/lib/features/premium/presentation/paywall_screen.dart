import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:mobile/features/premium/application/purchase_provider.dart';
import 'package:mobile/features/premium/data/purchase_repository.dart';
import 'package:mobile/core/services/firestore_service.dart';

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
    final currentPlan = ref.watch(subscriptionPlanProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('요금제 선택'),
      ),
      body: FutureBuilder<Offerings?>(
        future: purchaseRepo.getOfferings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Even if offerings fail, show the plan comparison
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Icon(Icons.workspace_premium, size: 64, color: Colors.amber),
                  const SizedBox(height: 12),
                  Text(
                    '나에게 맞는 요금제를 선택하세요',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Free Plan Card
                  _buildPlanCard(
                    context,
                    title: 'Free',
                    price: '무료',
                    isCurrentPlan: currentPlan == SubscriptionPlan.free,
                    features: [
                      '최근 3일 일기만 열람/수정 가능',
                      '오늘 일기만 작성 가능',
                      'AI 일기: 광고 시청 시 1회/일',
                      '7일 경과 일기 자동 삭제',
                    ],
                    color: Colors.grey,
                    onTap: null, // Can't purchase free
                  ),
                  const SizedBox(height: 12),

                  // Basic Plan Card
                  _buildPlanCard(
                    context,
                    title: 'Basic',
                    price: '\$1.99/월',
                    isCurrentPlan: currentPlan == SubscriptionPlan.basic,
                    features: [
                      '모든 과거 일기 열람 가능',
                      '오늘 일기만 작성 가능',
                      'AI 일기: 3회/일',
                      '클라우드 저장: 1GB',
                      '광고 제거',
                    ],
                    color: Colors.blue,
                    onTap: _isLoading
                        ? null
                        : () => _purchaseByIdentifier(snapshot.data, 'basic'),
                  ),
                  const SizedBox(height: 12),

                  // Pro Plan Card (recommended)
                  _buildPlanCard(
                    context,
                    title: 'Pro',
                    price: '\$4.99/월',
                    isCurrentPlan: currentPlan == SubscriptionPlan.pro,
                    isRecommended: true,
                    features: [
                      '모든 과거 일기 열람 가능',
                      '과거 날짜에도 일기 작성 가능',
                      'AI 일기: 5회/일',
                      '클라우드 저장: 5GB',
                      '광고 제거',
                      '모든 향후 기능 포함',
                    ],
                    color: Colors.deepPurple,
                    onTap: _isLoading
                        ? null
                        : () => _purchaseByIdentifier(snapshot.data, 'pro'),
                  ),

                  const SizedBox(height: 20),

                  // Add-on: Extra storage
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.add_circle_outline, color: Colors.teal),
                      title: const Text('저장 용량 추가'),
                      subtitle: const Text('1GB / \$0.99 (일회성)'),
                      trailing: FilledButton(
                        onPressed: currentPlan == SubscriptionPlan.free || _isLoading
                            ? null
                            : () => _purchaseByIdentifier(snapshot.data, 'storage_1gb'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        child: const Text('구매'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  // Restore purchases
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

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required bool isCurrentPlan,
    required List<String> features,
    required Color color,
    bool isRecommended = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: isRecommended ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isRecommended
            ? BorderSide(color: color, width: 2)
            : isCurrentPlan
                ? BorderSide(color: Colors.green, width: 2)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: isCurrentPlan ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '추천',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (isCurrentPlan)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '현재 플랜',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    price,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: color),
                        const SizedBox(width: 8),
                        Flexible(child: Text(f, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchaseByIdentifier(Offerings? offerings, String identifier) async {
    if (offerings == null || offerings.current == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품 정보를 불러올 수 없습니다. 다시 시도해주세요.')),
        );
      }
      return;
    }

    final packages = offerings.current!.availablePackages;
    Package? target;
    try {
      target = packages.firstWhere(
        (p) => p.identifier.toLowerCase().contains(identifier.toLowerCase()),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$identifier 상품을 찾을 수 없습니다.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isPro = await ref.read(isProProvider.notifier).purchasePackage(target);

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
