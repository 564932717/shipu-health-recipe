package com.xd.healthrecipe.domain;

import java.time.LocalDate;
import java.util.List;

public record WeeklyReport(
        String userId,
        LocalDate startDate,
        LocalDate endDate,
        int averageCalories,
        int recordDays,
        String completionLevel,
        List<String> trendHighlights,
        List<String> aiSuggestions
) {
}
