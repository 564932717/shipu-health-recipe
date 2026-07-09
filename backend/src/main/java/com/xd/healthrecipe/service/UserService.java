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
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class UserService {
    private final UserRepository userRepository;
    private final ProfileRepository profileRepository;

    public UserService(UserRepository userRepository, ProfileRepository profileRepository) {
        this.userRepository = userRepository;
        this.profileRepository = profileRepository;
    }

    @Transactional
    public UserSession register(RegisterRequest request) {
        String username = request.username().trim();
        if (userRepository.existsByUsername(username)) {
            throw new IllegalArgumentException("用户名已存在");
        }
        String displayName = request.displayName() == null || request.displayName().isBlank()
                ? username
                : request.displayName().trim();
        UserAccount account = new UserAccount(username, username, request.password(), displayName, LocalDateTime.now());
        userRepository.save(account);
        profileRepository.save(defaultProfile(account.id()));
        return new UserSession(account.id(), account.username(), account.displayName());
    }

    @Transactional
    public UserSession login(LoginRequest request) {
        String username = request.username().trim();
        UserAccount account = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("该用户还未在系统内注册，请先注册"));
        if (!account.password().equals(request.password())) {
            throw new IllegalArgumentException("密码错误，请重新输入");
        }
        account = ensureUsernameAsUserId(account);
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
                0,
                Gender.UNKNOWN,
                0,
                0,
                HealthGoal.BALANCED,
                List.of(),
                List.of(),
                List.of()
        );
    }

    private UserAccount ensureUsernameAsUserId(UserAccount account) {
        if (account.id().equals(account.username())) {
            return account;
        }
        userRepository.migrateUserIdToUsername(account.id(), account.username());
        return new UserAccount(
                account.username(),
                account.username(),
                account.password(),
                account.displayName(),
                account.createdAt()
        );
    }
}
