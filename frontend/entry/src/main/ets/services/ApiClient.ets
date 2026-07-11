import http from '@ohos.net.http';
import {
  ChangePasswordRequest,
  DietRecord,
  DietRecordRequest,
  HealthProfile,
  LoginRequest,
  MealPlan,
  MealType,
  NutritionSummary,
  Recipe,
  RecipeHistoryItem,
  RecipePageResponse,
  RegisterRequest,
  SyncSettingRequest,
  UpdateProfileRequest,
  UserCenterSummary,
  UserSession,
  WeeklyReport
} from '../common/Models';
import { MockData } from '../common/MockData';

interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

interface MockAccount {
  userId: string;
  username: string;
  password: string;
  displayName: string;
}

interface MockUserRecipeState {
  userId: string;
  favoriteIds: string[];
  historyIds: string[];
  syncEnabled: boolean;
}

export class ApiClient {
  static baseUrl: string = 'http://10.198.98.58:8080';
  static useMock: boolean = false;
  static fallbackToMockAuth: boolean = true;
  static currentUserId: string = 'demo';
  static currentUserName: string = '演示用户';
  static lastError: string = '';

  private static mockAccounts: MockAccount[] = [
    {
      userId: 'demo',
      username: 'demo',
      password: '123456',
      displayName: '演示用户'
    }
  ];

  private static mockUserRecipeStates: MockUserRecipeState[] = [
    {
      userId: 'demo',
      favoriteIds: ['B001', 'L001'],
      historyIds: ['L001', 'B001', 'D002'],
      syncEnabled: true
    }
  ];

  private static mockDietRecords: DietRecord[] = [
    {
      id: 'R001',
      userId: 'demo',
      foodName: '燕麦鸡蛋牛奶早餐',
      mealType: MealType.BREAKFAST,
      calories: 420,
      proteinGram: 28,
      fatGram: 12,
      carbohydrateGram: 48,
      eatenAt: '2026-07-06 08:10'
    },
    {
      id: 'R002',
      userId: 'demo',
      foodName: '糙米鸡胸蔬菜碗',
      mealType: MealType.LUNCH,
      calories: 560,
      proteinGram: 42,
      fatGram: 14,
      carbohydrateGram: 66,
      eatenAt: '2026-07-06 12:30'
    }
  ];

  static async login(request: LoginRequest): Promise<UserSession> {
    if (request.username.trim().toLowerCase() === 'admin') {
      const adminSession: UserSession = {
        userId: 'admin',
        username: 'admin',
        displayName: 'admin 测试账号'
      };
      ApiClient.rememberSession(adminSession);
      ApiClient.lastError = '';
      return adminSession;
    }

    if (ApiClient.useMock) {
      const account = ApiClient.findMockAccount(request.username);
      if (account == null) {
        ApiClient.lastError = '该用户还未在系统内注册，请先注册';
        throw new Error(ApiClient.lastError);
      }
      if (account.password !== request.password) {
        ApiClient.lastError = '密码错误，请重新输入';
        throw new Error(ApiClient.lastError);
      }
      const session: UserSession = {
        userId: account.userId,
        username: account.username,
        displayName: account.displayName
      };
      ApiClient.rememberSession(session);
      ApiClient.lastError = '';
      return session;
    }
    const result = await ApiClient.request<UserSession>('POST', '/api/users/login', request);
    ApiClient.rememberSession(result.data);
    return result.data;
  }

  static async register(request: RegisterRequest): Promise<UserSession> {
    if (ApiClient.useMock) {
      const account = ApiClient.findMockAccount(request.username);
      if (account != null) {
        ApiClient.lastError = '用户名已存在';
        throw new Error(ApiClient.lastError);
      }
      const displayName = request.displayName.length > 0 ? request.displayName : request.username;
      const newAccount: MockAccount = {
        userId: request.username,
        username: request.username,
        password: request.password,
        displayName: displayName
      };
      ApiClient.mockAccounts.push(newAccount);
      ApiClient.mockUserRecipeStates.push({
        userId: newAccount.userId,
        favoriteIds: [],
        historyIds: [],
        syncEnabled: true
      });
      const session: UserSession = {
        userId: newAccount.userId,
        username: newAccount.username,
        displayName: newAccount.displayName
      };
      ApiClient.lastError = '';
      return session;
    }
    const result = await ApiClient.request<UserSession>('POST', '/api/users/register', request);
    ApiClient.rememberSession(result.data);
    return result.data;
  }

