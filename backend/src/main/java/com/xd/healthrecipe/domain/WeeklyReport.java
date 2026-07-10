package com.xd.healthrecipe.domain;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public record WeeklyReport(
        String userId,
        LocalDate startDate,
        LocalDate endDate,
        int averageCalories,
        int recordDays,
        String completionLevel,
        List<String> trendHighlights,
        List<String> aiSuggestions,
        Map<String, Integer> dailyCalories,
        Map<String, Integer> dailyProtein,
        Map<String, Integer> dailyFat,
        Map<String, Integer> dailyCarbs,
        int avgProtein,
        int avgFat,
        int avgCarbs,
        double calorieCompletionRate,
        double proteinCompletionRate,
        double fatCompletionRate,
        double carbCompletionRate,
        double recordDayRate,
        int breakfastCount,
        int lunchCount,
        int dinnerCount,
        int snackCount,
        int weekOverWeekCalorieChange,
        String weekOverWeekTrend
) {
}
