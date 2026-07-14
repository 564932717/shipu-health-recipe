package com.xd.healthrecipe.web;

import com.xd.healthrecipe.domain.WeeklyReport;
import com.xd.healthrecipe.dto.ApiResponse;
import com.xd.healthrecipe.service.ReportService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/reports")
public class ReportController {
    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @GetMapping("/week")
    public ApiResponse<WeeklyReport> week(
            @RequestParam String userId,
            @RequestParam(defaultValue = "1800") int targetCalories,
            @RequestParam(required = false) String date
    ) {
        return ApiResponse.ok(reportService.weeklyReport(userId, targetCalories, date));
    }
}