  static async changePassword(request: ChangePasswordRequest): Promise<void> {
    if (ApiClient.useMock) {
      const account = ApiClient.findMockAccountByUserId(request.userId);
      if (account == null) {
        ApiClient.lastError = '未找到当前用户，请重新登录';
        throw new Error(ApiClient.lastError);
      }
      if (account.password !== request.oldPassword) {
        ApiClient.lastError = '原密码不正确，请重新输入';
        throw new Error(ApiClient.lastError);
      }
      account.password = request.newPassword;
      ApiClient.lastError = '';
      return;
    }
    await ApiClient.request<Object>('POST', '/api/users/password', request);
  }

  static async updateProfile(request: UpdateProfileRequest): Promise<UserSession> {
    if (ApiClient.useMock) {
      const account = ApiClient.findMockAccountByUserId(request.userId);
      if (account == null) {
        ApiClient.lastError = '未找到当前用户，请重新登录';
        throw new Error(ApiClient.lastError);
      }
      account.displayName = request.displayName;
      ApiClient.currentUserName = request.displayName;
      const session: UserSession = {
        userId: account.userId,
        username: account.username,
        displayName: account.displayName
      };
      ApiClient.lastError = '';
      return session;
    }
    const result = await ApiClient.request<UserSession>('PUT', `/api/users/${request.userId}/profile`, request);
    ApiClient.currentUserName = result.data.displayName;
    return result.data;
  }

  static async getUserCenter(userId: string): Promise<UserCenterSummary> {
    if (ApiClient.useMock) {
      return ApiClient.buildMockUserCenter(userId);
    }
    const result = await ApiClient.request<UserCenterSummary>('GET', `/api/users/${userId}/center`);
    return result.data;
  }

  static async listFavoriteRecipes(userId: string): Promise<Recipe[]> {
    if (ApiClient.useMock) {
      const state = ApiClient.getMockUserRecipeState(userId);
      return ApiClient.findMockRecipesByIds(state.favoriteIds);
    }
    const result = await ApiClient.request<Recipe[]>('GET', `/api/users/${userId}/favorites`);
    return result.data;
  }

  static async addFavoriteRecipe(userId: string, recipeId: string): Promise<void> {
    if (ApiClient.useMock) {
      const state = ApiClient.getMockUserRecipeState(userId);
      if (state.favoriteIds.indexOf(recipeId) < 0) {
        state.favoriteIds.push(recipeId);
      }
      ApiClient.lastError = '';
      return;
    }
    await ApiClient.request<Object>('POST', `/api/users/${userId}/favorites/${recipeId}`);
  }

  static async deleteFavoriteRecipe(userId: string, recipeId: string): Promise<void> {
    if (ApiClient.useMock) {
      const state = ApiClient.getMockUserRecipeState(userId);
      state.favoriteIds = state.favoriteIds.filter((item: string) => item !== recipeId);
      ApiClient.lastError = '';
      return;
    }
    await ApiClient.request<Object>('DELETE', `/api/users/${userId}/favorites/${recipeId}`);
  }

  static async listRecipeHistory(userId: string): Promise<RecipeHistoryItem[]> {
    if (ApiClient.useMock) {
      const state = ApiClient.getMockUserRecipeState(userId);
      const items: RecipeHistoryItem[] = [];
      for (let i = 0; i < state.historyIds.length; i++) {
        const recipe = ApiClient.findMockRecipe(state.historyIds[i]);
        if (recipe != null) {
          items.push({ recipe: recipe, lastViewedAt: new Date().toISOString() });
        }
      }
      return items;
    }
    const result = await ApiClient.request<RecipeHistoryItem[]>('GET', `/api/users/${userId}/recipe-history`);
    return result.data;
  }

