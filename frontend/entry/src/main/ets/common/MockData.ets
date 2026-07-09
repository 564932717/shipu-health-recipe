import { Gender, HealthGoal, HealthProfile, MealPlan, MealType, NutritionSummary, WeeklyReport } from './Models';

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
        carbohydrateGram: 48
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
        carbohydrateGram: 66
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
        carbohydrateGram: 28
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
        carbohydrateGram: 16
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
    startDate: '2026-07-01',
    endDate: '2026-07-07',
    averageCalories: 1680,
    recordDays: 5,
    completionLevel: '接近目标',
    trendHighlights: [
      '本周已记录 5 天饮食数据。',
      '日均摄入约 1680 千卡。',
      '晚餐热量整体控制较好。'
    ],
    aiSuggestions: ['继续保持高蛋白、足量蔬菜和规律记录。']
  };
}
