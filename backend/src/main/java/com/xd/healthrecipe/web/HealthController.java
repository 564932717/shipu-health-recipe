package com.xd.healthrecipe.web;

import com.xd.healthrecipe.domain.HealthAssessment;
import com.xd.healthrecipe.domain.HealthProfile;
import com.xd.healthrecipe.domain.MealPlan;
import com.xd.healthrecipe.dto.ApiResponse;
import com.xd.healthrecipe.service.HealthAssessmentService;
import com.xd.healthrecipe.service.RecommendationService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/health")
public class HealthController {
    private final HealthAssessmentService assessmentService;
    private final RecommendationService recommendationService;

    public HealthController(HealthAssessmentService assessmentService, RecommendationService recommendationService) {
        this.assessmentService = assessmentService;
        this.recommendationService = recommendationService;
    }

    @GetMapping("/ping")
    public ApiResponse<String> ping() {
        return ApiResponse.ok("health-recipe backend is running");
    }

    @PostMapping("/evaluate")
    public ApiResponse<HealthAssessment> evaluate(@RequestBody HealthProfile profile) {
        return ApiResponse.ok(assessmentService.evaluate(profile));
    }

    @PostMapping("/recommendations/day")
    public ApiResponse<MealPlan> recommend(@RequestBody HealthProfile profile) {
        return ApiResponse.ok(recommendationService.recommend(profile));
    }
}
