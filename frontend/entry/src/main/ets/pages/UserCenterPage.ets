import { ApiClient } from '../services/ApiClient';
import { ChangePasswordRequest, Recipe, RecipeHistoryItem, SyncSettingRequest, UpdateProfileRequest, UserCenterSummary } from '../common/Models';
import router from '@ohos.router';
import { AddFormMenuItem } from '@kit.ArkUI';
import { Want } from '@kit.AbilityKit';
import { formBindingData } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HealthCardData, HealthCardService } from '../services/HealthCardService';

@Component
export struct UserCenterPage {
  @Link isAuthed: boolean;
  @State summary: UserCenterSummary = {
    userId: ApiClient.currentUserId,
    displayName: ApiClient.currentUserName,
    favoriteCount: 0,
    historyCount: 0,
    syncEnabled: true,
    todayCalories: 980,
    targetCalories: 1875,
    recommendedRecipeName: '糙米鸡胸蔬菜碗'
  };
  @State favoriteRecipes: Recipe[] = [];
  @State historyRecipes: RecipeHistoryItem[] = [];
  @StorageLink('aiRecommendationLoading') @Watch('onAtomicCardSourceChanged') aiRecommendationLoading: boolean = false;
  @StorageLink('aiRecommendedRecipeNames') @Watch('onAtomicCardSourceChanged') aiRecommendedRecipeNames: string[] = [];
  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State syncEnabled: boolean = true;
  @State message: string = '';
  @State messageType: string = 'info';
  @State isLoading: boolean = false;
  @State isSavingPassword: boolean = false;
  @State isEditingName: boolean = false;
  @State editingDisplayName: string = '';
  @State isSavingName: boolean = false;
  @State showPasswordSection: boolean = false;
  @State syncProgress: number = 0;
  @State isSyncing: boolean = false;
  @State lastSyncTime: string = '';

  aboutToAppear() {
    this.loadCenter();
  }

