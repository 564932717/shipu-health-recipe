package com.xd.healthrecipe.service;

import com.xd.healthrecipe.domain.Gender;
import com.xd.healthrecipe.domain.HealthGoal;
import com.xd.healthrecipe.domain.HealthProfile;
import com.xd.healthrecipe.domain.UserAccount;
import com.xd.healthrecipe.dto.ChangePasswordRequest;
import com.xd.healthrecipe.dto.LoginRequest;
import com.xd.healthrecipe.dto.RegisterRequest;
import com.xd.healthrecipe.dto.UserSession;
import com.xd.healthrecipe.repository.ProfileRepository;
import com.xd.healthrecipe.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class UserService {
    private final UserRepository userRepository;
    private final ProfileRepository profileRepository;

    public UserService(UserRepository userRepository, ProfileRepository profileRepository) {
        this.userRepository = userRepository;
        this.profileRepository = profileRepository;
    }

    public UserSession register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.username())) {
            throw new IllegalArgumentException("用户名已存在");
        }
        String id = UUID.randomUUID().toString();
        UserAccount account = new UserAccount(id, request.username(), request.password(),
                request.displayName() == null || request.displayName().isBlank() ? request.username() : request.displayName(),
                LocalDateTime.now());
        userRepository.save(account);
        profileRepository.save(defaultProfile(account.id()));
        return new UserSession(account.id(), account.username(), account.displayName());
    }

    public UserSession login(LoginRequest request) {
        UserAccount account = userRepository.findByUsername(request.username())
                .orElseThrow(() -> new IllegalArgumentException("该用户还未在系统内注册，请先注册"));
        if (!account.password().equals(request.password())) {
            throw new IllegalArgumentException("密码错误，请重新输入");
        }
        return new UserSession(account.id(), account.username(), account.displayName());
    }

    public void changePassword(ChangePasswordRequest request) {
        if (!request.newPassword().equals(request.confirmPassword())) {
            throw new IllegalArgumentException("New password confirmation does not match");
        }
        if (request.newPassword().length() < 6) {
            throw new IllegalArgumentException("New password must be at least 6 characters");
        }
        UserAccount account = userRepository.findById(request.userId())
                .orElseThrow(() -> new IllegalArgumentException("User does not exist"));
        if (!account.password().equals(request.oldPassword())) {
            throw new IllegalArgumentException("Old password is incorrect");
        }
        userRepository.updatePassword(account.id(), request.newPassword());
    }

    private HealthProfile defaultProfile(String userId) {
        return new HealthProfile(
                userId,
                22,
                Gender.UNKNOWN,
                170,
                65,
                HealthGoal.BALANCED,
                List.of(),
                List.of(),
                List.of("清淡")
        );
    }
}
