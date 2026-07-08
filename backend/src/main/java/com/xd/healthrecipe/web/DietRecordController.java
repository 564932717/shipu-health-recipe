package com.xd.healthrecipe.web;

import com.xd.healthrecipe.domain.DietRecord;
import com.xd.healthrecipe.domain.NutritionSummary;
import com.xd.healthrecipe.dto.ApiResponse;
import com.xd.healthrecipe.dto.DietRecordRequest;
import com.xd.healthrecipe.service.DietRecordService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/diet-records")
public class DietRecordController {
    private final DietRecordService dietRecordService;

    public DietRecordController(DietRecordService dietRecordService) {
        this.dietRecordService = dietRecordService;
    }

    @PostMapping
    public ApiResponse<DietRecord> add(@Valid @RequestBody DietRecordRequest request) {
        return ApiResponse.ok(dietRecordService.add(request));
    }

    @GetMapping
    public ApiResponse<List<DietRecord>> list(@RequestParam String userId) {
        return ApiResponse.ok(dietRecordService.listByUser(userId));
    }

    @GetMapping("/summary")
    public ApiResponse<NutritionSummary> summary(
            @RequestParam String userId,
            @RequestParam(defaultValue = "1800") int targetCalories
    ) {
        return ApiResponse.ok(dietRecordService.dailySummary(userId, targetCalories));
    }
}
