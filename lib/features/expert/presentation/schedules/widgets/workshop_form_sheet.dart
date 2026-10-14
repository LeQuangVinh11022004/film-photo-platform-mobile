import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../models/expert_workshop.dart';

class WorkshopFormSheet extends StatefulWidget {
  final ExpertWorkshop? initial;
  final DateTime date;
  const WorkshopFormSheet({super.key, this.initial, required this.date});
  @override
  State<WorkshopFormSheet> createState() => _WorkshopFormSheetState();
}

class _WorkshopFormSheetState extends State<WorkshopFormSheet> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title, _description, _location, _capacity;
  late DateTime _date;
  late TimeOfDay _start, _end;
  late String _category;
  bool get _editing => widget.initial != null;
  @override
  void initState() {
    super.initState();
    final x = widget.initial;
    _title = TextEditingController(text: x?.title ?? '');
    _description = TextEditingController(text: x?.description ?? '');
    _location = TextEditingController(text: x?.location ?? '');
    _capacity = TextEditingController(text: '${x?.capacity ?? 10}');
    _date = x?.date ?? widget.date;
    _start = _parse(x?.startTime ?? '09:00');
    _end = _parse(x?.endTime ?? '11:00');
    _category = x?.category ?? 'Workshop';
  }

  TimeOfDay _parse(String value) {
    final p = value.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _time(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _capacity.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: context.bgColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickStart() async {
    final t = await showTimePicker(context: context, initialTime: _start);
    if (t != null) setState(() => _start = t);
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(context: context, initialTime: _end);
    if (t != null) setState(() => _end = t);
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    if (_end.hour * 60 + _end.minute <= _start.hour * 60 + _start.minute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giờ kết thúc phải sau giờ bắt đầu.')),
      );
      return;
    }
    Navigator.pop(
      context,
      ExpertWorkshop(
        id:
            widget.initial?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        date: DateTime(_date.year, _date.month, _date.day),
        startTime: _time(_start),
        endTime: _time(_end),
        location: _location.text.trim(),
        capacity: int.parse(_capacity.text),
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
    ),
    padding: EdgeInsets.fromLTRB(
      20,
      14,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.textSecColor.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _editing ? 'Chỉnh sửa lịch' : 'Tạo workshop / lịch hẹn',
              style: TextStyle(
                color: context.textColor,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: _dec('Tiêu đề'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Vui lòng nhập tiêu đề.'
                  : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _dec('Loại lịch'),
              items: const [
                DropdownMenuItem(value: 'Workshop', child: Text('Workshop')),
                DropdownMenuItem(value: 'Tư vấn', child: Text('Tư vấn')),
                DropdownMenuItem(value: 'Công việc', child: Text('Công việc')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: _dec('Mô tả'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Vui lòng nhập mô tả.' : null,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text('Ngày: ${_date.day}/${_date.month}/${_date.year}'),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickStart,
                    child: Text('Bắt đầu ${_time(_start)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickEnd,
                    child: Text('Kết thúc ${_time(_end)}'),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _location,
              decoration: _dec('Địa điểm / link online'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Vui lòng nhập địa điểm.'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _capacity,
              keyboardType: TextInputType.number,
              decoration: _dec('Số người tối đa'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 1 ? 'Nhập số lớn hơn 0.' : null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C5CFC),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(_editing ? 'Lưu thay đổi' : 'Tạo lịch'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class WorkshopDetailSheet extends StatelessWidget {
  final ExpertWorkshop item;
  const WorkshopDetailSheet({super.key, required this.item});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
    ),
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.category.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF7C5CFC),
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.title,
          style: TextStyle(
            color: context.textColor,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        _line(
          context,
          Icons.calendar_month,
          '${item.date.day}/${item.date.month}/${item.date.year}',
        ),
        _line(
          context,
          Icons.access_time,
          '${item.startTime} – ${item.endTime}',
        ),
        _line(context, Icons.location_on_outlined, item.location),
        _line(
          context,
          Icons.groups_2_outlined,
          'Tối đa ${item.capacity} người',
        ),
        const SizedBox(height: 10),
        Text(
          item.description,
          style: TextStyle(color: context.textSecColor, height: 1.5),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'delete'),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xoá'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, 'edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Chỉnh sửa'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C5CFC),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _line(BuildContext c, IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF7C5CFC)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(color: c.textColor, fontSize: 13)),
        ),
      ],
    ),
  );
}