  async loadCenter() {
    this.isLoading = true;
    try {
      const userId = ApiClient.currentUserId;
      const summary = await ApiClient.getUserCenter(userId);
      const favorites = await ApiClient.listFavoriteRecipes(userId);
      const history = await ApiClient.listRecipeHistory(userId);
      this.favoriteRecipes = favorites;
      this.historyRecipes = history;
      this.syncEnabled = summary.syncEnabled == null ? this.syncEnabled : summary.syncEnabled;
      this.summary = {
        userId: this.textValue(summary.userId, userId),
        displayName: this.textValue(summary.displayName, ApiClient.currentUserName),
        favoriteCount: favorites.length,
        historyCount: history.length,
        syncEnabled: this.syncEnabled,
        todayCalories: this.numberValue(summary.todayCalories, this.summary.todayCalories),
        targetCalories: this.numberValue(summary.targetCalories, this.summary.targetCalories),
        recommendedRecipeName: this.recommendedRecipeName(summary.recommendedRecipeName, history)
      };
      await this.refreshAtomicCard();
      this.message = '';
    } catch (error) {
      this.showError(ApiClient.lastError.length > 0 ? ApiClient.lastError : '用户中心数据加载失败，请稍后重试');
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.profileHeader()
        this.personalInfoSection()
        this.accountSecuritySection()
        this.collectionSection()
        this.syncSection()
        this.atomicCardPreview()
      }
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
    }
    .backgroundColor('#F4F7F1')
  }

  @Builder
  profileHeader() {
    Column({ space: 10 }) {
      Text('我的')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')
      Row() {
        Column({ space: 5 }) {
          Text(this.summary.displayName.length > 0 ? this.summary.displayName : ApiClient.currentUserName)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFF6D5')
          Text(`用户 ID：${this.summary.userId}`)
            .fontSize(12)
            .fontColor('#CFE3D4')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .padding(18)
      .backgroundColor('#071725')
      .borderRadius(20)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  personalInfoSection() {
    Column({ space: 12 }) {
      Text('个人信息')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      if (!this.isEditingName) {
        Row() {
          Column({ space: 4 }) {
            Text('昵称')
              .fontSize(12)
              .fontColor('#657064')
            Text(this.summary.displayName)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#071725')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('修改')
            .height(32)
            .fontSize(12)
            .fontColor('#156B45')
            .backgroundColor('#E8F4EC')
            .borderRadius(16)
            .onClick(() => {
              this.isEditingName = true;
              this.editingDisplayName = this.summary.displayName;
            })
        }
        .padding(14)
        .backgroundColor('#F8FAF5')
        .borderRadius(14)
        .width('100%')
      } else {
        Column({ space: 10 }) {
          TextInput({ placeholder: '请输入新昵称', text: $$this.editingDisplayName })
            .height(42)
            .fontSize(15)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#156B45' })
            .borderRadius(14)
            .padding({ left: 14, right: 14 })

          Row({ space: 10 }) {
            Button('取消')
              .height(36)
              .fontSize(13)
              .fontColor('#657064')
              .backgroundColor('#EEF4EA')
              .borderRadius(18)
              .layoutWeight(1)
              .onClick(() => {
                this.isEditingName = false;
              })
            Button(this.isSavingName ? '保存中...' : '确认修改')
              .height(36)
              .fontSize(13)
              .fontColor('#FFF6D5')
              .backgroundColor('#156B45')
              .borderRadius(18)
              .layoutWeight(1)
              .enabled(!this.isSavingName)
              .onClick(async () => {
                await this.saveDisplayName();
              })
          }
          .width('100%')
        }
        .padding(14)
        .backgroundColor('#F8FAF5')
        .borderRadius(14)
        .width('100%')
      }

      Row({ space: 8 }) {
        Text('需要完善身高、体重或健康目标？点击底部「档案」标签页即可编辑。')
          .fontSize(12)
          .fontColor('#657064')
          .layoutWeight(1)
      }
      .padding(12)
      .backgroundColor('#F8FAF5')
      .borderRadius(14)
      .width('100%')

      if (this.message.length > 0 && this.messageType !== 'error') {
        Text(this.message)
          .fontSize(13)
          .fontColor('#156B45')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#E8F4EC')
          .borderRadius(8)
          .width('100%')
      }
      if (this.message.length > 0 && this.messageType === 'error') {
        Text(this.message)
          .fontSize(13)
          .fontColor('#8B2418')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#FFE8DE')
          .borderRadius(8)
          .width('100%')
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  accountSecuritySection() {
    Column({ space: 12 }) {
      Row() {
        Text('账号安全')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .layoutWeight(1)
        Button(this.showPasswordSection ? '收起' : '展开')
          .height(30)
          .fontSize(12)
          .fontColor('#405146')
          .backgroundColor('#EEF4EA')
          .borderRadius(15)
          .onClick(() => {
            this.showPasswordSection = !this.showPasswordSection;
          })
      }
      .width('100%')

      if (this.showPasswordSection) {
        Column({ space: 10 }) {
          TextInput({ placeholder: '原密码', text: $$this.oldPassword })
            .type(InputType.Password)
            .height(42)
            .backgroundColor('#F8FAF5')
            .borderRadius(14)
            .padding({ left: 12, right: 12 })
          TextInput({ placeholder: '新密码（至少6位）', text: $$this.newPassword })
            .type(InputType.Password)
            .height(42)
            .backgroundColor('#F8FAF5')
            .borderRadius(14)
            .padding({ left: 12, right: 12 })
          TextInput({ placeholder: '确认新密码', text: $$this.confirmPassword })
            .type(InputType.Password)
            .height(42)
            .backgroundColor('#F8FAF5')
            .borderRadius(14)
            .padding({ left: 12, right: 12 })

          Button(this.isSavingPassword ? '保存中...' : '更新密码')
            .height(42)
            .fontSize(15)
            .fontColor('#FFF6D5')
            .backgroundColor('#071725')
            .borderRadius(21)
            .width('100%')
            .enabled(!this.isSavingPassword)
            .onClick(async () => {
              await this.savePassword();
            })
        }
        .width('100%')
      } else {
        Text('密码修改功能可在此处展开操作')
          .fontSize(13)
          .fontColor('#657064')
          .width('100%')
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  collectionSection() {
    Column({ space: 12 }) {
      Text('收藏与历史')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Text(this.favoriteRecipes.length === 0 ? '暂无收藏食谱' : `已收藏 ${this.favoriteRecipes.length} 个食谱：${this.recipeNames(this.favoriteRecipes, 3)}`)
        .fontSize(13)
        .fontColor('#405146')
        .width('100%')
      Text(this.historyRecipes.length === 0 ? '暂无浏览历史' : `最近浏览 ${this.historyRecipes.length} 个食谱：${this.historyItemNames(this.historyRecipes, 3)}`)
        .fontSize(13)
        .fontColor('#405146')
        .width('100%')

      Row({ space: 10 }) {
        Button('查看收藏')
          .height(36)
          .fontSize(13)
          .fontColor('#156B45')
          .backgroundColor('#E8F4EC')
          .borderRadius(18)
          .layoutWeight(1)
          .onClick(() => {
            router.pushUrl({ url: 'pages/FavoritePage' });
          })
        Button('查看历史')
          .height(36)
          .fontSize(13)
          .fontColor('#071725')
          .backgroundColor('#F4E8BA')
          .borderRadius(18)
          .layoutWeight(1)
          .onClick(() => {
            router.pushUrl({ url: 'pages/HistoryPage' });
          })
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  syncSection() {
    Column({ space: 12 }) {
      Row() {
        Text('跨设备数据同步')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.syncEnabled })
          .onChange(async (isOn: boolean) => {
            await this.saveSyncSetting(isOn);
          })
      }
      .width('100%')

      Text('开启后可同步健康档案、收藏食谱和饮食记录至其他鸿蒙设备。')
        .fontSize(13)
        .fontColor('#657064')
        .lineHeight(20)
        .width('100%')

      if (this.syncEnabled) {
        Row({ space: 10 }) {
          if (this.isSyncing) {
            Row()
              .width(16)
              .height(16)
              .backgroundColor('#F8DD77')
              .borderRadius(8)
          } else {
            Text(this.lastSyncTime.length > 0 ? `上次同步：${this.lastSyncTime}` : '数据待同步')
              .fontSize(12)
              .fontColor('#657064')
              .layoutWeight(1)
          }
          Button(this.isSyncing ? '同步中...' : '立即同步')
            .height(32)
            .fontSize(12)
            .fontColor('#156B45')
            .backgroundColor('#E8F4EC')
            .borderRadius(16)
            .enabled(!this.isSyncing)
            .onClick(async () => {
              await this.triggerSync();
            })
        }
        .width('100%')
      }

      if (this.syncProgress > 0 && this.syncProgress < 100) {
        Row()
          .height(4)
          .width(`${this.syncProgress}%`)
          .backgroundColor('#156B45')
          .borderRadius(2)
      }
      if (this.syncProgress >= 100) {
        Row()
          .height(4)
          .width('100%')
          .backgroundColor('#83C988')
          .borderRadius(2)
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  atomicCardPreview() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Text('原子化卡片预览')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .layoutWeight(1)

        Button('添加到桌面')
          .id('atomicCardAddButton')
          .height(34)
          .padding({ left: 14, right: 14 })
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#156B45')
          .backgroundColor('#E8F4EC')
          .borderRadius(17)
          .bindMenu(this.addToDesktopMenu)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: 12 }) {
        Row() {
          Text('今日摄入')
            .fontSize(13)
            .fontColor('#CFE3D4')
            .layoutWeight(1)
          Text(`已完成 ${this.intakeProgress()}%`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#F8DD77')
        }
        .width('100%')

        Text(`${this.summary.todayCalories} / ${this.summary.targetCalories} 千卡`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFF6D5')

        Row() {
          Row()
            .width(`${this.intakeProgress()}%`)
            .height(6)
            .backgroundColor('#83C988')
            .borderRadius(3)
        }
        .width('100%')
        .height(6)
        .backgroundColor('#314554')
        .borderRadius(3)

        Column({ space: 4 }) {
          Text('今日推荐')
            .fontSize(12)
            .fontColor('#CFE3D4')
          if (this.aiRecommendationLoading) {
            Row({ space: 8 }) {
              LoadingProgress()
                .width(16)
                .height(16)
                .color('#F8DD77')
              Text('AI正在为你急速生成中')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#F8DD77')
            }
          } else if (this.aiRecommendedRecipeNames.length > 0) {
            ForEach(this.aiRecommendedRecipeNames, (meal: string) => {
              Text(meal)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#F8DD77')
                .lineHeight(21)
                .width('100%')
            }, (meal: string) => meal)
          } else {
            Text('AI推荐暂未生成')
              .fontSize(14)
              .fontColor('#F8DD77')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .padding(16)
      .backgroundColor('#071725')
      .borderRadius(18)
      .width('100%')

      Button('退出登录')
        .height(42)
        .fontSize(15)
        .fontColor('#071725')
        .backgroundColor('#F4E8BA')
        .borderRadius(21)
        .width('100%')
        .onClick(() => {
          this.isAuthed = false;
        })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  addToDesktopMenu() {
    Menu() {
      AddFormMenuItem(this.atomicCardWant(), 'atomicCardAddButton', {
        formBindingData: formBindingData.createFormBindingData(this.atomicCardFormData()),
        callback: (error: BusinessError, formId: string) => {
          if (error && error.code !== 0) {
            this.showError(`添加到桌面失败：${error.code} ${error.message}`);
            return;
          }
          this.message = '原子化卡片已添加到桌面';
          this.messageType = 'info';
        },
        style: {
          options: {
            content: '添加到桌面'
          }
        }
      })
    }
  }

  private atomicCardWant(): Want {
    return {
      bundleName: 'com.example.shipu',
      abilityName: 'HealthCardFormAbility',
      moduleName: 'entry',
      parameters: {
        // 4 代表 4*4 卡片。2*4 高度不足以稳定展示早餐、午餐、晚餐和加餐四行内容。
        'ohos.extra.param.key.form_dimension': 4,
        'ohos.extra.param.key.form_name': 'health_card',
        'ohos.extra.param.key.module_name': 'entry'
      }
    };
  }

  private atomicCardFormData(): HealthCardData {
    return new HealthCardData(
      this.summary.todayCalories,
      this.summary.targetCalories,
      this.intakeProgress(),
      this.desktopRecommendation()
    );
  }

  private desktopRecommendation(): string {
    if (this.aiRecommendationLoading) {
      return 'AI正在为你急速生成中';
    }
    if (this.aiRecommendedRecipeNames.length > 0) {
      // 桌面卡片使用换行分隔每餐，避免四餐内容挤在同一行后被截断。
      return this.aiRecommendedRecipeNames.join('\n');
    }
    return 'AI推荐暂未生成';
  }

  private onAtomicCardSourceChanged(): void {
    this.refreshAtomicCard();
  }

  private async refreshAtomicCard(): Promise<void> {
    try {
      await HealthCardService.saveAndUpdate(getContext(this), this.atomicCardFormData());
    } catch (error) {
      console.error(`Refresh atomic card failed: ${JSON.stringify(error)}`);
    }
  }

  private async saveDisplayName() {
    const name = this.editingDisplayName.trim();
    if (name.length === 0) {
      this.showError('昵称不能为空');
      return;
    }
    this.isSavingName = true;
    try {
      const request: UpdateProfileRequest = {
        userId: ApiClient.currentUserId,
        displayName: name
      };
      await ApiClient.updateProfile(request);
      this.summary.displayName = name;
      this.isEditingName = false;
      this.message = `昵称已更新为"${name}"`;
      this.messageType = 'info';
    } catch (error) {
      this.showError(ApiClient.lastError.length > 0 ? ApiClient.lastError : '修改失败');
    } finally {
      this.isSavingName = false;
    }
  }

  private async savePassword() {
    if (this.oldPassword.trim().length === 0 || this.newPassword.trim().length === 0) {
      this.showError('请输入原密码和新密码');
      return;
    }
    if (this.newPassword.trim().length < 6) {
      this.showError('新密码至少 6 位');
      return;
    }
    if (this.newPassword.trim() !== this.confirmPassword.trim()) {
      this.showError('两次输入的新密码不一致');
      return;
    }
    if (this.oldPassword.trim() === this.newPassword.trim()) {
      this.showError('新密码不能与原密码相同');
      return;
    }

    this.isSavingPassword = true;
    try {
      const request: ChangePasswordRequest = {
        userId: ApiClient.currentUserId,
        oldPassword: this.oldPassword.trim(),
        newPassword: this.newPassword.trim(),
        confirmPassword: this.confirmPassword.trim()
      };
      await ApiClient.changePassword(request);
      this.oldPassword = '';
      this.newPassword = '';
      this.confirmPassword = '';
      this.showPasswordSection = false;
      this.message = '密码已更新';
      this.messageType = 'info';
    } catch (error) {
      this.showError(ApiClient.lastError.length > 0 ? ApiClient.lastError : '密码更新失败，请稍后重试');
    } finally {
      this.isSavingPassword = false;
    }
  }

  private async saveSyncSetting(isOn: boolean) {
    const previous = this.syncEnabled;
    this.syncEnabled = isOn;
    try {
      const request: SyncSettingRequest = {
        syncEnabled: isOn
      };
      await ApiClient.saveSyncSetting(ApiClient.currentUserId, request);
      this.summary.syncEnabled = isOn;
      this.message = isOn ? '跨设备同步已开启' : '跨设备同步已关闭';
      this.messageType = 'info';
    } catch (error) {
      this.syncEnabled = previous;
      this.showError(ApiClient.lastError.length > 0 ? ApiClient.lastError : '同步设置保存失败');
    }
  }

  private async triggerSync() {
    this.isSyncing = true;
    this.syncProgress = 0;
    const steps = [25, 50, 75, 100];
    for (let i = 0; i < steps.length; i++) {
      this.syncProgress = steps[i];
      await this.delay(300);
    }
    await this.loadCenter();
    this.lastSyncTime = this.nowString();
    this.syncProgress = 100;
    this.isSyncing = false;
    this.message = '数据同步完成';
    this.messageType = 'info';
  }

  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: (value: void) => void) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  private nowString(): string {
    const d = new Date();
    const m = `${d.getMonth() + 1}`.padStart(2, '0');
    const day = `${d.getDate()}`.padStart(2, '0');
    const h = `${d.getHours()}`.padStart(2, '0');
    const min = `${d.getMinutes()}`.padStart(2, '0');
    return `${m}-${day} ${h}:${min}`;
  }

  private recipeNames(recipes: Recipe[], limit: number): string {
    const names: string[] = [];
    const count = recipes.length > limit ? limit : recipes.length;
    for (let index = 0; index < count; index++) {
      names.push(recipes[index].name);
    }
    return names.join('、');
  }

  private historyItemNames(items: RecipeHistoryItem[], limit: number): string {
    const names: string[] = [];
    const count = items.length > limit ? limit : items.length;
    for (let index = 0; index < count; index++) {
      names.push(items[index].recipe.name);
    }
    return names.join('、');
  }

  private textValue(value: string, fallback: string): string {
    if (value != null && value.length > 0) {
      return value;
    }
    return fallback;
  }

  private numberValue(value: number, fallback: number): number {
    const parsed = Number(value);
    if (Number.isNaN(parsed)) {
      return fallback;
    }
    return parsed;
  }

  private intakeProgress(): number {
    if (this.summary.targetCalories <= 0) {
      return 0;
    }
    const progress = Math.round(this.summary.todayCalories * 100 / this.summary.targetCalories);
    return Math.max(0, Math.min(100, progress));
  }

  private recommendedRecipeName(value: string, history: RecipeHistoryItem[]): string {
    if (value != null && value.length > 0) {
      return value;
    }
    if (history.length > 0) {
      return history[0].recipe.name;
    }
    return this.summary.recommendedRecipeName;
  }

  private showError(message: string) {
    this.message = message;
    this.messageType = 'error';
  }
}
