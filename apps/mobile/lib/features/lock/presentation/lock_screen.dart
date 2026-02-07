import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/lock/application/lock_service.dart';
import 'package:mobile/features/diary/data/diary_repository.dart';
import 'package:go_router/go_router.dart';

class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback? onUnlock;
  const LockScreen({super.key, this.onUnlock});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _inputPin = '';
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final success = await ref.read(lockServiceProvider).authenticateWithBiometrics();
    if (success && mounted) {
    if (success && mounted) {
       if (widget.onUnlock != null) {
         widget.onUnlock!();
       } else {
         Navigator.of(context).pushReplacementNamed('/');
       }
    }
    }
  }

  void _onKeyPress(String val) {
    if (_inputPin.length < 4) {
      setState(() {
        _inputPin += val;
      });
      if (_inputPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_inputPin.isNotEmpty) {
      setState(() {
        _inputPin = _inputPin.substring(0, _inputPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isChecking = true);
    final isValid = await ref.read(lockServiceProvider).verifyPin(_inputPin);
    
    if (mounted) {
      setState(() {
        _isChecking = false;
        if (!isValid) {
          _inputPin = '';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('비밀번호가 일치하지 않습니다')),
          );
        } else {
           if (widget.onUnlock != null) {
             widget.onUnlock!();
           } else {
             // Fallback for standalone usage (if any)
             context.go('/');
           }
        }
      });
    }
  }

  void _showRecoveryDialog() async {
    final question = await ref.read(lockServiceProvider).getRecoveryQuestion();
    if (!mounted) return;

    if (question == null) {
      // Should not happen if set up correctly
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('복구 질문이 설정되지 않았습니다.')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _RecoveryDialog(question: question),
    );

    if (result == true && mounted) {
      // Recovery success -> Unlock via callback or router
      if (widget.onUnlock != null) {
        widget.onUnlock!();
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock, size: 64),
            const SizedBox(height: 24),
            const Text(
              '잠금 해제',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _inputPin.length
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                );
              }),
            ),
            const Spacer(),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              padding: const EdgeInsets.symmetric(horizontal: 48),
              children: [
                ...List.generate(9, (index) => _buildKey('${index + 1}')),
                TextButton(
                  onPressed: _showRecoveryDialog,
                  child: const Text('비밀번호 찾기', style: TextStyle(fontSize: 12)),
                ),
                _buildKey('0'),
                IconButton(
                  onPressed: _onDelete,
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Emergency Reset Button (User Request)
            TextButton(
              onPressed: () async {
                await ref.read(lockServiceProvider).resetLock();
                if (context.mounted) {
                   if (widget.onUnlock != null) {
                     widget.onUnlock!();
                   } else {
                     context.go('/');
                   }
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('긴급 해제 완료! (테스트 후 다시 설정하세요)')),
                   );
                }
              },
              child: const Text(
                '긴급 초기화 (테스트용)',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String val) {
    return InkWell(
      onTap: () => _onKeyPress(val),
      borderRadius: BorderRadius.circular(32),
      child: Center(
        child: Text(
          val,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _RecoveryDialog extends ConsumerStatefulWidget {
  final String question;
  const _RecoveryDialog({required this.question});

  @override
  ConsumerState<_RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends ConsumerState<_RecoveryDialog> {
  final _answerController = TextEditingController();
  int _failCount = 0;

  Future<void> _verifyAnswer() async {
    final isValid = await ref.read(lockServiceProvider).verifyRecoveryAnswer(_answerController.text);
    if (!mounted) return;

    if (isValid) {
      // SUCCESS: Reset Lock Settings ONLY (Keep Data)
      await ref.read(lockServiceProvider).resetLock();
      
      if (mounted) {
        Navigator.pop(context, true); // Return success result
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('본인 인증 완료. 비밀번호 설정이 초기화되었습니다.')),
        );
      }
    } else {
      // FAILURE
      setState(() {
        _failCount++;
      });
      
      if (_failCount >= 3) {
        // Show Wipe Dialog
        _showWipeConfirm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('답변이 일치하지 않습니다 (${_failCount}/3)')),
        );
      }
    }
  }

  void _showWipeConfirm() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('본인 인증 실패', style: TextStyle(color: Colors.red)),
        content: const Text(
          '본인 인증에 3회 실패했습니다.\n\n보안을 위해 앱을 초기화하시겠습니까?\n\n주의: "초기화"를 선택하면 저장된 모든 일기 데이터가 영구적으로 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () { 
              Navigator.pop(context); // Close confirm
              // Reset count on cancel? Or keep it? keeping it strict.
            },
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Wipe data
              final repo = ref.read(diaryRepositoryProvider);
              await repo.clearAllData(); 
              
              await ref.read(lockServiceProvider).resetLock();
              
              if (mounted) {
                // Return to main and likely restart/exit or just goto home empty
                Navigator.pop(context); // Close confirm
                Navigator.pop(context, true); // Close recovery with "success" (as in flow complete)
              }
            },
            child: const Text('초기화 (데이터 삭제)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('비밀번호 찾기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('질문: ${widget.question}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _answerController,
            decoration: const InputDecoration(
              hintText: '답변 입력',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _verifyAnswer,
          child: const Text('확인'),
        ),
      ],
    );
  }
}
