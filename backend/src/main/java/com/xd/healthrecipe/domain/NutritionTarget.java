package com.xd.healthrecipe.domain;

public record NutritionTarget(
        int dailyCalories,
        int proteinGram,
        int fatGram,
        int carbohydrateGram,
        String macroRatio
) {
}
