import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { formBindingData, formProvider } from '@kit.FormKit';

const PREFERENCES_NAME: string = 'health_card_state';
const FORM_IDS_KEY: string = 'form_ids';
const TODAY_CALORIES_KEY: string = 'today_calories';
const TARGET_CALORIES_KEY: string = 'target_calories';
const PROGRESS_KEY: string = 'progress';
const RECOMMENDATION_KEY: string = 'recommendation';

export class HealthCardData {
  todayCalories: number;
  targetCalories: number;
  progress: number;
  recommendation: string;

  constructor(todayCalories: number = 0, targetCalories: number = 1875,
    progress: number = 0, recommendation: string = 'AI推荐暂未生成') {
    this.todayCalories = todayCalories;
    this.targetCalories = targetCalories;
    this.progress = progress;
    this.recommendation = recommendation;
  }
}

export class HealthCardService {
  static loadData(context: common.Context): HealthCardData {
    const store = HealthCardService.openStore(context);
    return new HealthCardData(
      store.getSync(TODAY_CALORIES_KEY, 0) as number,
      store.getSync(TARGET_CALORIES_KEY, 1875) as number,
      store.getSync(PROGRESS_KEY, 0) as number,
      store.getSync(RECOMMENDATION_KEY, 'AI推荐暂未生成') as string
    );
  }

  static registerForm(context: common.Context, formId: string): void {
    if (formId.length === 0) {
      return;
    }
    const store = HealthCardService.openStore(context);
    const ids = HealthCardService.readFormIds(store);
    if (ids.includes(formId)) {
      return;
    }
    ids.push(formId);
    store.putSync(FORM_IDS_KEY, ids.join(','));
    store.flush();
  }

  static removeForm(context: common.Context, formId: string): void {
    const store = HealthCardService.openStore(context);
    const ids = HealthCardService.readFormIds(store);
    const remaining: string[] = [];
    for (let index = 0; index < ids.length; index++) {
      if (ids[index] !== formId) {
        remaining.push(ids[index]);
      }
    }
    store.putSync(FORM_IDS_KEY, remaining.join(','));
    store.flush();
  }

  static async saveAndUpdate(context: common.Context, data: HealthCardData): Promise<void> {
    const store = HealthCardService.openStore(context);
    store.putSync(TODAY_CALORIES_KEY, data.todayCalories);
    store.putSync(TARGET_CALORIES_KEY, data.targetCalories);
    store.putSync(PROGRESS_KEY, data.progress);
    store.putSync(RECOMMENDATION_KEY, data.recommendation);
    await store.flush();

    const ids = HealthCardService.readFormIds(store);
    const bindingData = formBindingData.createFormBindingData(data);
    for (let index = 0; index < ids.length; index++) {
      try {
        await formProvider.updateForm(ids[index], bindingData);
      } catch (error) {
        console.error(`HealthCard update failed, formId=${ids[index]}, error=${JSON.stringify(error)}`);
      }
    }
  }

  static async updateForm(context: common.Context, formId: string): Promise<void> {
    const data = HealthCardService.loadData(context);
    await formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
  }

  private static openStore(context: common.Context): preferences.Preferences {
    // 卡片运行在独立进程中。每次移除内存缓存后重开，确保两个进程读取到对方刚写入的数据。
    try {
      preferences.removePreferencesFromCacheSync(context, PREFERENCES_NAME);
    } catch (error) {
      console.warn(`HealthCard preferences cache refresh failed: ${JSON.stringify(error)}`);
    }
    return preferences.getPreferencesSync(context, { name: PREFERENCES_NAME });
  }

  private static readFormIds(store: preferences.Preferences): string[] {
    const value = store.getSync(FORM_IDS_KEY, '') as string;
    if (value.length === 0) {
      return [];
    }
    const source = value.split(',');
    const ids: string[] = [];
    for (let index = 0; index < source.length; index++) {
      if (source[index].length > 0) {
        ids.push(source[index]);
      }
    }
    return ids;
  }
}
