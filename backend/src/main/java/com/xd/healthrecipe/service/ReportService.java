package com.xd.healthrecipe.service;

import com.xd.healthrecipe.domain.DietRecord;
import com.xd.healthrecipe.domain.MealType;
import com.xd.healthrecipe.domain.WeeklyReport;
import org.springframework.stereotype.Service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.format.TextStyle;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class ReportService {
    private final DietRecordService dietRecordService;

    public ReportService(DietRecordService dietRecordService) {
        this.dietRecordService = dietRecordService;
    }

    public WeeklyReport weeklyReport(String userId, int targetCalories) {
        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(6);
        List<DietRecord> records = dietRecordService.listByUser(userId).stream()
                .filter(record -> {
                    LocalDate day = record.eatenAt().toLocalDate();
                    return !day.isBefore(start) && !day.isAfter(end);
                })
                .toList();

        Map<LocalDate, List<DietRecord>> byDay = records.stream()
                .collect(Collectors.groupingBy(record -> record.eatenAt().toLocalDate()));

        int recordDays = byDay.size();
        int totalCalories = records.stream().mapToInt(DietRecord::calories).sum();
        int totalProtein = records.stream().mapToInt(DietRecord::proteinGram).sum();
        int totalFat = records.stream().mapToInt(DietRecord::fatGram).sum();
        int totalCarbs = records.stream().mapToInt(DietRecord::carbohydrateGram).sum();
        int average = recordDays == 0 ? 0 : totalCalories / recordDays;
        int avgProtein = recordDays == 0 ? 0 : totalProtein / recordDays;
        int avgFat = recordDays == 0 ? 0 : totalFat / recordDays;
        int avgCarbs = recordDays == 0 ? 0 : totalCarbs / recordDays;

        Map<String, Integer> dailyCalories = buildDailyMap(start, end, byDay, DietRecord::calories);
        Map<String, Integer> dailyProtein = buildDailyMap(start, end, byDay, DietRecord::proteinGram);
        Map<String, Integer> dailyFat = buildDailyMap(start, end, byDay, DietRecord::fatGram);
        Map<String, Integer> dailyCarbs = buildDailyMap(start, end, byDay, DietRecord::carbohydrateGram);

        int targetProtein = (int) Math.round(targetCalories * 0.25 / 4);
        int targetFat = (int) Math.round(targetCalories * 0.25 / 9);
        int targetCarbs = (int) Math.round(targetCalories * 0.50 / 4);

        double calorieCompletionRate = targetCalories <= 0 ? 0 : Math.min(100, Math.round(average * 1000.0 / targetCalories) / 10.0);
        double proteinCompletionRate = targetProtein <= 0 ? 0 : Math.min(100, Math.round(avgProtein * 1000.0 / targetProtein) / 10.0);
        double fatCompletionRate = targetFat <= 0 ? 0 : Math.min(100, Math.round(avgFat * 1000.0 / targetFat) / 10.0);
        double carbCompletionRate = targetCarbs <= 0 ? 0 : Math.min(100, Math.round(avgCarbs * 1000.0 / targetCarbs) / 10.0);
        double recordDayRate = Math.round(recordDays * 1000.0 / 7) / 10.0;

        long breakfastCount = records.stream().filter(r -> r.mealType() == MealType.BREAKFAST).count();
        long lunchCount = records.stream().filter(r -> r.mealType() == MealType.LUNCH).count();
        long dinnerCount = records.stream().filter(r -> r.mealType() == MealType.DINNER).count();
        long snackCount = records.stream().filter(r -> r.mealType() == MealType.SNACK).count();

        int weekOverWeekCalorieChange = calcWeekOverWeekChange(userId, end, totalCalories, recordDays);
        String weekOverWeekTrend = weekOverWeekTrend(weekOverWeekCalorieChange);

        return new WeeklyReport(
                userId,
                start,
                end,
                average,
                recordDays,
                completionLevel(average, targetCalories),
                buildHighlights(recordDays, average, avgProtein, avgFat, avgCarbs, recordDayRate,
                        breakfastCount, lunchCount, dinnerCount, snackCount, weekOverWeekTrend),
                buildSuggestions(average, totalCalories, targetCalories, recordDays, recordDayRate,
                        calorieCompletionRate, proteinCompletionRate, fatCompletionRate, carbCompletionRate,
                        breakfastCount, lunchCount, dinnerCount, snackCount,
                        totalProtein, totalFat, totalCarbs),
                dailyCalories,
                dailyProtein,
                dailyFat,
                dailyCarbs,
                avgProtein,
                avgFat,
                avgCarbs,
                calorieCompletionRate,
                proteinCompletionRate,
                fatCompletionRate,
                carbCompletionRate,
                recordDayRate,
                (int) breakfastCount,
                (int) lunchCount,
                (int) dinnerCount,
                (int) snackCount,
                weekOverWeekCalorieChange,
                weekOverWeekTrend
        );
    }

    private Map<String, Integer> buildDailyMap(LocalDate start, LocalDate end,
                                               Map<LocalDate, List<DietRecord>> byDay,
                                               java.util.function.ToIntFunction<DietRecord> mapper) {
        Map<String, Integer> result = new LinkedHashMap<>();
        for (LocalDate date = start; !date.isAfter(end); date = date.plusDays(1)) {
            String dayLabel = date.getDayOfWeek().getDisplayName(TextStyle.SHORT, Locale.CHINESE);
            List<DietRecord> dayRecords = byDay.getOrDefault(date, List.of());
            int sum = dayRecords.stream().mapToInt(mapper).sum();
            result.put(dayLabel, sum);
        }
        return result;
    }

    private int calcWeekOverWeekChange(String userId, LocalDate thisEnd, int thisWeekTotal, int thisWeekDays) {
        LocalDate prevStart = thisEnd.minusDays(13);
        LocalDate prevEnd = thisEnd.minusDays(7);
        List<DietRecord> prevRecords = dietRecordService.listByUser(userId).stream()
                .filter(record -> {
                    LocalDate day = record.eatenAt().toLocalDate();
                    return !day.isBefore(prevStart) && !day.isAfter(prevEnd);
                })
                .toList();
        if (prevRecords.isEmpty() || thisWeekDays == 0) {
            return 0;
        }
        long prevDays = prevRecords.stream().map(r -> r.eatenAt().toLocalDate()).distinct().count();
        if (prevDays == 0) {
            return 0;
        }
        int prevTotal = prevRecords.stream().mapToInt(DietRecord::calories).sum();
        int prevAvg = (int) (prevTotal / prevDays);
        int thisAvg = thisWeekTotal / thisWeekDays;
        return thisAvg - prevAvg;
    }

    private String weekOverWeekTrend(int change) {
        if (change > 100) {
            return "UP";
        }
        if (change < -100) {
            return "DOWN";
        }
        return "STABLE";
    }

    private String completionLevel(int averageCalories, int targetCalories) {
        if (averageCalories == 0) {
            return "暂无记录";
        }
        double ratio = averageCalories * 1.0 / targetCalories;
        if (ratio < 0.8) {
            return "摄入偏低";
        }
        if (ratio > 1.1) {
            return "摄入偏高";
        }
        return "接近目标";
    }

    private List<String> buildHighlights(int recordDays, int averageCalories,
                                         int avgProtein, int avgFat, int avgCarbs,
                                         double recordDayRate,
                                         long breakfastCount, long lunchCount, long dinnerCount, long snackCount,
                                         String weekOverWeekTrend) {
        List<String> highlights = new ArrayList<>();
        highlights.add("本周已记录 " + recordDays + "/7 天饮食数据，记录率 " + recordDayRate + "%。");
        highlights.add("日均摄入约 " + averageCalories + " 千卡（蛋白质 " + avgProtein + "g / 脂肪 " + avgFat + "g / 碳水 " + avgCarbs + "g）。");
        String trendDesc = switch (weekOverWeekTrend) {
            case "UP" -> "较上周有所上升";
            case "DOWN" -> "较上周有所下降";
            default -> "与上周基本持平";
        };
        highlights.add("周热量趋势：" + trendDesc + "。");
        if (breakfastCount > 0 || lunchCount > 0 || dinnerCount > 0) {
            long maxMeal = Math.max(Math.max(breakfastCount, lunchCount), Math.max(dinnerCount, snackCount));
            String maxMealName = maxMeal == breakfastCount ? "早餐" : maxMeal == lunchCount ? "午餐" : maxMeal == dinnerCount ? "晚餐" : "加餐";
            highlights.add("记录最多的餐次为" + maxMealName + "，共 " + maxMeal + " 条记录。");
        }
        return highlights;
    }

    private List<String> buildSuggestions(int average, int totalCalories, int targetCalories,
                                          int recordDays, double recordDayRate,
                                          double calorieRate, double proteinRate,
                                          double fatRate, double carbRate,
                                          long breakfastCount, long lunchCount, long dinnerCount, long snackCount,
                                          int totalProtein, int totalFat, int totalCarbs) {
        List<String> suggestions = new ArrayList<>();
        if (recordDays == 0) {
            suggestions.add("本周暂无饮食记录。建议从今天开始记录三餐，系统会自动生成趋势分析与改善建议。");
            suggestions.add("开启每日饮食记录，解锁周报、趋势分析和 AI 个性化建议等全部功能。");
            return suggestions;
        }
        if (recordDayRate < 71) {
            suggestions.add("本周记录天数不足（" + recordDayRate + "%），记录越完整，AI 建议越精准。建议每天坚持记录三餐。");
        }
        if (calorieRate < 80) {
            suggestions.add("本周热量摄入偏低（完成率 " + calorieRate + "%），可在早餐或加餐中增加鸡蛋、牛奶、坚果等优质营养，避免能量不足影响代谢。");
        } else if (calorieRate > 110) {
            suggestions.add("本周热量摄入偏高（" + calorieRate + "%），建议减少油炸食品和含糖饮料，晚餐保持七分饱，增加蔬菜比例。");
        } else {
            suggestions.add("本周热量控制较为稳定（完成率 " + calorieRate + "%），继续保持均衡搭配和规律作息。");
        }
        if (proteinRate < 70) {
            suggestions.add("蛋白质摄入不足（完成率 " + proteinRate + "%），建议每餐搭配足量瘦肉、鱼虾、豆制品或蛋奶类食物，有助于肌肉维持和饱腹感。");
        }
        if (fatRate > 120) {
            suggestions.add("脂肪摄入偏高（" + fatRate + "%），优先选择蒸、煮、凉拌等低油烹饪方式，减少动物脂肪和油炸食品。");
        }
        if (carbRate > 120) {
            suggestions.add("碳水化合物摄入偏高（" + carbRate + "%），可逐步用粗粮代替精米白面，控制水果和甜食摄入量。");
        }
        if (breakfastCount == 0) {
            suggestions.add("本周缺少早餐记录，规律三餐是健康饮食的基础，建议每天安排营养均衡的早餐。");
        }
        if (recordDayRate >= 85 && calorieRate >= 80 && calorieRate <= 110) {
            suggestions.add("表扬！本周饮食记录和热量控制均表现良好，继续保持规律记录，AI 将为你提供更精准的长期趋势分析。");
        }
        if (suggestions.size() < 3) {
            suggestions.add("继续保持高蛋白、足量蔬菜和规律记录，下一份周报将涵盖更多维度的分析。");
        }
        return suggestions;
    }
}
