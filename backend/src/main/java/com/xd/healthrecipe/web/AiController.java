package com.xd.healthrecipe.web;

import com.xd.healthrecipe.domain.*;
import com.xd.healthrecipe.dto.ApiResponse;
import com.xd.healthrecipe.service.AiChatService;
import com.xd.healthrecipe.service.DietRecordService;
import com.xd.healthrecipe.service.HealthAssessmentService;
import com.xd.healthrecipe.service.ReportService;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/ai")
public class AiController {
    private final AiChatService aiChatService;
    private final HealthAssessmentService assessmentService;
    private final ReportService reportService;
    private final DietRecordService dietRecordService;

    public AiController(AiChatService aiChatService,
                        HealthAssessmentService assessmentService,
                        ReportService reportService,
                        DietRecordService dietRecordService) {
        this.aiChatService = aiChatService;
        this.assessmentService = assessmentService;
        this.reportService = reportService;
        this.dietRecordService = dietRecordService;
    }

    /**
     * AI 智能三餐推荐
     */
    @PostMapping("/recommend-meals")
    public ApiResponse<AiMealPlan> recommendMeals(@RequestBody Map<String, Object> body) {
        @SuppressWarnings("unchecked")
        Map<String, Object> profileMap = (Map<String, Object>) body.get("profile");

        HealthProfile profile = parseProfile(profileMap);
        HealthAssessment assessment = assessmentService.evaluate(profile);

        int refreshIndex = body.containsKey("refreshIndex")
                ? ((Number) body.get("refreshIndex")).intValue()
                : 0;

        AiMealPlan plan = aiChatService.generateMealPlan(profile, assessment, refreshIndex);
        return ApiResponse.ok(plan);
    }

    /**
     * AI 单日饮食分析
     */
    @PostMapping("/daily-analysis")
    public ApiResponse<List<String>> dailyAnalysis(@RequestBody Map<String, Object> body) {
        String userId = (String) body.get("userId");
        String date = (String) body.get("date");

        int targetCalories = body.containsKey("targetCalories")
                ? ((Number) body.get("targetCalories")).intValue()
                : 1800;
        int targetProtein = body.containsKey("targetProtein")
                ? ((Number) body.get("targetProtein")).intValue()
                : 100;
        int targetFat = body.containsKey("targetFat")
                ? ((Number) body.get("targetFat")).intValue()
                : 50;
        int targetCarbs = body.containsKey("targetCarbs")
                ? ((Number) body.get("targetCarbs")).intValue()
                : 200;

        LocalDate targetDate = date != null && !date.isEmpty() ? LocalDate.parse(date) : LocalDate.now();
        List<DietRecord> dayRecords = dietRecordService.listByUser(userId).stream()
                .filter(r -> r.eatenAt().toLocalDate().equals(targetDate))
                .toList();

        List<String> analysis = aiChatService.generateDailyAnalysis(
                userId, dayRecords, targetCalories, targetProtein, targetFat, targetCarbs);
        return ApiResponse.ok(analysis);
    }

    /**
     * AI 周报改善建议
     */
    @PostMapping("/weekly-suggestions")
    public ApiResponse<List<String>> weeklySuggestions(@RequestBody Map<String, Object> body) {
        String userId = (String) body.get("userId");
        String date = (String) body.get("date");
        int targetCalories = body.containsKey("targetCalories")
                ? ((Number) body.get("targetCalories")).intValue()
                : 1800;

        WeeklyReport report = reportService.weeklyReport(userId, targetCalories, date);
        List<String> suggestions = aiChatService.generateWeeklySuggestions(userId, report);
        return ApiResponse.ok(suggestions);
    }

    @SuppressWarnings("unchecked")
    private HealthProfile parseProfile(Map<String, Object> map) {
        String userId = getString(map, "userId", "demo");
        int age = getInt(map, "age", 25);
        Gender gender = parseGender(getString(map, "gender", "UNKNOWN"));
        double heightCm = getDouble(map, "heightCm", 170);
        double weightKg = getDouble(map, "weightKg", 65);
        HealthGoal goal = parseGoal(getString(map, "goal", "BALANCED"));
        List<String> chronicConditions = parseStringList(map, "chronicConditions");
        List<String> taboos = parseStringList(map, "taboos");
        List<String> tastePreferences = parseStringList(map, "tastePreferences");
        return new HealthProfile(userId, age, gender, heightCm, weightKg, goal,
                chronicConditions, taboos, tastePreferences);
    }

    private String getString(Map<String, Object> map, String key, String defaultValue) {
        Object val = map.get(key);
        return val == null ? defaultValue : val.toString();
    }

    private int getInt(Map<String, Object> map, String key, int defaultValue) {
        Object val = map.get(key);
        if (val instanceof Number) {
            return ((Number) val).intValue();
        }
        if (val instanceof String) {
            try {
                return Integer.parseInt((String) val);
            } catch (NumberFormatException ignored) {}
        }
        return defaultValue;
    }

    private double getDouble(Map<String, Object> map, String key, double defaultValue) {
        Object val = map.get(key);
        if (val instanceof Number) {
            return ((Number) val).doubleValue();
        }
        if (val instanceof String) {
            try {
                return Double.parseDouble((String) val);
            } catch (NumberFormatException ignored) {}
        }
        return defaultValue;
    }

    private Gender parseGender(String s) {
        if ("MALE".equalsIgnoreCase(s)) {
            return Gender.MALE;
        }
        if ("FEMALE".equalsIgnoreCase(s)) {
            return Gender.FEMALE;
        }
        return Gender.UNKNOWN;
    }

    private HealthGoal parseGoal(String s) {
        try {
            return HealthGoal.valueOf(s);
        } catch (IllegalArgumentException e) {
            return HealthGoal.BALANCED;
        }
    }

    @SuppressWarnings("unchecked")
    private List<String> parseStringList(Map<String, Object> map, String key) {
        Object obj = map.get(key);
        if (obj == null) {
            return List.of();
        }
        if (obj instanceof List) {
            return ((List<Object>) obj).stream().map(Object::toString).toList();
        }
        if (obj instanceof String && !((String) obj).isEmpty()) {
            return List.of(((String) obj).split("[,，]"));
        }
        return List.of();
    }
}
