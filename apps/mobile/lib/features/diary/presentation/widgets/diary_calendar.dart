import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/diary/application/diary_provider.dart';
import 'package:table_calendar/table_calendar.dart';

class DiaryCalendar extends ConsumerStatefulWidget {
  const DiaryCalendar({super.key});

  @override
  ConsumerState<DiaryCalendar> createState() => _DiaryCalendarState();
}

class _DiaryCalendarState extends ConsumerState<DiaryCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  Widget build(BuildContext context) {
    final diaryDatesAsync = ref.watch(diaryDatesProvider);
    final dates = diaryDatesAsync.valueOrNull ?? [];

    return TableCalendar<bool>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      rangeSelectionMode: RangeSelectionMode.toggledOn,
      
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      rangeStartDay: _rangeStart,
      rangeEndDay: _rangeEnd,
      
      eventLoader: (day) {
        // Simple check if day has any diary entry
        // We normalize dates to year-month-day in repository, so simple comparison
        final normalizedDay = DateTime(day.year, day.month, day.day);
        return dates.any((d) => isSameDay(d, normalizedDay)) ? [true] : [];
      },
      
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _rangeStart = null;
            _rangeEnd = null;
          });
          
          // Filter provider update (Start of day to End of day)
          ref.read(diaryFilterProvider.notifier).setRange(selectedDay, selectedDay);
        }
      },
      
      onRangeSelected: (start, end, focusedDay) {
        setState(() {
          _selectedDay = null;
          _focusedDay = focusedDay;
          _rangeStart = start;
          _rangeEnd = end;
        });
        
        // Filter provider update
        // If end is null, it means range selection is in progress (start only), 
        // we can filter just for start day or wait. Usually wait or just show start.
        if (start != null) {
           ref.read(diaryFilterProvider.notifier).setRange(start, end ?? start);
        }
      },

      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        rangeStartDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        rangeEndDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        rangeHighlightColor: Theme.of(context).primaryColor.withOpacity(0.2),
      ),
    );
  }
}
