package com.xd.healthrecipe.domain;

import java.util.List;

public record HealthProfile(
        String userId,
        int age,
        Gender gender,
        double heightCm,
        double weightKg,
        HealthGoal goal,
        List<String> chronicConditions,
        List<String> taboos,
        List<String> tastePreferences
) {
    public List<String> chronicConditions() {
        return chronicConditions == null ? List.of() : chronicConditions;
    }

    public List<String> taboos() {
        return taboos == null ? List.of() : taboos;
    }

    public List<String> tastePreferences() {
        return tastePreferences == null ? List.of() : tastePreferences;
    }
}
