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

  @override
  Widget build(BuildContext context) {
    final diaryDatesAsync = ref.watch(diaryDatesProvider);
    final dates = diaryDatesAsync.valueOrNull ?? [];
    final selectedDate = ref.watch(selectedDateProvider);
    final theme = Theme.of(context);

    return TableCalendar<bool>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: selectedDate,
      calendarFormat: _calendarFormat,
      
      // Single date selection only (no range)
      rangeSelectionMode: RangeSelectionMode.disabled,
      
      selectedDayPredicate: (day) => isSameDay(selectedDate, day),
      
      eventLoader: (day) {
        // Simple check if day has any diary entry
        final normalizedDay = DateTime(day.year, day.month, day.day);
        return dates.any((d) => isSameDay(d, normalizedDay)) ? [true] : [];
      },
      
      onDaySelected: (selectedDay, focusedDay) {
        // Update selected date and refresh diary list
        ref.read(selectedDateProvider.notifier).setDate(selectedDay);
        ref.read(infiniteScrollDiaryListProvider.notifier).refresh();
      },

      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      
      onPageChanged: (focusedDay) {
        // Optionally update focused day
      },
      
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        markerSize: 6,
        markersMaxCount: 1,
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
        outsideDaysVisible: false,
      ),
      
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonDecoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        formatButtonTextStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 12,
        ),
      ),
    );
  }
}
