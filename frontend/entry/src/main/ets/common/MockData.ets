import { AiMealPlan, AiRecipe, Gender, HealthGoal, HealthProfile, MealPlan, MealType, NutritionSummary, Recipe, WeeklyReport } from './Models';


export class MockData {
  static profile: HealthProfile = {
    userId: 'demo',
    age: 22,
    gender: Gender.MALE,
    heightCm: 175,
    weightKg: 72,
    goal: HealthGoal.FAT_LOSS,
    chronicConditions: [],
    taboos: [],
    tastePreferences: []
  };

  static mealPlan: MealPlan = {
    assessment: {
      bmi: 23.5,
      bmiLevel: '正常',
      target: {
        dailyCalories: 1875,
        proteinGram: 101,
        fatGram: 52,
        carbohydrateGram: 251,
        macroRatio: '蛋白质 101g / 脂肪 52g / 碳水 251g'
      },
      advices: [
        'BMI 处于正常范围，可保持均衡饮食并稳定运动。',
        '推荐食谱已过滤花生和高盐食材。',
        '每日推荐热量约为 1875 千卡。'
      ]
    },
    breakfast: [
      {
        id: 'B001',
        name: '燕麦鸡蛋牛奶早餐',
        mealType: MealType.BREAKFAST,
        category: '高蛋白早餐',
        tags: ['高蛋白', '低油', '快手'],
        ingredients: ['燕麦', '鸡蛋', '低脂牛奶', '蓝莓'],
        steps: ['燕麦加入低脂牛奶煮软', '鸡蛋水煮 8 分钟', '搭配少量蓝莓'],
        calories: 420,
        proteinGram: 28,
        fatGram: 12,
        carbohydrateGram: 48,
        difficulty: '简单',
        cookTime: '10分钟'
      }
    ],
    lunch: [
      {
        id: 'L001',
        name: '糙米鸡胸蔬菜碗',
        mealType: MealType.LUNCH,
        category: '减脂午餐',
        tags: ['低脂', '高纤维'],
        ingredients: ['糙米', '鸡胸肉', '西兰花', '胡萝卜'],
        steps: ['糙米提前浸泡后蒸熟', '鸡胸肉少油煎熟', '蔬菜焯水后装盘'],
        calories: 560,
        proteinGram: 42,
        fatGram: 14,
        carbohydrateGram: 66,
        difficulty: '中等',
        cookTime: '20分钟'
      }
    ],
    dinner: [
      {
        id: 'D002',
        name: '豆腐菌菇青菜汤',
        mealType: MealType.DINNER,
        category: '控糖晚餐',
        tags: ['低碳', '高纤维', '清淡'],
        ingredients: ['豆腐', '香菇', '青菜', '海带'],
        steps: ['菌菇煮出鲜味', '加入豆腐和青菜煮熟', '少盐调味'],
        calories: 310,
        proteinGram: 24,
        fatGram: 12,
        carbohydrateGram: 28,
        difficulty: '简单',
        cookTime: '15分钟'
      }
    ],
    snack: [
      {
        id: 'S001',
        name: '无糖酸奶坚果杯',
        mealType: MealType.SNACK,
        category: '健康加餐',
        tags: ['加餐', '高蛋白'],
        ingredients: ['无糖酸奶', '杏仁', '奇亚籽'],
        steps: ['酸奶倒入杯中', '撒入坚果和奇亚籽'],
        calories: 220,
        proteinGram: 14,
        fatGram: 12,
        carbohydrateGram: 16,
        difficulty: '简单',
        cookTime: '5分钟'
      }
    ],
    estimatedIntake: {
      dailyCalories: 1510,
      proteinGram: 108,
      fatGram: 50,
      carbohydrateGram: 158,
      macroRatio: '蛋白质 108g / 脂肪 50g / 碳水 158g'
    },
    notes: ['推荐结果会根据目标、忌口、食谱标签进行过滤。']
  };

  private static toAiRecipe(recipe: Recipe): AiRecipe {
    return {
      name: recipe.name,
      calories: recipe.calories,
      proteinGram: recipe.proteinGram,
      fatGram: recipe.fatGram,
      carbohydrateGram: recipe.carbohydrateGram,
      ingredients: recipe.ingredients,
      steps: recipe.steps,
      difficulty: recipe.difficulty,
      cookTime: recipe.cookTime
    };
  }

  static aiMealPlan: AiMealPlan = {
    breakfast: MockData.mealPlan.breakfast.map((item: Recipe) => MockData.toAiRecipe(item)),
    lunch: MockData.mealPlan.lunch.map((item: Recipe) => MockData.toAiRecipe(item)),
    dinner: MockData.mealPlan.dinner.map((item: Recipe) => MockData.toAiRecipe(item)),
    snack: MockData.mealPlan.snack.map((item: Recipe) => MockData.toAiRecipe(item)),
    estimatedIntake: MockData.mealPlan.estimatedIntake,
    notes: ['方案由 AI 根据你的健康档案与目标实时生成。', '如不满意可点击"换一换"重新生成。', '如有特殊过敏史请在忌口中标注。']
  };

