package com.xd.healthrecipe.domain;

import java.util.List;

public record AiRecipe(
        String name,
        int calories,
        int proteinGram,
        int fatGram,
        int carbohydrateGram,
        List<String> ingredients,
        List<String> steps,
        String difficulty,
        String cookTime
) {
}
