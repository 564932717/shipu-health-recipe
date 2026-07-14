package com.xd.healthrecipe.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.xd.healthrecipe.domain.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class AiChatService {
    private static final Logger log = LoggerFactory.getLogger(AiChatService.class);

    @Value("${ai.api-key}")
    private String apiKey;

    @Value("${ai.model:deepseek-v4-flash}")
    private String model;

    @Value("${ai.base-url:https://api.deepseek.com}")
    private String baseUrl;

    private final ObjectMapper objectMapper;

    public AiChatService(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    /**
     * AI 生成个性化三餐推荐方案
     */
    private static final int MAX_RETRIES = 2;

    public AiMealPlan generateMealPlan(HealthProfile profile, HealthAssessment assessment, int refreshIndex) {
        String systemPrompt = buildMealSystemPrompt();
        String userPrompt = buildMealUserPrompt(profile, assessment, refreshIndex);
        log.info("AI MealPlan request: profile={}, refreshIndex={}", profile.userId(), refreshIndex);

        Exception lastException = null;
        for (int attempt = 0; attempt <= MAX_RETRIES; attempt++) {
            try {
                if (attempt > 0) {
                    long delayMs = attempt * 2000L; // 递增等待：2s、4s
                    log.info("AI MealPlan 第{}次重试，等待{}ms...", attempt, delayMs);
                    Thread.sleep(delayMs);
                }
                return doGenerateMealPlan(systemPrompt, userPrompt);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                lastException = e;
                break;
            } catch (Exception e) {
                lastException = e;
                if (attempt < MAX_RETRIES) {
                    log.warn("AI MealPlan 第{}次尝试失败，将重试: {}", attempt + 1, e.getMessage());
                }
            }
        }

        log.error("AI MealPlan generation failed after {} attempts", MAX_RETRIES + 1, lastException);
        throw new RuntimeException("AI 实时推荐生成失败，已重试" + MAX_RETRIES + "次，请稍后重试", lastException);
    }

    private AiMealPlan doGenerateMealPlan(String systemPrompt, String userPrompt) {
        String response = callAiApi(systemPrompt, userPrompt);
        String json = extractJson(response);
        if (json == null || json.isBlank()) {
            log.error("AI MealPlan JSON extraction returned empty. Raw response: {}", response);
            throw new RuntimeException("AI 返回内容无法解析，可能是频率限制或模型繁忙，请稍后重试");
        }
        log.debug("AI MealPlan JSON: {}", json);

        // AI 可能返回数组而非对象，自动包裹
        Map<String, Object> raw;
        try {
            if (json.trim().startsWith("[")) {
                log.warn("AI 返回了数组格式，自动包裹为对象。原始JSON: {}", json);
                raw = objectMapper.readValue("{\"breakfast\":" + json + "}", new TypeReference<Map<String, Object>>() {});
            } else {
                raw = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
            }
        } catch (JsonProcessingException e) {
            log.error("AI MealPlan JSON 解析失败: {}", e.getMessage());
            throw new RuntimeException("AI 返回的食谱数据格式异常，无法解析", e);
        }

        List<AiRecipe> breakfast = parseRecipeList(raw, "breakfast");
        List<AiRecipe> lunch = parseRecipeList(raw, "lunch");
        List<AiRecipe> dinner = parseRecipeList(raw, "dinner");
        List<AiRecipe> snack = parseRecipeList(raw, "snack");

        // 如果数组格式导致菜品全部归入 breakfast，则按序重新分配
        if (!breakfast.isEmpty() && lunch.isEmpty() && dinner.isEmpty() && snack.isEmpty()) {
            log.warn("AI 返回了数组格式，按序分配到三餐+加餐");
            int total = breakfast.size();
            List<AiRecipe> all = breakfast;
            breakfast = total >= 1 ? List.of(all.get(0)) : List.of();
            lunch = total >= 2 ? List.of(all.get(1)) : List.of();
            dinner = total >= 3 ? List.of(all.get(2)) : List.of();
            snack = total >= 4 ? all.subList(3, total) : List.of();
        }

        int totalCalories = getInt(raw, "totalCalories", 0);
        int totalProtein = getInt(raw, "totalProtein", 0);
        int totalFat = getInt(raw, "totalFat", 0);
        int totalCarbs = getInt(raw, "totalCarbs", 0);

        // 数组格式下没有汇总字段，从菜品中累加
        if (totalCalories == 0) {
            List<AiRecipe> all = new ArrayList<>();
            all.addAll(breakfast);
            all.addAll(lunch);
            all.addAll(dinner);
            all.addAll(snack);
            for (AiRecipe r : all) {
                totalCalories += r.calories();
                totalProtein += r.proteinGram();
                totalFat += r.fatGram();
                totalCarbs += r.carbohydrateGram();
            }
        }

        String macroRatio = totalProtein + "g 蛋白质 / " + totalFat + "g 脂肪 / " + totalCarbs + "g 碳水";
        NutritionTarget estimatedIntake = new NutritionTarget(totalCalories, totalProtein, totalFat, totalCarbs, macroRatio);

        List<String> notes = parseStringList(raw, "notes");
        if (notes.isEmpty()) {
            notes = List.of(
                    "方案由 AI 根据你的健康档案与目标实时生成。",
                    "如不满意可点击\"换一换\"重新生成。",
                    "如有特殊过敏史请在忌口中标注。"
            );
        }

        return new AiMealPlan(breakfast, lunch, dinner, snack, estimatedIntake, notes);
    }


    /**
     * AI 单日饮食分析
     */
    public List<String> generateDailyAnalysis(String userId, List<DietRecord> dayRecords,
                                               int targetCalories, int targetProtein, int targetFat, int targetCarbs) {
        String systemPrompt = buildDailySystemPrompt();
        String userPrompt = buildDailyUserPrompt(dayRecords, targetCalories, targetProtein, targetFat, targetCarbs);
        log.info("AI DailyAnalysis request: userId={}, records={}", userId, dayRecords.size());

        Exception lastException = null;
        for (int attempt = 0; attempt <= MAX_RETRIES; attempt++) {
            try {
                if (attempt > 0) {
                    long delayMs = attempt * 2000L;
                    log.info("AI DailyAnalysis 第{}次重试，等待{}ms...", attempt, delayMs);
                    Thread.sleep(delayMs);
                }
                return doGenerateDailyAnalysis(systemPrompt, userPrompt);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                lastException = e;
                break;
            } catch (Exception e) {
                lastException = e;
                if (attempt < MAX_RETRIES) {
                    log.warn("AI DailyAnalysis 第{}次尝试失败，将重试: {}", attempt + 1, e.getMessage());
                }
            }
        }

        log.error("AI DailyAnalysis failed after {} attempts", MAX_RETRIES + 1, lastException);
        // 本地兜底分析
        return buildLocalDailyAnalysis(dayRecords, targetCalories, targetProtein, targetFat, targetCarbs);
    }

    private List<String> doGenerateDailyAnalysis(String systemPrompt, String userPrompt) {
        String response = callAiApi(systemPrompt, userPrompt);
        String json = extractJson(response);
        if (json == null || json.isBlank()) {
            throw new RuntimeException("AI 返回内容无法解析");
        }
        log.debug("AI DailyAnalysis JSON: {}", json);

        try {
            List<String> suggestions = objectMapper.readValue(json, new TypeReference<List<String>>() {});
            if (suggestions != null && !suggestions.isEmpty()) {
                return suggestions;
            }
        } catch (JsonProcessingException ignored) {}

        try {
            Map<String, Object> raw = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
            @SuppressWarnings("unchecked")
            List<String> suggestions = (List<String>) raw.get("suggestions");
            if (suggestions != null && !suggestions.isEmpty()) {
                return suggestions;
            }
            @SuppressWarnings("unchecked")
            List<String> analysis = (List<String>) raw.get("analysis");
            if (analysis != null && !analysis.isEmpty()) {
                return analysis;
            }
        } catch (JsonProcessingException ignored) {}

        return parseTextSuggestions(response);
    }

    /**
     * AI 生成周报改善建议
     */
    public List<String> generateWeeklySuggestions(String userId, WeeklyReport report) {
        String systemPrompt = buildWeeklySystemPrompt();
        String userPrompt = buildWeeklyUserPrompt(report);
        log.info("AI WeeklySuggestions request: userId={}", userId);

        Exception lastException = null;
        for (int attempt = 0; attempt <= MAX_RETRIES; attempt++) {
            try {
                if (attempt > 0) {
                    long delayMs = attempt * 2000L;
                    log.info("AI WeeklySuggestions 第{}次重试，等待{}ms...", attempt, delayMs);
                    Thread.sleep(delayMs);
                }
                return doGenerateWeeklySuggestions(systemPrompt, userPrompt);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                lastException = e;
                break;
            } catch (Exception e) {
                lastException = e;
                if (attempt < MAX_RETRIES) {
                    log.warn("AI WeeklySuggestions 第{}次尝试失败，将重试: {}", attempt + 1, e.getMessage());
                }
            }
        }

        log.warn("AI WeeklySuggestions failed after {} attempts, using fallback", MAX_RETRIES + 1, lastException);
        return List.of(
                "AI 建议服务暂时不可用，请稍后再试。",
                "以下是基于数据的自动建议：本周请继续保持三餐规律记录。",
                "建议关注蛋白质与蔬菜摄入的均衡性。"
        );
    }

    private List<String> doGenerateWeeklySuggestions(String systemPrompt, String userPrompt) {
        String response = callAiApi(systemPrompt, userPrompt);
        String json = extractJson(response);
        log.debug("AI WeeklySuggestions JSON: {}", json);

        try {
            List<String> suggestions = objectMapper.readValue(json, new TypeReference<List<String>>() {});
            if (suggestions != null && !suggestions.isEmpty()) {
                return suggestions;
            }
        } catch (JsonProcessingException ignored) {}

        try {
            Map<String, Object> raw = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
            @SuppressWarnings("unchecked")
            List<String> suggestions = (List<String>) raw.get("suggestions");
            if (suggestions != null && !suggestions.isEmpty()) {
                return suggestions;
            }
        } catch (JsonProcessingException ignored) {}

        return parseTextSuggestions(response);
    }

    // ---- Internal methods ----

    private String callAiApi(String systemPrompt, String userPrompt) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(15000);
        factory.setReadTimeout(90000);

        RestClient client = RestClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Authorization", "Bearer " + apiKey)
                .defaultHeader("Content-Type", "application/json")
                .requestFactory(factory)
                .build();

        Map<String, Object> requestBody = Map.of(
                "model", model,
                "messages", List.of(
                        Map.of("role", "system", "content", systemPrompt),
                        Map.of("role", "user", "content", userPrompt)
                ),
                "temperature", 0.7,
                "max_tokens", 16384,
                "stream", false
        );

        Map<String, Object> responseMap = client.post()
                .uri("/v1/chat/completions")
                .body(requestBody)
                .retrieve()
                .body(Map.class);

        if (responseMap == null) {
            throw new RuntimeException("AI 服务返回空响应");
        }

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> choices = (List<Map<String, Object>>) responseMap.get("choices");
        if (choices == null || choices.isEmpty()) {
            throw new RuntimeException("AI 服务未返回有效 choices: " + responseMap);
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
        Object content = message.get("content");
        if (content == null || content.toString().isBlank()) {
            Object finishReason = choices.get(0).get("finish_reason");
            String reason = finishReason != null ? finishReason.toString() : "unknown";
            log.warn("AI 服务返回空 content, finish_reason={}, choices={}", reason, choices);
            throw new RuntimeException("AI 服务返回空内容（finish_reason=" + reason + "），可能是模型推理超限或频率限制，请稍后重试");
        }

        return content.toString();
    }

    private String extractJson(String raw) {
        raw = raw.trim();

        // Strip think tags from DeepSeek-R1 reasoning
        raw = raw.replaceAll("(?s)<think>.*?</think>", "").trim();

        // Remove markdown code block markers
        if (raw.startsWith("```json")) {
            raw = raw.substring(7);
        } else if (raw.startsWith("```")) {
            raw = raw.substring(3);
        }
        if (raw.endsWith("```")) {
            raw = raw.substring(0, raw.length() - 3);
        }
        raw = raw.trim();

        // Find JSON object start/end
        int start = raw.indexOf('{');
        int end = raw.lastIndexOf('}');
        if (start >= 0 && end > start) {
            raw = raw.substring(start, end + 1);
        } else {
            // Try JSON array
            start = raw.indexOf('[');
            end = raw.lastIndexOf(']');
            if (start >= 0 && end > start) {
                raw = raw.substring(start, end + 1);
            }
        }

        return raw;
    }

    @SuppressWarnings("unchecked")
    private List<AiRecipe> parseRecipeList(Map<String, Object> raw, String key) {
        Object obj = raw.get(key);
        if (!(obj instanceof List)) {
            return List.of();
        }
        List<Map<String, Object>> list = (List<Map<String, Object>>) obj;
        List<AiRecipe> recipes = new ArrayList<>();
        for (Map<String, Object> item : list) {
            try {
                recipes.add(new AiRecipe(
                        getString(item, "name"),
                        getInt(item, "calories", 0),
                        getInt(item, "proteinGram", "protein", 0),
                        getInt(item, "fatGram", "fat", 0),
                        getInt(item, "carbohydrateGram", "carbohydrate", "carbs", 0),
                        parseStringList(item, "ingredients"),
                        parseStringList(item, "steps"),
                        getString(item, "difficulty"),
                        getString(item, "cookTime")
                ));
            } catch (Exception e) {
                log.warn("Failed to parse recipe item in {}: {}", key, e.getMessage());
            }
        }
        return recipes;
    }

    @SuppressWarnings("unchecked")
    private List<String> parseStringList(Map<String, Object> raw, String key) {
        Object obj = raw.get(key);
        if (obj instanceof List) {
            List<String> result = new ArrayList<>();
            for (Object item : (List<Object>) obj) {
                if (item != null) {
                    result.add(item.toString());
                }
            }
            return result;
        }
        if (obj instanceof String) {
            return List.of(((String) obj).split("[；;，,\n]"));
        }
        return List.of();
    }

    private String getString(Map<String, Object> map, String key) {
        Object val = map.get(key);
        return val == null ? "" : val.toString();
    }

    private int getInt(Map<String, Object> map, String key, int defaultValue) {
        Object val = map.get(key);
        if (val instanceof Number) {
            return ((Number) val).intValue();
        }
        if (val instanceof String) {
            return parseInt((String) val);
        }
        return defaultValue;
    }

    private int getInt(Map<String, Object> map, String key, String altKey, int defaultValue) {
        int val = getInt(map, key, -1);
        if (val >= 0) {
            return val;
        }
        return getInt(map, altKey, defaultValue);
    }

    private int getInt(Map<String, Object> map, String key, String altKey1, String altKey2, int defaultValue) {
        int val = getInt(map, key, -1);
        if (val >= 0) {
            return val;
        }
        val = getInt(map, altKey1, -1);
        if (val >= 0) {
            return val;
        }
        return getInt(map, altKey2, defaultValue);
    }

    private int parseInt(String s) {
        Matcher m = Pattern.compile("\\d+").matcher(s);
        if (m.find()) {
            return Integer.parseInt(m.group());
        }
        return 0;
    }

    private List<String> parseTextSuggestions(String response) {
        List<String> suggestions = new ArrayList<>();
        String[] lines = response.split("\\n");
        for (String line : lines) {
            line = line.trim()
                    .replaceAll("^[\\d一二三四五六七]+[、．.。)）\\s\\-:：]+", "")
                    .replaceAll("^[-•*\\s]+", "")
                    .trim();
            if (line.length() > 5 && line.length() < 200) {
                suggestions.add(line);
            }
        }
        return suggestions.isEmpty()
                ? List.of("请保持规律饮食记录，以便 AI 为你提供更精准的周报分析。")
                : suggestions;
    }

    // ---- Prompt builders ----

    private String buildMealSystemPrompt() {
        return """
                你是一位拥有20年经验的资深注册营养师和健康餐食规划专家。
                你的任务是根据用户提供的健康档案信息，生成一份个性化的一日三餐及加餐方案。

                ## 输出格式要求（严格遵守）
                请只返回一个合法的JSON对象，不要包含任何markdown标记或其他文字。JSON结构如下：
                {
                  "breakfast": [
                    {
                      "name": "菜品名称",
                      "calories": 350,
                      "proteinGram": 25,
                      "fatGram": 10,
                      "carbohydrateGram": 40,
                      "ingredients": ["食材1", "食材2"],
                      "steps": ["步骤1", "步骤2"],
                      "difficulty": "简单/中等/复杂",
                      "cookTime": "15分钟"
                    }
                  ],
                  "lunch": [...],
                  "dinner": [...],
                  "snack": [...],
                  "totalCalories": 1800,
                  "totalProtein": 100,
                  "totalFat": 50,
                  "totalCarbs": 200,
                  "notes": ["备注1", "备注2", "备注3"]
                }

                ## 设计原则
                1. 每一餐通常返回1个主菜食谱，加餐1个。
                2. 热量严格按照用户的每日目标分配，早餐约占25-30%，午餐35-40%，晚餐25-30%，加餐5-10%。
                3. 必须避开用户标注的所有饮食禁忌食材。
                4. 优先考虑用户的口味偏好（清淡、辣味等）。
                5. 根据用户目标调整：
                   - 减脂：高蛋白、低脂、低GI碳水，多蔬菜
                   - 增肌：高蛋白、充足碳水、适量优质脂肪
                   - 控糖：低GI主食、高膳食纤维、避免精制糖
                   - 控压：低钠、高钾、多果蔬全谷物
                   - 均衡：三大营养素按4:3:3比例分配
                6. 根据慢性病情况做针对性调整（如糖尿病避开高GI，高血压低盐）。
                7. 食材应是中国家庭常见、易购的食材。
                8. 制作步骤简明扼要，每步20字以内，3-5步即可。
                9. cookTime为预估的烹饪时间。
                10. 方案要有多样性，如果提示"换一批"则生成完全不同内容的食谱。
                """;
    }

    private String buildMealUserPrompt(HealthProfile profile, HealthAssessment assessment, int refreshIndex) {
        StringBuilder sb = new StringBuilder();
        sb.append("请根据以下用户信息生成个性化三餐方案：\n\n");

        sb.append("## 基本信息\n");
        sb.append("- 年龄：").append(profile.age()).append("岁\n");
        sb.append("- 性别：").append(profile.gender().name()).append("\n");
        sb.append("- 身高：").append(profile.heightCm()).append("cm\n");
        sb.append("- 体重：").append(profile.weightKg()).append("kg\n");
        sb.append("- BMI：").append(String.format("%.1f", assessment.bmi())).append("（").append(assessment.bmiLevel()).append("）\n");

        String goalDesc = switch (profile.goal()) {
            case FAT_LOSS -> "减脂";
            case MUSCLE_GAIN -> "增肌";
            case BLOOD_SUGAR_CONTROL -> "控糖";
            case BLOOD_PRESSURE_CONTROL -> "控压";
            case BALANCED -> "均衡饮食";
        };
        sb.append("- 目标：").append(goalDesc).append("\n");

        sb.append("\n## 营养目标\n");
        sb.append("- 每日推荐热量：").append(assessment.target().dailyCalories()).append("kcal\n");
        sb.append("- 蛋白质：").append(assessment.target().proteinGram()).append("g\n");
        sb.append("- 脂肪：").append(assessment.target().fatGram()).append("g\n");
        sb.append("- 碳水：").append(assessment.target().carbohydrateGram()).append("g\n");
        sb.append("- 宏观比例：").append(assessment.target().macroRatio()).append("\n");

        if (!profile.chronicConditions().isEmpty()) {
            sb.append("\n## 慢性病情况\n");
            for (String cond : profile.chronicConditions()) {
                sb.append("- ").append(cond).append("\n");
            }
        }

        if (!profile.taboos().isEmpty()) {
            sb.append("\n## 饮食禁忌（必须避开）\n");
            for (String taboo : profile.taboos()) {
                sb.append("- ").append(taboo).append("\n");
            }
        }

        if (!profile.tastePreferences().isEmpty()) {
            sb.append("\n## 口味偏好\n");
            for (String taste : profile.tastePreferences()) {
                sb.append("- ").append(taste).append("\n");
            }
        }

        if (refreshIndex > 0) {
            sb.append("\n## 重要\n");
            sb.append("这是第").append(refreshIndex + 1).append("次生成方案，请确保与之前的完全不同，给出全新的食谱组合。\n");
        }

        sb.append("\n请严格按照JSON格式返回结果。");
        return sb.toString();
    }

    private String buildDailySystemPrompt() {
        return """
                你是一位拥有20年经验的资深注册营养师。
                你的任务是根据用户某一天的饮食记录，给出3-5条具体、实用的分析和改善建议。

                ## 输出格式要求
                请只返回一个JSON字符串数组，只包含分析建议文本。每条约30-60字，简洁实用。
                格式示例：
                ["建议1内容", "建议2内容", "建议3内容"]

                ## 分析原则
                1. 先总结当日总热量与目标对比，再逐项分析蛋白质、脂肪、碳水。
                2. 检查餐次是否完整（早餐、午餐、晚餐），缺失餐次要提醒。
                3. 具体可执行，不说空话（如"多吃蔬菜"改为"建议午餐增加一份深色蔬菜如西兰花"）。
                4. 结合中国饮食习惯给出建议。
                5. 语气温和鼓励，不要指责。
                6. 如果当天无记录，返回一条鼓励用户开始记录的建议。
                """;
    }

    private String buildDailyUserPrompt(List<DietRecord> dayRecords,
                                         int targetCalories, int targetProtein, int targetFat, int targetCarbs) {
        StringBuilder sb = new StringBuilder();
        sb.append("请根据以下用户单日饮食记录，给出分析和改善建议：\n\n");

        sb.append("## 营养目标\n");
        sb.append("- 热量：").append(targetCalories).append("kcal\n");
        sb.append("- 蛋白质：").append(targetProtein).append("g\n");
        sb.append("- 脂肪：").append(targetFat).append("g\n");
        sb.append("- 碳水：").append(targetCarbs).append("g\n");

        if (dayRecords.isEmpty()) {
            sb.append("\n## 当日记录\n");
            sb.append("当天暂无饮食记录。\n");
        } else {
            sb.append("\n## 当日记录（").append(dayRecords.size()).append("条）\n");
            int totalCal = 0, totalProt = 0, totalFat = 0, totalCarb = 0;
            for (DietRecord r : dayRecords) {
                String mealName = switch (r.mealType()) {
                    case BREAKFAST -> "早餐";
                    case LUNCH -> "午餐";
                    case DINNER -> "晚餐";
                    case SNACK -> "加餐";
                };
                sb.append("- ").append(mealName).append("：").append(r.foodName())
                        .append("，").append(r.calories()).append("kcal")
                        .append("（蛋白").append(r.proteinGram()).append("g/脂肪").append(r.fatGram())
                        .append("g/碳水").append(r.carbohydrateGram()).append("g）\n");
                totalCal += r.calories();
                totalProt += r.proteinGram();
                totalFat += r.fatGram();
                totalCarb += r.carbohydrateGram();
            }
            sb.append("\n## 当日合计\n");
            sb.append("- 总热量：").append(totalCal).append("kcal（目标").append(targetCalories).append("kcal，")
                    .append(Math.round(totalCal * 100.0 / targetCalories)).append("%）\n");
            sb.append("- 总蛋白质：").append(totalProt).append("g（目标").append(targetProtein).append("g）\n");
            sb.append("- 总脂肪：").append(totalFat).append("g（目标").append(targetFat).append("g）\n");
            sb.append("- 总碳水：").append(totalCarb).append("g（目标").append(targetCarbs).append("g）\n");
        }

        sb.append("\n请只返回JSON格式的建议数组。");
        return sb.toString();
    }

    private List<String> buildLocalDailyAnalysis(List<DietRecord> dayRecords,
                                                  int targetCalories, int targetProtein, int targetFat, int targetCarbs) {
        List<String> results = new ArrayList<>();
        if (dayRecords.isEmpty()) {
            results.add("当天暂无饮食记录，请先添加记录后再进行分析。");
            return results;
        }

        int totalCal = dayRecords.stream().mapToInt(DietRecord::calories).sum();
        int totalProt = dayRecords.stream().mapToInt(DietRecord::proteinGram).sum();
        int totalFat = dayRecords.stream().mapToInt(DietRecord::fatGram).sum();
        int totalCarb = dayRecords.stream().mapToInt(DietRecord::carbohydrateGram).sum();
        boolean hasBreakfast = dayRecords.stream().anyMatch(r -> r.mealType() == MealType.BREAKFAST);
        boolean hasLunch = dayRecords.stream().anyMatch(r -> r.mealType() == MealType.LUNCH);
        boolean hasDinner = dayRecords.stream().anyMatch(r -> r.mealType() == MealType.DINNER);

        int calPercent = Math.round(totalCal * 100f / targetCalories);
        results.add("当日共记录 " + dayRecords.size() + " 条饮食数据，总摄入 " + totalCal + " kcal（目标 " + targetCalories + " kcal）。");

        if (calPercent < 80) {
            results.add("热量摄入偏低（" + calPercent + "%），建议适当增加主食和优质蛋白的摄入。");
        } else if (calPercent > 110) {
            results.add("热量摄入偏高（" + calPercent + "%），建议控制油脂和精制碳水的摄入。");
        } else {
            results.add("热量摄入接近目标（" + calPercent + "%），整体控制良好。");
        }

        int protPercent = Math.round(totalProt * 100f / targetProtein);
        if (protPercent < 70) {
            results.add("蛋白质摄入不足（" + protPercent + "%），建议每餐搭配瘦肉、鱼虾、鸡蛋或豆制品。");
        } else {
            results.add("蛋白质摄入达标（" + protPercent + "%）。");
        }

        if (!hasBreakfast) {
            results.add("缺少早餐记录，早餐是一天能量的起点，建议保持规律早餐习惯。");
        }
        if (!hasLunch) {
            results.add("缺少午餐记录，午餐建议搭配主食+蛋白+蔬菜。");
        }
        if (!hasDinner) {
            results.add("缺少晚餐记录，晚餐建议清淡为主，避免高油高盐。");
        }

        if (totalCarb < targetCarbs * 0.7) {
            results.add("碳水摄入偏低，可适当增加全谷物、薯类等优质碳水来源。");
        }
        if (totalFat > targetFat * 1.2) {
            results.add("脂肪摄入偏高，建议减少油炸食品，选择蒸煮等烹饪方式。");
        }

        results.add("（以上为本地分析结果，AI 实时分析暂时不可用，请稍后重试）");
        return results;
    }

    private String buildWeeklySystemPrompt() {
        return """
                你是一位经验丰富的健康管理师和营养顾问。
                你的任务是根据用户提供的本周饮食报告数据，给出3-5条具体、实用的改善建议。

                ## 输出格式要求
                请返回一个JSON字符串数组，只包含建议文本。每条约30-60字，简洁实用。
                格式示例：
                ["建议1内容", "建议2内容", "建议3内容"]

                ## 建议原则
                1. 具体可执行，不说空话（如"多运动"改为"建议每天快走30分钟"）。
                2. 基于数据说话，引用具体的完成率和趋势。
                3. 关注热量、蛋白质、脂肪、碳水四维度的达标情況。
                4. 关注餐次是否规律（早餐、午餐、晚餐、加餐）。
                5. 给出饮食结构调整的方向（增减哪类食物）。
                6. 语气温和鼓励，不要指责。
                7. 结合中国饮食习惯给出建议。
                """;
    }

    private String buildWeeklyUserPrompt(WeeklyReport report) {
        StringBuilder sb = new StringBuilder();
        sb.append("请根据以下用户本周饮食数据，给出改善建议：\n\n");

        sb.append("## 本周概览\n");
        sb.append("- 日均热量摄入：").append(report.averageCalories()).append("kcal\n");
        sb.append("- 记录天数：").append(report.recordDays()).append("/7天\n");
        sb.append("- 完成度评级：").append(report.completionLevel()).append("\n");
        sb.append("- 热量完成率：").append(report.calorieCompletionRate()).append("%\n");
        sb.append("- 蛋白质完成率：").append(report.proteinCompletionRate()).append("%\n");
        sb.append("- 脂肪完成率：").append(report.fatCompletionRate()).append("%\n");
        sb.append("- 碳水完成率：").append(report.carbCompletionRate()).append("%\n");
        sb.append("- 记录日占比：").append(report.recordDayRate()).append("%\n");

        sb.append("\n## 餐次分布\n");
        sb.append("- 早餐记录：").append(report.breakfastCount()).append("次\n");
        sb.append("- 午餐记录：").append(report.lunchCount()).append("次\n");
        sb.append("- 晚餐记录：").append(report.dinnerCount()).append("次\n");
        sb.append("- 加餐记录：").append(report.snackCount()).append("次\n");

        sb.append("\n## 趋势\n");
        sb.append("- 周间热量变化：").append(report.weekOverWeekCalorieChange()).append("kcal\n");
        sb.append("- 趋势方向：").append(report.weekOverWeekTrend()).append("\n");

        sb.append("\n请只返回JSON格式的建议数组。");
        return sb.toString();
    }
}
