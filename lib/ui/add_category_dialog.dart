import 'package:flutter/material.dart';
import '../services/category_manager.dart';

/// 添加分类对话框
///
/// 允许用户输入分类名称，验证后创建新的自定义分类
class AddCategoryDialog extends StatefulWidget {
  final Future<void> Function(String name) onSubmitted;

  const AddCategoryDialog({
    super.key,
    required this.onSubmitted,
  });

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 验证并提交分类名称
  Future<void> _submit() async {
    final name = _controller.text.trim();

    // 基本验证
    if (name.isEmpty) {
      setState(() => _errorText = '分类名称不能为空');
      return;
    }

    if (name.length > 10) {
      setState(() => _errorText = '分类名称长度不能超过10个字符');
      return;
    }

    // 开始提交
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.onSubmitted(name);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on CategoryNameEmptyException catch (_) {
      setState(() {
        _errorText = '分类名称不能为空';
        _isSubmitting = false;
      });
    } on CategoryNameTooLongException catch (_) {
      setState(() {
        _errorText = '分类名称长度不能超过10个字符';
        _isSubmitting = false;
      });
    } on CategoryNameDuplicateException catch (e) {
      setState(() {
        _errorText = e.message;
        _isSubmitting = false;
      });
    } on CategoryLimitExceededException catch (e) {
      setState(() {
        _errorText = e.message;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _errorText = '创建分类失败: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加分类'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 10,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
              return Text(
                '$currentLength/${maxLength ?? 10}',
                style: Theme.of(context).textTheme.bodySmall,
              );
            },
            decoration: InputDecoration(
              hintText: '请输入分类名称',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              // 实时更新错误提示
              setState(() {
                // 清除错误提示（如果用户开始输入）
                if (_errorText != null && value.isNotEmpty) {
                  _errorText = null;
                }
              });
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Text(
            '支持 Unicode 和 emoji 字符',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
            ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
            : const Text('确认'),
        ),
      ],
    );
  }
}