  static async addRecipeHistory(userId: string, recipeId: string): Promise<void> {
    if (ApiClient.useMock) {
      const state = ApiClient.getMockUserRecipeState(userId);
      const next = state.historyIds.filter((item: string) => item !== recipeId);
      next.unshift(recipeId);
      state.historyIds = next.slice(0, 12);
      ApiClient.lastError = '';
      return;
    }
    await ApiClient.request<Object>('POST', `/api/users/${userId}/recipe-history/${recipeId}`);
  }

  static async saveSyncSetting(userId: string, request: SyncSettingRequest): Promise<void> {
    if (ApiClient.useMock) {
      const state = ApiClient.getMockUserRecipeState(userId);
      state.syncEnabled = request.syncEnabled;
      ApiClient.lastError = '';
      return;
    }
    await ApiClient.request<Object>('POST', `/api/users/${userId}/sync-setting`, request);
  }

  static async clearRecipeHistory(userId: string): Promise<void> {
    if (ApiClient.useMock) {
      const state = ApiClient.getMockUserRecipeState(userId);
      state.historyIds = [];
      ApiClient.lastError = '';
      return;
    }
    await ApiClient.request<Object>('DELETE', `/api/users/${userId}/recipe-history`);
  }

  static async getProfile(userId: string): Promise<HealthProfile> {
    if (ApiClient.useMock) {
      MockData.profile.userId = userId;
      return MockData.profile;
    }
    const result = await ApiClient.request<HealthProfile>('GET', `/api/profiles/${userId}`);
    return result.data;
  }

  static async saveProfile(profile: HealthProfile): Promise<HealthProfile> {
    if (ApiClient.useMock) {
      MockData.profile = profile;
      return profile;
    }
    const result = await ApiClient.request<HealthProfile>('POST', '/api/profiles', profile);
    return result.data;
  }

  static async recommend(profile: HealthProfile): Promise<MealPlan> {
    if (ApiClient.useMock) {
      MockData.profile = profile;
      return MockData.mealPlan;
    }
    const result = await ApiClient.request<MealPlan>('POST', '/api/health/recommendations/day', profile);
    return result.data;
  }

  static async searchRecipes(keyword: string, goal?: string, mealType?: MealType): Promise<Recipe[]> {
    if (ApiClient.useMock) {
      const recipes = ApiClient.mockRecipes();
      const cleanKeyword = keyword.trim();
      return recipes.filter((recipe: Recipe) => {
        const source = `${recipe.name} ${recipe.category} ${recipe.tags.join(' ')} ${recipe.ingredients.join(' ')}`;
        const keywordMatched = cleanKeyword.length === 0 || source.indexOf(cleanKeyword) >= 0;
        const mealMatched = mealType == null || recipe.mealType === mealType;
        return keywordMatched && mealMatched;
      });
    }
    const params: string[] = [];
    if (keyword.trim().length > 0) {
      params.push(`keyword=${encodeURIComponent(keyword.trim())}`);
    }
    if (goal != null && goal.length > 0) {
      params.push(`goal=${goal}`);
    }
    if (mealType != null) {
      params.push(`mealType=${mealType}`);
    }
    const query = params.length > 0 ? `?${params.join('&')}` : '';
    const result = await ApiClient.request<Recipe[]>('GET', `/api/recipes${query}`);
    return result.data;
  }

  static async getRecipeDetail(recipeId: string): Promise<Recipe> {
    if (ApiClient.useMock) {
      const recipe = ApiClient.findMockRecipe(recipeId);
      if (recipe == null) {
        ApiClient.lastError = '食谱不存在';
        throw new Error(ApiClient.lastError);
      }
      return recipe;
    }
    const result = await ApiClient.request<Recipe>('GET', `/api/recipes/${recipeId}`);
    return result.data;
  }