  private static aiPlanVariant1: AiMealPlan = {
    breakfast: [{
      name: '燕麦鸡蛋牛奶早餐', calories: 420, proteinGram: 28, fatGram: 12, carbohydrateGram: 48,
      ingredients: ['燕麦 50g', '鸡蛋 1个', '牛奶 250ml', '蓝莓 30g'],
      steps: ['燕麦加牛奶煮 2 分钟', '水煮蛋 8 分钟', '搭配蓝莓食用'], difficulty: '简单', cookTime: '10分钟'
    }],
    lunch: [{
      name: '糙米鸡胸蔬菜碗', calories: 560, proteinGram: 42, fatGram: 14, carbohydrateGram: 66,
      ingredients: ['糙米 100g', '鸡胸肉 120g', '西兰花', '胡萝卜'],
      steps: ['糙米煮熟', '鸡胸肉煎熟切块', '蔬菜焯水拌入'], difficulty: '中等', cookTime: '25分钟'
    }],
    dinner: [{
      name: '豆腐菌菇青菜汤', calories: 310, proteinGram: 24, fatGram: 8, carbohydrateGram: 28,
      ingredients: ['嫩豆腐 200g', '菌菇 100g', '青菜 100g'],
      steps: ['菌菇炒软加水', '放入豆腐煮 5 分钟', '加入青菜煮 2 分钟'], difficulty: '简单', cookTime: '15分钟'
    }],
    snack: [{
      name: '无糖酸奶坚果杯', calories: 220, proteinGram: 14, fatGram: 8, carbohydrateGram: 16,
      ingredients: ['无糖酸奶 150g', '混合坚果 15g', '奇亚籽 5g'],
      steps: ['酸奶倒入杯中', '撒入坚果和奇亚籽'], difficulty: '简单', cookTime: '2分钟'
    }],
    estimatedIntake: { dailyCalories: 1510, proteinGram: 108, fatGram: 42, carbohydrateGram: 158,
      macroRatio: '蛋白质 108g / 脂肪 42g / 碳水 158g' },
    notes: ['当前为离线备用方案 1。', '连接后端后可体验 AI 实时推荐。']
  };

  private static aiPlanVariant2: AiMealPlan = {
    breakfast: [{
      name: '紫薯豆浆蒸蛋', calories: 390, proteinGram: 26, fatGram: 11, carbohydrateGram: 46,
      ingredients: ['紫薯 100g', '豆浆 250ml', '鸡蛋 1个'],
      steps: ['紫薯蒸熟', '鸡蛋加豆浆蒸 10 分钟', '搭配食用'], difficulty: '简单', cookTime: '15分钟'
    }],
    lunch: [{
      name: '三文鱼杂粮饭', calories: 580, proteinGram: 38, fatGram: 18, carbohydrateGram: 62,
      ingredients: ['三文鱼 120g', '杂粮饭 100g', '芦笋 100g'],
      steps: ['三文鱼煎熟', '杂粮饭蒸熟', '芦笋焯水'], difficulty: '中等', cookTime: '25分钟'
    }],
    dinner: [{
      name: '清蒸鲈鱼配杂粮', calories: 330, proteinGram: 30, fatGram: 10, carbohydrateGram: 30,
      ingredients: ['鲈鱼 150g', '杂粮 80g', '姜丝', '葱'],
      steps: ['鲈鱼加姜丝蒸 12 分钟', '杂粮煮熟', '淋上少量蒸鱼豉油'], difficulty: '简单', cookTime: '20分钟'
    }],
    snack: [{
      name: '苹果花生酱片', calories: 200, proteinGram: 8, fatGram: 12, carbohydrateGram: 18,
      ingredients: ['苹果 1个', '无糖花生酱 20g'],
      steps: ['苹果切片', '涂抹花生酱'], difficulty: '简单', cookTime: '3分钟'
    }],
    estimatedIntake: { dailyCalories: 1500, proteinGram: 102, fatGram: 51, carbohydrateGram: 156,
      macroRatio: '蛋白质 102g / 脂肪 51g / 碳水 156g' },
    notes: ['当前为离线备用方案 2。', '连接后端后可体验 AI 实时推荐。']
  };

