package com.xd.healthrecipe.domain;

import java.util.List;

public record AiMealPlan(
        List<AiRecipe> breakfast,
        List<AiRecipe> lunch,
        List<AiRecipe> dinner,
        List<AiRecipe> snack,
        NutritionTarget estimatedIntake,
        List<String> notes
) {
}