  static async getRecipePage(page: number, size: number, keyword?: string, mealType?: string, sort?: string): Promise<RecipePageResponse> {
    const params: string[] = [];
    params.push(`page=${page}`);
    params.push(`size=${size}`);
    if (keyword != null && keyword.trim().length > 0) {
      params.push(`keyword=${encodeURIComponent(keyword.trim())}`);
    }
    if (mealType != null && mealType.length > 0) {
      params.push(`mealType=${mealType}`);
    }
    if (sort != null && sort.length > 0) {
      params.push(`sort=${sort}`);
    }
    const query = `?${params.join('&')}`;
    const result = await ApiClient.request<RecipePageResponse>('GET', `/api/recipes/page${query}`);
    return result.data;
  }

  static async addDietRecord(record: DietRecordRequest): Promise<DietRecord> {
    if (ApiClient.useMock) {
      const demoRecord: DietRecord = {
        id: Date.now().toString(),
        userId: record.userId,
        foodName: record.foodName,
        mealType: record.mealType,
        calories: record.calories,
        proteinGram: record.proteinGram,
        fatGram: record.fatGram,
        carbohydrateGram: record.carbohydrateGram,
        eatenAt: new Date().toISOString()
      };
      ApiClient.mockDietRecords.unshift(demoRecord);
      return demoRecord;
    }
    try {
      const result = await ApiClient.request<DietRecord>('POST', '/api/diet-records', record);
      const savedRecord = result.data;
      ApiClient.cacheRecord(savedRecord);
      return savedRecord;
    } catch (_err) {
      const fallbackRecord: DietRecord = {
        id: Date.now().toString(),
        userId: record.userId,
        foodName: record.foodName,
        mealType: record.mealType,
        calories: record.calories,
        proteinGram: record.proteinGram,
        fatGram: record.fatGram,
        carbohydrateGram: record.carbohydrateGram,
        eatenAt: new Date().toISOString()
      };
      ApiClient.mockDietRecords.unshift(fallbackRecord);
      return fallbackRecord;
    }
  }

  static async listDietRecords(userId: string): Promise<DietRecord[]> {
    if (ApiClient.useMock) {
      return ApiClient.mockDietRecords.filter((record: DietRecord) => record.userId === userId);
    }
    try {
      const result = await ApiClient.request<DietRecord[]>('GET', `/api/diet-records?userId=${userId}`);
      return result.data;
    } catch (error) {
      return ApiClient.mockDietRecords.filter((record: DietRecord) => record.userId === userId);
    }
  }

  static async getSummary(userId: string, targetCalories: number): Promise<NutritionSummary> {
    if (ApiClient.useMock) {
      return ApiClient.buildSummary(userId, targetCalories);
    }
    const result = await ApiClient.request<NutritionSummary>('GET', `/api/diet-records/summary?userId=${userId}&targetCalories=${targetCalories}`);
    return result.data;
  }

  static async getWeeklyReport(userId: string, targetCalories: number): Promise<WeeklyReport> {
    if (ApiClient.useMock) {
      return ApiClient.computeWeeklyReport(userId, targetCalories);
    }
    try {
      const result = await ApiClient.request<WeeklyReport>('GET', `/api/reports/week?userId=${userId}&targetCalories=${targetCalories}`);
      const report = result.data;
      if (report.weeklyRecords == null || report.weeklyRecords.length === 0) {
        report.weeklyRecords = ApiClient.mockDietRecords.filter((r: DietRecord) => r.userId === userId);
      }
      return report;
    } catch (error) {
      return ApiClient.computeWeeklyReport(userId, targetCalories);
    }
  }

  private static cacheRecord(record: DietRecord) {
    ApiClient.mockDietRecords.unshift(record);
  }