  private static aiPlanVariant3: AiMealPlan = {
    breakfast: [{
      name: '酸奶坚果水果碗', calories: 360, proteinGram: 18, fatGram: 10, carbohydrateGram: 48,
      ingredients: ['无糖酸奶 200g', '混合坚果 20g', '香蕉 1根', '燕麦 30g'],
      steps: ['酸奶铺底', '加入燕麦和坚果', '香蕉切片摆放'], difficulty: '简单', cookTime: '5分钟'
    }],
    lunch: [{
      name: '牛肉番茄意面', calories: 540, proteinGram: 40, fatGram: 16, carbohydrateGram: 58,
      ingredients: ['全麦意面 80g', '牛肉 100g', '番茄 2个', '洋葱'],
      steps: ['意面煮熟', '牛肉和番茄炒成酱', '拌匀'], difficulty: '中等', cookTime: '30分钟'
    }],
    dinner: [{
      name: '冬瓜虾仁汤', calories: 290, proteinGram: 28, fatGram: 6, carbohydrateGram: 26,
      ingredients: ['虾仁 120g', '冬瓜 200g', '海带 30g'],
      steps: ['冬瓜切块煮软', '加入虾仁和海带', '调味煮 3 分钟'], difficulty: '简单', cookTime: '15分钟'
    }],
    snack: [{
      name: '黄瓜鸡蛋杯', calories: 180, proteinGram: 16, fatGram: 6, carbohydrateGram: 12,
      ingredients: ['鸡蛋 1个', '黄瓜 1根', '黑胡椒'],
      steps: ['鸡蛋煮熟切块', '黄瓜切片', '拌匀撒黑胡椒'], difficulty: '简单', cookTime: '8分钟'
    }],
    estimatedIntake: { dailyCalories: 1370, proteinGram: 102, fatGram: 38, carbohydrateGram: 144,
      macroRatio: '蛋白质 102g / 脂肪 38g / 碳水 144g' },
    notes: ['当前为离线备用方案 3。', '连接后端后可体验 AI 实时推荐。']
  };

  private static aiPlanVariants: AiMealPlan[] = [
    MockData.aiPlanVariant1, MockData.aiPlanVariant2, MockData.aiPlanVariant3
  ];

  static getRotatingAiMealPlan(refreshIndex: number): AiMealPlan {
    return MockData.aiPlanVariants[refreshIndex % MockData.aiPlanVariants.length];
  }

  static summary: NutritionSummary = {
    userId: 'demo',
    totalCalories: 980,
    totalProteinGram: 70,
    totalFatGram: 26,
    totalCarbohydrateGram: 114,
    calorieCompletion: 52.3,
    suggestions: [
      '今日摄入偏低，可适当补充优质蛋白和复合碳水。',
      '建议记录完整三餐，便于生成更准确的健康周报。'
    ]
  };

  static weeklyReport: WeeklyReport = {
    userId: 'demo',
    startDate: '2026-07-04',
    endDate: '2026-07-10',
    averageCalories: 1680,
    recordDays: 5,
    completionLevel: '接近目标',
    trendHighlights: [
      '本周已记录 5/7 天饮食数据，记录率 71.4%。',
      '日均摄入约 1680 千卡（蛋白质 72g / 脂肪 38g / 碳水 210g）。',
      '周热量趋势：与上周基本持平。',
      '记录最多的餐次为午餐，共 5 条记录。'
    ],
    aiSuggestions: [
      '本周热量控制较为稳定（完成率 89.6%），继续保持均衡搭配和规律作息。',
      '蛋白质摄入稍显不足（完成率 71.3%），建议每餐搭配足量瘦肉、鱼虾、豆制品或蛋奶类食物。',
      '继续保持高蛋白、足量蔬菜和规律记录，下一份周报将涵盖更多维度的分析。'
    ],
    dailyCalories: {
      '周一': 450,
      '周二': 520,
      '周三': 380,
      '周四': 610,
      '周五': 430,
      '周六': 480,
      '周日': 350
    },
    dailyProtein: {
      '周一': 22,
      '周二': 28,
      '周三': 18,
      '周四': 35,
      '周五': 20,
      '周六': 24,
      '周日': 16
    },
    dailyFat: {
      '周一': 10,
      '周二': 12,
      '周三': 9,
      '周四': 14,
      '周五': 10,
      '周六': 11,
      '周日': 8
    },
    dailyCarbs: {
      '周一': 45,
      '周二': 52,
      '周三': 38,
      '周四': 60,
      '周五': 42,
      '周六': 48,
      '周日': 36
    },
    avgProtein: 72,
    avgFat: 38,
    avgCarbs: 210,
    calorieCompletionRate: 89.6,
    proteinCompletionRate: 71.3,
    fatCompletionRate: 73.1,
    carbCompletionRate: 83.7,
    recordDayRate: 71.4,
    breakfastCount: 3,
    lunchCount: 5,
    dinnerCount: 4,
    snackCount: 2,
    weekOverWeekCalorieChange: 0,
    weekOverWeekTrend: 'STABLE',
    weeklyRecords: []
  };
}
