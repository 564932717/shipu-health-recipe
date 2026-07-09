package com.xd.healthrecipe.service;

import com.xd.healthrecipe.domain.HealthProfile;
import com.xd.healthrecipe.repository.ProfileRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ProfileService {
    public static final String DEMO_USER_ID = "demo";

    private final ProfileRepository profileRepository;

    public ProfileService(ProfileRepository profileRepository) {
        this.profileRepository = profileRepository;
    }

    public HealthProfile save(HealthProfile profile) {
        if (profile.userId() == null || profile.userId().isBlank()) {
            throw new IllegalArgumentException("用户 ID 不能为空");
        }
        return profileRepository.save(profile);
    }

    public Optional<HealthProfile> find(String userId) {
        return profileRepository.find(userId);
    }

    public List<HealthProfile> all() {
        return profileRepository.all();
    }
}
