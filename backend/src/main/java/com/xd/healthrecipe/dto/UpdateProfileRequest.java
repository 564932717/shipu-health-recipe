package com.xd.healthrecipe.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateProfileRequest(
        @NotBlank String userId,
        String displayName
) {
}
