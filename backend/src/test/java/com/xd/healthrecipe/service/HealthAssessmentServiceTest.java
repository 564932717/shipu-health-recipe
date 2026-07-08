package com.xd.healthrecipe.service;

import com.xd.healthrecipe.domain.Gender;
import com.xd.healthrecipe.domain.HealthAssessment;
import com.xd.healthrecipe.domain.HealthGoal;
import com.xd.healthrecipe.domain.HealthProfile;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class HealthAssessmentServiceTest {
    private final HealthAssessmentService service = new HealthAssessmentService();

    @Test
    void evaluateReturnsBmiAndNutritionTarget() {
        HealthProfile profile = new HealthProfile(
                "u1", 22, Gender.MALE, 175, 72,
                HealthGoal.FAT_LOSS, List.of(), List.of("花生"), List.of("清淡")
        );

        HealthAssessment assessment = service.evaluate(profile);

        assertThat(assessment.bmi()).isEqualTo(23.5);
        assertThat(assessment.target().dailyCalories()).isPositive();
        assertThat(assessment.advices()).isNotEmpty();
    }
}
