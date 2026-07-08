package com.xd.healthrecipe.domain;

import java.util.List;

public record NutritionSummary(
        String userId,
        int totalCalories,
        int totalProteinGram,
        int totalFatGram,
        int totalCarbohydrateGram,
        double calorieCompletion,
        List<String> suggestions
) {
}
