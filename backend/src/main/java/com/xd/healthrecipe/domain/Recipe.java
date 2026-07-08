package com.xd.healthrecipe.domain;

import java.util.List;
import java.util.Set;

public record Recipe(
        String id,
        String name,
        MealType mealType,
        String category,
        Set<HealthGoal> suitableGoals,
        List<String> tags,
        List<String> ingredients,
        List<String> steps,
        int calories,
        int proteinGram,
        int fatGram,
        int carbohydrateGram
) {
    public boolean matchesGoal(HealthGoal goal) {
        return suitableGoals.contains(goal) || suitableGoals.contains(HealthGoal.BALANCED);
    }

    public boolean containsAny(List<String> words) {
        if (words == null || words.isEmpty()) {
            return false;
        }
        String source = (name + " " + category + " " + tags + " " + ingredients).toLowerCase();
        return words.stream()
                .filter(word -> word != null && !word.isBlank())
                .map(String::toLowerCase)
                .anyMatch(source::contains);
    }
}
