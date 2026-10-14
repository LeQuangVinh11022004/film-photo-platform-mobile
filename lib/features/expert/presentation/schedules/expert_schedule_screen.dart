import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/expert_workshop.dart';
import 'widgets/workshop_card.dart';
import 'widgets/workshop_form_sheet.dart';

class ExpertScheduleScreen extends StatefulWidget {
  const ExpertScheduleScreen({super.key});
  @override
  State<ExpertScheduleScreen> createState() => _ExpertScheduleScreenState();
}

class _ExpertScheduleScreenState extends State<ExpertScheduleScreen> {
  late DateTime _monday, _selected;
  late List<ExpertWorkshop> _items;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monday = _startOfWeek(now);
    _selected = DateTime(now.year, now.month, now.day);
    _items = [
      _demo(
        '1',
        'Workshop: Chụp chân dung bằng film',
        1,
        '09:00',
        '11:30',
        'The Film Lab, Quận 3',
        'Workshop',
      ),
      _demo(
        '2',
        'Tư vấn chọn máy film cho người mới',
        3,
        '14:00',
        '15:00',
        'Google Meet',
        'Tư vấn',
      ),
      _demo(
        '3',
        'Thực hành ánh sáng trong studio',
        5,
        '13:30',
        '16:00',
        'Darkroom Studio, Bình Thạnh',
        'Workshop',
      ),
    ];
  }

  DateTime _startOfWeek(DateTime d) {
    final x = DateTime(d.year, d.month, d.day);
    return x.subtract(Duration(days: x.weekday - 1));
  }

  ExpertWorkshop _demo(
    String id,
    String title,
    int day,
    String start,
    String end,
    String place,
    String category,
  ) => ExpertWorkshop(
    id: id,
    title: title,
    description: 'Buổi chia sẻ thực hành về nhiếp ảnh film. Chuẩn bị máy ảnh và film nếu có.',
    date: _monday.add(Duration(days: day)),
    startTime: start,
    endTime: end,
    location: place,
    capacity: 12,
    category: category,
  );
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  List<ExpertWorkshop> get _forSelected =>
      _items.where((e) => _sameDay(e.date, _selected)).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  Future<void> _edit({ExpertWorkshop? item}) async {
    final result = await showModalBottomSheet<ExpertWorkshop>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkshopFormSheet(initial: item, date: _selected),
    );
    if (result == null || !mounted) return;
    setState(() {
      final i = _items.indexWhere((e) => e.id == result.id);
      if (i < 0) {
        _items.add(result);
      } else {
        _items[i] = result;
      }
      _selected = DateTime(
        result.date.year,
        result.date.month,
        result.date.day,
      );
      _monday = _startOfWeek(result.date);
    });
  }

  Future<void> _details(ExpertWorkshop item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkshopDetailSheet(item: item),
    );
    if (!mounted) return;
    if (action == 'edit') _edit(item: item);
    if (action == 'delete')
      setState(() => _items.removeWhere((e) => e.id == item.id));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    const fullDays = [
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 150),
              children: [
                Text(
                  'Lịch trình',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Quản lý workshop và lịch tư vấn của bạn',
                  style: TextStyle(color: context.textSecColor, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_monthName(_monday.month)} ${_monday.year}',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _monday = _monday.subtract(const Duration(days: 7));
                        _selected = _monday;
                      }),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _monday = _monday.add(const Duration(days: 7));
                        _selected = _monday;
                      }),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                    IconButton(
                      tooltip: 'Về hôm nay',
                      onPressed: () => setState(() {
                        _monday = _startOfWeek(today);
                        _selected = DateTime(
                          today.year,
                          today.month,
                          today.day,
                        );
                      }),
                      icon: const Icon(Icons.today_rounded),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(7, (i) {
                    final d = _monday.add(Duration(days: i));
                    final selected = _sameDay(d, _selected);
                    final has = _items.any((e) => _sameDay(e.date, d));
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _selected = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF7C5CFC)
                                  : context.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _sameDay(d, today) && !selected
                                    ? const Color(0xFF7C5CFC)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  days[i],
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : context.textSecColor,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  '${d.day}',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : context.textColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: has
                                        ? (selected
                                              ? Colors.white
                                              : const Color(0xFF7C5CFC))
                                        : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_sameDay(_selected, today) ? 'Hôm nay' : fullDays[_selected.weekday - 1]} · ${_date(_selected)}',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_forSelected.length} lịch',
                      style: TextStyle(
                        color: context.textSecColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_forSelected.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 42,
                          color: context.textSecColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Chưa có lịch nào',
                          style: TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Tạo workshop hoặc thêm lịch tư vấn cho ngày này.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.textSecColor),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _edit(),
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo lịch mới'),
                        ),
                      ],
                    ),
                  )
                else
                  ..._forSelected.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: WorkshopCard(
                        workshop: e,
                        onTap: () => _details(e),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Text(
                  'Các lịch khác trong tuần',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...List.generate(7, (i) {
                  final d = _monday.add(Duration(days: i));
                  final events = _items
                      .where(
                        (e) => _sameDay(e.date, d) && !_sameDay(d, _selected),
                      )
                      .toList();
                  if (events.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          '${fullDays[i]} · ${_date(d)}',
                          style: TextStyle(
                            color: context.textSecColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ...events.map(
                        (e) => WorkshopCard(
                          workshop: e,
                          onTap: () {
                            setState(() => _selected = d);
                            _details(e);
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 108,
              child: FloatingActionButton(
                heroTag: 'expert_schedule_add',
                backgroundColor: const Color(0xFF7C5CFC),
                foregroundColor: Colors.white,
                onPressed: () => _edit(),
                child: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) => const [
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ][month - 1];
}
