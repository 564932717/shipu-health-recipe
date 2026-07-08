package com.xd.healthrecipe.domain;

import java.time.LocalDateTime;

public record UserAccount(
        String id,
        String username,
        String password,
        String displayName,
        LocalDateTime createdAt
) {
}
