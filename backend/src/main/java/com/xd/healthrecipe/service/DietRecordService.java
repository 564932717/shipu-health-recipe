package com.xd.healthrecipe.service;

import com.xd.healthrecipe.domain.DietRecord;
import com.xd.healthrecipe.domain.NutritionSummary;
import com.xd.healthrecipe.dto.DietRecordRequest;
import com.xd.healthrecipe.repository.DietRecordRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class DietRecordService {
    private final DietRecordRepository dietRecordRepository;

    public DietRecordService(DietRecordRepository dietRecordRepository) {
        this.dietRecordRepository = dietRecordRepository;
    }

    public DietRecord add(DietRecordRequest request) {
        DietRecord record = new DietRecord(
                UUID.randomUUID().toString(),
                request.userId(),
                request.foodName(),
                request.mealType(),
                request.calories(),
                request.proteinGram(),
                request.fatGram(),
                request.carbohydrateGram(),
                LocalDateTime.now()
        );
        return dietRecordRepository.save(record);
    }

    public List<DietRecord> listByUser(String userId) {
        return dietRecordRepository.listByUser(userId);
    }

    public NutritionSummary dailySummary(String userId, int targetCalories) {
        LocalDate today = LocalDate.now();
        List<DietRecord> todayRecords = dietRecordRepository.listByUser(userId).stream()
                .filter(record -> record.eatenAt().toLocalDate().equals(today))
                .toList();
        int calories = todayRecords.stream().mapToInt(DietRecord::calories).sum();
        int protein = todayRecords.stream().mapToInt(DietRecord::proteinGram).sum();
        int fat = todayRecords.stream().mapToInt(DietRecord::fatGram).sum();
        int carbs = todayRecords.stream().mapToInt(DietRecord::carbohydrateGram).sum();
        double completion = targetCalories <= 0 ? 0 : Math.round(calories * 1000.0 / targetCalories) / 10.0;
        return new NutritionSummary(userId, calories, protein, fat, carbs, completion, suggestions(completion));
    }

    private List<String> suggestions(double completion) {
        List<String> suggestions = new ArrayList<>();
        if (completion < 70) {
            suggestions.add("今日摄入不足，可适当补充优质蛋白和复合碳水。");
        } else if (completion > 110) {
            suggestions.add("今日热量摄入偏高，晚间建议减少油脂和精制碳水。");
        } else {
            suggestions.add("今日热量摄入接近目标，继续保持均衡搭配。");
        }
        suggestions.add("建议记录完整三餐，便于生成更准确的健康周报。");
        return suggestions;
    }
}
