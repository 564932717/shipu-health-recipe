package com.xd.healthrecipe.dto;

import com.xd.healthrecipe.domain.Recipe;

import java.util.List;

public record RecipePage(List<Recipe> data, int total, int page, int size, int totalPages) {
}
