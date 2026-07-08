package com.xd.healthrecipe.service;

import com.xd.healthrecipe.domain.DietRecord;
import com.xd.healthrecipe.domain.WeeklyReport;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
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
        Map<LocalDate, Integer> caloriesByDay = records.stream()
                .collect(Collectors.groupingBy(record -> record.eatenAt().toLocalDate(),
                        Collectors.summingInt(DietRecord::calories)));
        int recordDays = caloriesByDay.size();
        int average = recordDays == 0 ? 0 : caloriesByDay.values().stream().mapToInt(Integer::intValue).sum() / recordDays;
        return new WeeklyReport(
                userId,
                start,
                end,
                average,
                recordDays,
                completionLevel(average, targetCalories),
                buildHighlights(recordDays, average),
                buildSuggestions(average, targetCalories)
        );
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

    private List<String> buildHighlights(int recordDays, int averageCalories) {
        return List.of(
                "本周已记录 " + recordDays + " 天饮食数据。",
                "日均摄入约 " + averageCalories + " 千卡。",
                "记录越完整，AI 周报建议越准确。"
        );
    }

    private List<String> buildSuggestions(int averageCalories, int targetCalories) {
        if (averageCalories == 0) {
            return List.of("建议从今天开始记录三餐，系统会自动生成趋势分析。");
        }
        if (averageCalories < targetCalories * 0.8) {
            return List.of("本周平均摄入偏低，可在早餐或加餐中增加鸡蛋、牛奶、坚果等优质营养来源。");
        }
        if (averageCalories > targetCalories * 1.1) {
            return List.of("本周平均摄入偏高，建议减少油炸食品和含糖饮料，晚餐保持清淡。");
        }
        return List.of("本周热量控制较稳定，建议继续保持高蛋白、足量蔬菜和规律记录。");
    }
}
