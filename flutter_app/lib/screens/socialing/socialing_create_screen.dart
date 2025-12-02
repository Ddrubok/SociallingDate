import 'package:flutter/material.dart';
import 'package:flutter_app/models/socialing_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/socialing_service.dart';

class SocialingCreateScreen extends StatefulWidget {
  const SocialingCreateScreen({super.key});

  @override
  State<SocialingCreateScreen> createState() => _SocialingCreateScreenState();
}

class _SocialingCreateScreenState extends State<SocialingCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxMembersController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  String _selectedCategory = SocialingModel.categories.first;

  final SocialingService _socialingService = SocialingService();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null) {
      return;
    }

    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final userId = context.read<AuthProvider>().currentUserId!;
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await _socialingService.createSocialing(
        hostId: userId,
        title: _titleController.text,
        content: _contentController.text,
        location: _locationController.text,
        dateTime: dateTime,
        maxMembers: int.parse(_maxMembersController.text),
        tags: [], // 태그 기능은 추후 추가
        category: _selectedCategory,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.createSuccess)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getCategoryText(String code, AppLocalizations l10n) {
    switch (code) {
      case 'small':
        return l10n.catSmall;
      case 'large':
        return l10n.catLarge;
      case 'oneday':
        return l10n.catOneDay;
      case 'weekend':
        return l10n.catWeekend;
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createSocialing)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: l10n.categoryLabel,
                ), // "카테고리"
                items: SocialingModel.categories.map((categoryCode) {
                  return DropdownMenuItem(
                    value: categoryCode,
                    child: Text(
                      _getCategoryText(categoryCode, l10n),
                    ), // 번역된 텍스트 표시
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: l10n.titleHint),
                validator: (v) => v!.isEmpty ? l10n.titleHint : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(labelText: l10n.contentHint),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? l10n.contentHint : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: l10n.locationHint,
                ), // "장소 입력"
                validator: (v) => v!.isEmpty ? l10n.locationHint : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxMembersController,
                decoration: InputDecoration(labelText: l10n.maxMembersHint),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? l10n.maxMembersHint : null,
              ),
              const SizedBox(height: 24),

              // 날짜 & 시간 선택
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectDate(context),
                      child: Text(
                        _selectedDate == null
                            ? l10n.dateHint
                            : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(context),
                      child: Text(
                        _selectedTime == null
                            ? l10n.timeHint
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(l10n.createSocialing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