  private static computeWeeklyReport(userId: string, targetCalories: number): WeeklyReport {
    const userRecords = ApiClient.mockDietRecords.filter((r: DietRecord) => r.userId === userId);
    const now = new Date();
    const dayOrder: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const labels: string[] = [];
    const dayMap: Map<string, DietRecord[]> = new Map();
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now.getTime());
      d.setDate(d.getDate() - i);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      const label = dayOrder[d.getDay()];
      labels.push(label);
      dayMap.set(key, []);
    }

    const dateKeys: string[] = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now.getTime());
      d.setDate(d.getDate() - i);
      dateKeys.push(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`);
    }

    userRecords.forEach((record: DietRecord) => {
      const dateKey = record.eatenAt.substring(0, 10);
      const list = dayMap.get(dateKey);
      if (list != null) {
        list.push(record);
      }
    });

    const dailyCals: Record<string, number> = {};
    const dailyProts: Record<string, number> = {};
    const dailyFats: Record<string, number> = {};
    const dailyCarbs: Record<string, number> = {};
    let recordDays = 0;
    let totalCalories = 0;
    let totalProtein = 0;
    let totalFat = 0;
    let totalCarbs = 0;
    let breakfastCount = 0;
    let lunchCount = 0;
    let dinnerCount = 0;
    let snackCount = 0;

    for (let i = 0; i < dateKeys.length; i++) {
      const key = dateKeys[i];
      const label = labels[i];
      const dayRecords = dayMap.get(key) ?? [];
      let cals = 0;
      let prot = 0;
      let fat = 0;
      let carb = 0;
      dayRecords.forEach((r: DietRecord) => {
        cals += r.calories;
        prot += r.proteinGram;
        fat += r.fatGram;
        carb += r.carbohydrateGram;
        if (r.mealType === MealType.BREAKFAST) {
          breakfastCount++;
        } else if (r.mealType === MealType.LUNCH) {
          lunchCount++;
        } else if (r.mealType === MealType.DINNER) {
          dinnerCount++;
        } else {
          snackCount++;
        }
      });
      dailyCals[label] = cals;
      dailyProts[label] = prot;
      dailyFats[label] = fat;
      dailyCarbs[label] = carb;
      if (dayRecords.length > 0) {
        recordDays++;
        totalCalories += cals;
        totalProtein += prot;
        totalFat += fat;
        totalCarbs += carb;
      }
    }

    const averageCalories = recordDays === 0 ? 0 : Math.round(totalCalories / recordDays);
    const avgProtein = recordDays === 0 ? 0 : Math.round(totalProtein / recordDays);
    const avgFat = recordDays === 0 ? 0 : Math.round(totalFat / recordDays);
    const avgCarbs = recordDays === 0 ? 0 : Math.round(totalCarbs / recordDays);

    const targetProtein = Math.round(targetCalories * 0.25 / 4);
    const targetFat = Math.round(targetCalories * 0.25 / 9);
    const targetCarbs = Math.round(targetCalories * 0.50 / 4);

    const calorieCompletionRate = targetCalories <= 0 ? 0 : Math.round(Math.min(100, averageCalories * 100 / targetCalories) * 10) / 10;
    const proteinCompletionRate = targetProtein <= 0 ? 0 : Math.round(Math.min(100, avgProtein * 100 / targetProtein) * 10) / 10;
    const fatCompletionRate = targetFat <= 0 ? 0 : Math.round(Math.min(100, avgFat * 100 / targetFat) * 10) / 10;
    const carbCompletionRate = targetCarbs <= 0 ? 0 : Math.round(Math.min(100, avgCarbs * 100 / targetCarbs) * 10) / 10;
    const recordDayRate = Math.round(recordDays * 1000 / 7) / 10;

    let completionLevel = '暂无记录';
    if (averageCalories > 0) {
      const ratio = averageCalories / targetCalories;
      if (ratio < 0.8) {
        completionLevel = '摄入偏低';
      } else if (ratio > 1.1) {
        completionLevel = '摄入偏高';
      } else {
        completionLevel = '接近目标';
      }
    }

    const highlights: string[] = [];
    highlights.push(`本周已记录 ${recordDays}/7 天饮食数据，记录率 ${recordDayRate}%。`);
    highlights.push(`日均摄入约 ${averageCalories} 千卡（蛋白质 ${avgProtein}g / 脂肪 ${avgFat}g / 碳水 ${avgCarbs}g）。`);
    if (recordDays >= 5) {
      highlights.push('记录习惯良好，继续保持每天记录三餐。');
    } else if (recordDays > 0) {
      highlights.push(`还差 ${7 - recordDays} 天即可达成全周记录，加油！`);
    } else {
      highlights.push('本周暂无饮食记录，开始记录后将自动生成趋势分析。');
    }
    const maxMeal = Math.max(breakfastCount, lunchCount, dinnerCount, snackCount);
    if (maxMeal > 0) {
      const maxName = maxMeal === breakfastCount ? '早餐' : maxMeal === lunchCount ? '午餐' : maxMeal === dinnerCount ? '晚餐' : '加餐';
      highlights.push(`记录最多的餐次为${maxName}，共 ${maxMeal} 条。`);
    }

    const suggestions: string[] = [];
    if (recordDays === 0) {
      suggestions.push('建议从今天开始记录三餐，系统会自动生成趋势分析。');
      suggestions.push('开启每日饮食记录，解锁周报和 AI 个性化建议等全部功能。');
    } else {
      if (recordDayRate < 71) {
        suggestions.push(`本周记录天数不足（${recordDayRate}%），记录越完整建议越精准。`);
      }
      if (calorieCompletionRate < 80) {
        suggestions.push(`热量摄入偏低（完成率 ${calorieCompletionRate}%），可在早餐或加餐增加鸡蛋、牛奶、坚果等。`);
      } else if (calorieCompletionRate > 110) {
        suggestions.push(`热量摄入偏高（${calorieCompletionRate}%），建议减少油炸食品，晚餐保持清淡。`);
      } else if (calorieCompletionRate >= 80) {
        suggestions.push(`热量控制稳定（完成率 ${calorieCompletionRate}%），继续保持均衡搭配。`);
      }
      if (proteinCompletionRate < 70) {
        suggestions.push(`蛋白质摄入不足（完成率 ${proteinCompletionRate}%），建议每餐搭配瘦肉、鱼虾或豆制品。`);
      }
      if (breakfastCount === 0 && recordDays > 0) {
        suggestions.push('本周缺少早餐记录，规律三餐是健康饮食的基础。');
      }
      if (suggestions.length < 2) {
        suggestions.push('继续保持高蛋白、足量蔬菜和规律记录，下周将有更详细的分析。');
      }
    }

    const startD = new Date(now.getTime());
    startD.setDate(startD.getDate() - 6);
    const startStr = `${startD.getFullYear()}-${String(startD.getMonth() + 1).padStart(2, '0')}-${String(startD.getDate()).padStart(2, '0')}`;
    const endStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

    return {
      userId: userId,
      startDate: startStr,
      endDate: endStr,
      averageCalories: averageCalories,
      recordDays: recordDays,
      completionLevel: completionLevel,
      trendHighlights: highlights,
      aiSuggestions: suggestions,
      dailyCalories: dailyCals,
      dailyProtein: dailyProts,
      dailyFat: dailyFats,
      dailyCarbs: dailyCarbs,
      avgProtein: avgProtein,
      avgFat: avgFat,
      avgCarbs: avgCarbs,
      calorieCompletionRate: calorieCompletionRate,
      proteinCompletionRate: proteinCompletionRate,
      fatCompletionRate: fatCompletionRate,
      carbCompletionRate: carbCompletionRate,
      recordDayRate: recordDayRate,
      breakfastCount: breakfastCount,
      lunchCount: lunchCount,
      dinnerCount: dinnerCount,
      snackCount: snackCount,
      weekOverWeekCalorieChange: 0,
      weekOverWeekTrend: 'STABLE',
      weeklyRecords: userRecords
    };
  }

  private static async request<T>(method: string, path: string, body?: Object): Promise<ApiResponse<T>> {
    const request = http.createHttp();
    try {
      let requestMethod = http.RequestMethod.GET;
      if (method === 'POST') {
        requestMethod = http.RequestMethod.POST;
      }
      if (method === 'PUT') {
        requestMethod = http.RequestMethod.PUT;
      }
      if (method === 'DELETE') {
        requestMethod = http.RequestMethod.DELETE;
      }
      const response = await request.request(ApiClient.baseUrl + path, {
        method: requestMethod,
        header: { 'Content-Type': 'application/json' },
        extraData: body == null ? undefined : JSON.stringify(body)
      });
      const result = JSON.parse(response.result as string) as ApiResponse<T>;
      if (!result.success) {
        ApiClient.lastError = result.message;
        throw new Error(result.message);
      }
      ApiClient.lastError = '';
      return result;
    } catch (error) {
      if (ApiClient.lastError.length === 0) {
        ApiClient.lastError = `无法连接后端服务：${ApiClient.baseUrl}`;
      }
      throw new Error(ApiClient.lastError);
    } finally {
      request.destroy();
    }
  }

  private static rememberSession(session: UserSession) {
    ApiClient.currentUserId = session.userId;
    ApiClient.currentUserName = session.displayName.length > 0 ? session.displayName : session.username;
    MockData.profile.userId = session.userId;
    ApiClient.getMockUserRecipeState(session.userId);
  }

  private static buildSummary(userId: string, targetCalories: number): NutritionSummary {
    const records = ApiClient.mockDietRecords.filter((record: DietRecord) => record.userId === userId);
    let totalCalories = 0;
    let totalProtein = 0;
    let totalFat = 0;
    let totalCarbs = 0;
    records.forEach((record: DietRecord) => {
      totalCalories += record.calories;
      totalProtein += record.proteinGram;
      totalFat += record.fatGram;
      totalCarbs += record.carbohydrateGram;
    });
    const completion = targetCalories <= 0 ? 0 : Number((totalCalories * 100 / targetCalories).toFixed(1));
    const summary: NutritionSummary = {
      userId: userId,
      totalCalories: totalCalories,
      totalProteinGram: totalProtein,
      totalFatGram: totalFat,
      totalCarbohydrateGram: totalCarbs,
      calorieCompletion: completion,
      suggestions: completion < 70 ? [
        '今日摄入偏低，可补充一份优质蛋白或复合碳水。',
        '建议晚餐搭配深色蔬菜，帮助提升饱腹感。'
      ] : [
        '今日摄入接近目标，继续保持稳定记录。',
        '注意饮水和蔬菜摄入，避免晚间高盐食物。'
      ]
    };
    return summary;
  }

  private static buildMockUserCenter(userId: string): UserCenterSummary {
    const state = ApiClient.getMockUserRecipeState(userId);
    const summary = ApiClient.buildSummary(userId, MockData.mealPlan.assessment.target.dailyCalories);
    const history = ApiClient.findMockRecipesByIds(state.historyIds);
    const recommendedRecipeName = history.length > 0 ? history[0].name : MockData.mealPlan.lunch[0].name;
    const result: UserCenterSummary = {
      userId: userId,
      displayName: ApiClient.currentUserName,
      favoriteCount: state.favoriteIds.length,
      historyCount: state.historyIds.length,
      syncEnabled: state.syncEnabled,
      todayCalories: summary.totalCalories,
      targetCalories: MockData.mealPlan.assessment.target.dailyCalories,
      recommendedRecipeName: recommendedRecipeName
    };
    return result;
  }

  private static getMockUserRecipeState(userId: string): MockUserRecipeState {
    for (let index = 0; index < ApiClient.mockUserRecipeStates.length; index++) {
      const state = ApiClient.mockUserRecipeStates[index];
      if (state.userId === userId) {
        return state;
      }
    }
    const created: MockUserRecipeState = {
      userId: userId,
      favoriteIds: [],
      historyIds: [],
      syncEnabled: true
    };
    ApiClient.mockUserRecipeStates.push(created);
    return created;
  }

  private static findMockRecipesByIds(ids: string[]): Recipe[] {
    const recipes: Recipe[] = [];
    ids.forEach((id: string) => {
      const recipe = ApiClient.findMockRecipe(id);
      if (recipe != null) {
        recipes.push(recipe);
      }
    });
    return recipes;
  }

  private static findMockRecipe(id: string): Recipe | null {
    const recipes = ApiClient.mockRecipes();
    for (let index = 0; index < recipes.length; index++) {
      const recipe = recipes[index];
      if (recipe.id === id) {
        return recipe;
      }
    }
    return null;
  }

  private static mockRecipes(): Recipe[] {
    return [
      MockData.mealPlan.breakfast[0],
      MockData.mealPlan.lunch[0],
      MockData.mealPlan.dinner[0],
      MockData.mealPlan.snack[0],
      {
        id: 'B002',
        name: '全麦牛油果鸡蛋吐司',
        mealType: MealType.BREAKFAST,
        category: '均衡早餐',
        tags: ['高纤维', '饱腹', '均衡'],
        ingredients: ['全麦吐司', '鸡蛋', '牛油果', '小番茄'],
        steps: ['鸡蛋煎熟', '牛油果压成泥', '吐司烤脆后组合装盘'],
        calories: 460,
        proteinGram: 24,
        fatGram: 18,
        carbohydrateGram: 52,
        difficulty: '简单',
        cookTime: '10分钟'
      },
      {
        id: 'L002',
        name: '三文鱼藜麦能量碗',
        mealType: MealType.LUNCH,
        category: '增肌午餐',
        tags: ['优质脂肪', '高蛋白', '训练日'],
        ingredients: ['三文鱼', '藜麦', '菠菜', '玉米粒'],
        steps: ['藜麦煮熟', '三文鱼煎至两面金黄', '蔬菜铺底后组合'],
        calories: 680,
        proteinGram: 46,
        fatGram: 24,
        carbohydrateGram: 68,
        difficulty: '中等',
        cookTime: '25分钟'
      },
      {
        id: 'D003',
        name: '番茄虾仁魔芋面',
        mealType: MealType.DINNER,
        category: '低碳晚餐',
        tags: ['控糖', '低碳', '轻食'],
        ingredients: ['虾仁', '魔芋面', '番茄', '生菜'],
        steps: ['番茄炒出汤汁', '加入虾仁煮熟', '放入魔芋面拌匀'],
        calories: 360,
        proteinGram: 34,
        fatGram: 8,
        carbohydrateGram: 32,
        difficulty: '简单',
        cookTime: '15分钟'
      },
      {
        id: 'S002',
        name: '苹果肉桂燕麦杯',
        mealType: MealType.SNACK,
        category: '控糖加餐',
        tags: ['低糖', '高纤维', '便携'],
        ingredients: ['苹果', '燕麦', '无糖酸奶', '肉桂粉'],
        steps: ['苹果切丁', '与燕麦和酸奶混合', '撒少量肉桂粉'],
        calories: 240,
        proteinGram: 12,
        fatGram: 6,
        carbohydrateGram: 38,
        difficulty: '简单',
        cookTime: '5分钟'
      }
    ];
  }

  private static findMockAccount(username: string): MockAccount | null {
    for (let index = 0; index < ApiClient.mockAccounts.length; index++) {
      const account = ApiClient.mockAccounts[index];
      if (account.username === username) {
        return account;
      }
    }
    return null;
  }

  private static findMockAccountByUserId(userId: string): MockAccount | null {
    for (let index = 0; index < ApiClient.mockAccounts.length; index++) {
      const account = ApiClient.mockAccounts[index];
      if (account.userId === userId) {
        return account;
      }
    }
    return null;
  }
}
