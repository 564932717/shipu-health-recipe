package com.xd.healthrecipe.web;

import com.xd.healthrecipe.domain.HealthProfile;
import com.xd.healthrecipe.dto.ApiResponse;
import com.xd.healthrecipe.service.ProfileService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/profiles")
public class ProfileController {
    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping
    public ApiResponse<List<HealthProfile>> all() {
        return ApiResponse.ok(profileService.all());
    }

    @GetMapping("/{userId}")
    public ApiResponse<HealthProfile> get(@PathVariable String userId) {
        HealthProfile profile = profileService.find(userId)
                .orElseThrow(() -> new IllegalArgumentException("健康档案不存在"));
        return ApiResponse.ok(profile);
    }

    @PostMapping
    public ApiResponse<HealthProfile> save(@RequestBody HealthProfile profile) {
        return ApiResponse.ok(profileService.save(profile));
    }
}
