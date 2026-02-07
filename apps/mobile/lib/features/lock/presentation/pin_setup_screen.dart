import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/lock/application/lock_service.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();

  final _pinFocus = FocusNode();
  final _confirmFocus = FocusNode();
  
  int _step = 0; // 0: Set PIN, 1: Confirm PIN, 2: Security Question
  String _firstPin = '';

  @override
  void initState() {
    super.initState();
    // Force rebuild when focus changes to update UI borders
    _pinFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
    
    // Ensure keyboard shows up on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    _pinFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0) {
      if (_pinController.text.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('4자리 숫자를 입력해주세요')),
        );
        return;
      }
      setState(() {
        _firstPin = _pinController.text;
        _step = 1;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confirmFocus.requestFocus();
      });
    } else if (_step == 1) {
      if (_confirmController.text != _firstPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호가 일치하지 않습니다')),
        );
        return;
      }
      setState(() {
        _step = 2;
      });
    } else if (_step == 2) {
      if (_questionController.text.isEmpty || _answerController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('질문과 답변을 모두 입력해주세요')),
        );
        return;
      }
      _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    try {
      await ref.read(lockServiceProvider).setupLock(
            _firstPin,
            _questionController.text,
            _answerController.text,
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('잠금 설정이 완료되었습니다')),
        );
        Navigator.pop(context, true); // Return success result
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('앱 잠금 설정')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (_step == 0) ...[
              const Text('사용할 4자리 비밀번호를 입력해주세요', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              _buildPinInput(_pinController, _pinFocus),
            ] else if (_step == 1) ...[
              const Text('비밀번호를 한 번 더 입력해주세요', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              _buildPinInput(_confirmController, _confirmFocus),
            ] else ...[
              const Text(
                '비밀번호를 잊어버렸을 때를 대비해\n질문과 답변을 설정해주세요',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '질문 (예: 가장 좋아하는 색깔은?)',
                  hintText: '질문을 입력하세요',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '답변',
                  hintText: '답변을 입력하세요',
                ),
              ),
            ],
            const Spacer(),
            if (_step == 2)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextStep,
                  child: const Text('완료'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinInput(TextEditingController controller, FocusNode focusNode) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 80,
        child: Stack(
          children: [
            // Invisible TextField for input handling
            TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              showCursor: false,
              enableSuggestions: false,
              autocorrect: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.transparent),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
              ),
              onChanged: (value) {
                setState(() {}); // Rebuild to show dots
                if (value.length == 4) {
                   // Auto-advance after small delay for UX
                   Future.delayed(const Duration(milliseconds: 200), () {
                     if (mounted) _nextStep();
                   });
                }
              },
            ),
            // Visible Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                final textLength = controller.text.length;
                final hasValue = index < textLength;
                final isFocused = index == textLength; // Current cursor position
                
                return Container(
                  width: 50,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: hasValue || (isFocused && focusNode.hasFocus)
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.grey.shade400,
                      width: (isFocused && focusNode.hasFocus) ? 2.5 : 2, // Thicker border for focus
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: hasValue 
                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                        : (isFocused && focusNode.hasFocus 
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1) // Explicit focus color
                            : Colors.transparent),
                  ),
                  child: Center(
                    child: hasValue
                        ? Text(
                            '*', 
                            style: TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary
                            ),
                          )
                        : (isFocused && focusNode.hasFocus
                           // Active cursor indicator (blinking line or just empty)
                           // Use a stronger filled color for the active box
                           ? Container(
                               width: 2, 
                               height: 24, 
                               color: Theme.of(context).colorScheme.primary
                             ) 
                           : null),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
