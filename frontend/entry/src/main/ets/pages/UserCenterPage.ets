import { ApiClient } from '../services/ApiClient';
import { ChangePasswordRequest, Recipe, SyncSettingRequest, UserCenterSummary } from '../common/Models';

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
  @State historyRecipes: Recipe[] = [];
  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State syncEnabled: boolean = true;
  @State message: string = '';
  @State isLoading: boolean = false;
  @State isSavingPassword: boolean = false;

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
      this.message = '';
    } catch (error) {
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '用户中心数据加载失败，请稍后重试';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.profileHeader()
        this.accountSection()
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
        Text(this.isLoading ? '同步中' : '健康档案')
          .fontSize(13)
          .fontColor('#071725')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#F8DD77')
          .borderRadius(16)
      }
      .padding(18)
      .backgroundColor('#071725')
      .borderRadius(20)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  accountSection() {
    Column({ space: 12 }) {
      Text('账号与密码')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      TextInput({ placeholder: '原密码', text: $$this.oldPassword })
        .type(InputType.Password)
        .height(42)
        .backgroundColor('#F8FAF5')
        .borderRadius(14)
        .padding({ left: 12, right: 12 })
      TextInput({ placeholder: '新密码', text: $$this.newPassword })
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

      Button('保存密码')
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

      if (this.message.length > 0) {
        Text(this.message)
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
    Column({ space: 10 }) {
      Text('收藏管理')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')
      Text('收藏食谱、浏览历史和同步状态会从用户中心接口实时读取。')
        .fontSize(13)
        .fontColor('#657064')
        .width('100%')
      Row({ space: 10 }) {
        this.infoTile('收藏', `${this.summary.favoriteCount}`)
        this.infoTile('历史', `${this.summary.historyCount}`)
        this.infoTile('同步', this.syncEnabled ? '开启' : '关闭')
      }
      .width('100%')

      Text(this.favoriteRecipes.length === 0 ? '暂无收藏食谱' : `最近收藏：${this.recipeNames(this.favoriteRecipes, 2)}`)
        .fontSize(13)
        .fontColor('#405146')
        .width('100%')
      Text(this.historyRecipes.length === 0 ? '暂无浏览历史' : `最近查看：${this.recipeNames(this.historyRecipes, 3)}`)
        .fontSize(13)
        .fontColor('#405146')
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

      Text('开启后可同步健康档案、收藏食谱和饮食记录，适配手机、平板等鸿蒙设备。')
        .fontSize(13)
        .fontColor('#657064')
        .lineHeight(20)
        .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  atomicCardPreview() {
    Column({ space: 12 }) {
      Text('原子化卡片预览')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')
      Column({ space: 8 }) {
        Text('今日摄入')
          .fontSize(13)
          .fontColor('#CFE3D4')
        Text(`${this.summary.todayCalories} / ${this.summary.targetCalories} 千卡`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFF6D5')
        Text(`推荐：${this.summary.recommendedRecipeName}`)
          .fontSize(13)
          .fontColor('#F8DD77')
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
  infoTile(label: string, value: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
      Text(label)
        .fontSize(12)
        .fontColor('#657064')
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor('#F8FAF5')
    .borderRadius(14)
  }

  private async savePassword() {
    if (this.oldPassword.trim().length === 0 || this.newPassword.trim().length === 0) {
      this.message = '请输入原密码和新密码';
      return;
    }
    if (this.newPassword.trim().length < 6) {
      this.message = '新密码至少 6 位';
      return;
    }
    if (this.newPassword.trim() !== this.confirmPassword.trim()) {
      this.message = '两次输入的新密码不一致';
      return;
    }

    this.isSavingPassword = true;
    try {
      const request: ChangePasswordRequest = {
        userId: ApiClient.currentUserId,
        oldPassword: this.oldPassword.trim(),
        newPassword: this.newPassword.trim()
      };
      await ApiClient.changePassword(request);
      this.oldPassword = '';
      this.newPassword = '';
      this.confirmPassword = '';
      this.message = '密码已更新';
    } catch (error) {
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '密码更新失败，请稍后重试';
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
      this.summary = {
        userId: this.summary.userId,
        displayName: this.summary.displayName,
        favoriteCount: this.summary.favoriteCount,
        historyCount: this.summary.historyCount,
        syncEnabled: isOn,
        todayCalories: this.summary.todayCalories,
        targetCalories: this.summary.targetCalories,
        recommendedRecipeName: this.summary.recommendedRecipeName
      };
      this.message = isOn ? '跨设备同步已开启' : '跨设备同步已关闭';
    } catch (error) {
      this.syncEnabled = previous;
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '同步设置保存失败';
    }
  }

  private recipeNames(recipes: Recipe[], limit: number): string {
    const names: string[] = [];
    const count = recipes.length > limit ? limit : recipes.length;
    for (let index = 0; index < count; index++) {
      names.push(recipes[index].name);
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

  private recommendedRecipeName(value: string, history: Recipe[]): string {
    if (value != null && value.length > 0) {
      return value;
    }
    if (history.length > 0) {
      return history[0].name;
    }
    return this.summary.recommendedRecipeName;
  }
}
