package com.xd.healthrecipe.service;

import com.xd.healthrecipe.domain.Gender;
import com.xd.healthrecipe.domain.HealthAssessment;
import com.xd.healthrecipe.domain.HealthGoal;
import com.xd.healthrecipe.domain.HealthProfile;
import com.xd.healthrecipe.domain.NutritionTarget;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class HealthAssessmentService {
    public HealthAssessment evaluate(HealthProfile profile) {
        validate(profile);
        double bmi = round(profile.weightKg() / Math.pow(profile.heightCm() / 100.0, 2));
        int calories = estimateCalories(profile);
        NutritionTarget target = buildTarget(profile, calories);
        List<String> advices = buildAdvices(profile, bmi, target);
        return new HealthAssessment(bmi, bmiLevel(bmi), target, advices);
    }

    private void validate(HealthProfile profile) {
        if (profile == null) {
            throw new IllegalArgumentException("健康档案不能为空");
        }
        if (profile.age() <= 0 || profile.heightCm() <= 0 || profile.weightKg() <= 0) {
            throw new IllegalArgumentException("年龄、身高、体重必须大于 0");
        }
    }

    private int estimateCalories(HealthProfile profile) {
        double base;
        if (profile.gender() == Gender.FEMALE) {
            base = 10 * profile.weightKg() + 6.25 * profile.heightCm() - 5 * profile.age() - 161;
        } else {
            base = 10 * profile.weightKg() + 6.25 * profile.heightCm() - 5 * profile.age() + 5;
        }

        double maintenance = base * 1.35;
        HealthGoal goal = profile.goal() == null ? HealthGoal.BALANCED : profile.goal();
        return switch (goal) {
            case FAT_LOSS -> (int) Math.max(1200, maintenance - 400);
            case MUSCLE_GAIN -> (int) (maintenance + 300);
            case BLOOD_SUGAR_CONTROL, BLOOD_PRESSURE_CONTROL -> (int) Math.max(1300, maintenance - 150);
            case BALANCED -> (int) maintenance;
        };
    }

    private NutritionTarget buildTarget(HealthProfile profile, int calories) {
        HealthGoal goal = profile.goal() == null ? HealthGoal.BALANCED : profile.goal();
        double proteinFactor = goal == HealthGoal.MUSCLE_GAIN ? 1.8 : 1.4;
        int proteinGram = (int) Math.round(profile.weightKg() * proteinFactor);
        double fatRatio = goal == HealthGoal.BLOOD_SUGAR_CONTROL ? 0.30 : 0.25;
        int fatGram = (int) Math.round(calories * fatRatio / 9);
        int carbohydrateGram = Math.max(0, (calories - proteinGram * 4 - fatGram * 9) / 4);
        String ratio = proteinGram + "g 蛋白质 / " + fatGram + "g 脂肪 / " + carbohydrateGram + "g 碳水";
        return new NutritionTarget(calories, proteinGram, fatGram, carbohydrateGram, ratio);
    }

    private List<String> buildAdvices(HealthProfile profile, double bmi, NutritionTarget target) {
        List<String> advices = new ArrayList<>();
        if (bmi >= 24) {
            advices.add("BMI 偏高，建议优先选择高蛋白、低油脂、低糖食谱。");
        } else if (bmi < 18.5) {
            advices.add("BMI 偏低，建议适当增加优质蛋白和复合碳水摄入。");
        } else {
            advices.add("BMI 处于正常范围，可保持均衡饮食并稳定运动。");
        }

        if (profile.goal() == HealthGoal.BLOOD_SUGAR_CONTROL) {
            advices.add("控糖目标下建议减少精制碳水，优先选择全谷物和高纤维食材。");
        }
        if (profile.goal() == HealthGoal.BLOOD_PRESSURE_CONTROL) {
            advices.add("控压目标下建议减少高盐加工食品，增加富含钾和膳食纤维的食材。");
        }
        if (!profile.taboos().isEmpty()) {
            advices.add("推荐食谱已尽量过滤忌口：" + String.join("、", profile.taboos()));
        }
        advices.add("每日推荐热量约为 " + target.dailyCalories() + " 千卡，建议分配到三餐与加餐。");
        return advices;
    }

    private String bmiLevel(double bmi) {
        if (bmi < 18.5) {
            return "偏瘦";
        }
        if (bmi < 24) {
            return "正常";
        }
        if (bmi < 28) {
            return "超重";
        }
        return "肥胖";
    }

    private double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }
}
