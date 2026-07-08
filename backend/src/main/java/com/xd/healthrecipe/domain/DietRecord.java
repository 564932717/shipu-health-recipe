package com.xd.healthrecipe.domain;

import java.time.LocalDateTime;

public record DietRecord(
        String id,
        String userId,
        String foodName,
        MealType mealType,
        int calories,
        int proteinGram,
        int fatGram,
        int carbohydrateGram,
        LocalDateTime eatenAt
) {
}
