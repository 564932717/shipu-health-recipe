import { LoginRequest, RegisterRequest, UserSession } from '../common/Models';
import { ApiClient } from '../services/ApiClient';
import { DashboardPage } from './DashboardPage';
import { ProfilePage } from './ProfilePage';
import { RecipeHubPage } from './RecipeHubPage';
import { ReportPage } from './ReportPage';
import { UserCenterPage } from './UserCenterPage';

@Entry
@Component
struct Index {
  @State isAuthed: boolean = false;
  @State currentUserId: string = '';
  @State currentUserName: string = '';
  @State currentTabIndex: number = 0;
  @State panelMode: number = -1;

  aboutToAppear() {
    AppStorage.setOrCreate('favIds', []);
    AppStorage.setOrCreate('aiRecommendationLoading', false);
    AppStorage.setOrCreate('aiRecommendedRecipeNames', []);
  }
  @State loginUsername: string = '';
  @State loginPassword: string = '';
  @State registerUsername: string = '';
  @State registerPassword: string = '';
  @State registerConfirmPassword: string = '';
  @State showPassword: boolean = false;
  @State errorMessage: string = '';
  @State successMessage: string = '';
  @State topMessage: string = '';
  @State isSubmitting: boolean = false;

  build() {
    Stack() {
      if (!this.isAuthed) {
        this.loginScreen()
      } else {
        this.mainTabs()
      }

      if (this.topMessage.length > 0) {
        this.topNotice()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F8F3')
  }

  @Builder
  topNotice() {
    Column() {
      Text(this.topMessage)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F5132')
        .padding({ left: 18, right: 18, top: 10, bottom: 10 })
        .backgroundColor('#DFF6E7')
        .border({ width: 1, color: '#8FD8A8' })
        .borderRadius(18)
        .margin({ top: 58 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  loginScreen() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        Blank()
          .layoutWeight(1)

        Column({ space: 22 }) {
          this.loginHero()
          this.entryPanel()
        }
        .width('100%')

        Blank()
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 22, right: 22, top: 54, bottom: 42 })
      .backgroundColor('#F4F7F1')

      if (this.panelMode >= 0) {
        this.authPanel()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  loginHero() {
    Column({ space: 12 }) {
      Text('个性化健康食谱规划系统')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .textAlign(TextAlign.Center)
        .width('100%')

      Text('登录后继续记录饮食、管理食谱与查看营养统计')
        .fontSize(14)
        .fontColor('#657064')
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
  }

  @Builder
  entryPanel() {
    Column({ space: 14 }) {
      Column({ space: 6 }) {
        Text('欢迎使用')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .width('100%')
        Text('请选择登录或注册账号')
          .fontSize(13)
          .fontColor('#657064')
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ bottom: 4 })

      this.entryButton('登录', '已有账号，输入账号和密码', 0, true)
      this.entryButton('注册', '第一次使用，创建新账号', 1, false)
    }
    .padding({ left: 20, right: 20, top: 22, bottom: 22 })
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#E7EFE4' })
    .borderRadius(24)
    .width('100%')
  }

  @Builder
  entryButton(title: string, subtitle: string, mode: number, primary: boolean) {
    Row() {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(primary ? '#FFF6D5' : '#071725')
          .maxLines(1)
        Text(subtitle)
          .fontSize(12)
          .fontColor(primary ? '#DDEBDD' : '#657064')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
      .height('100%')

      Text('>')
        .fontSize(25)
        .fontColor(primary ? '#FFF6D5' : '#156B45')
        .width(24)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(62)
    .padding({ left: 16, right: 14 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(primary ? '#071725' : '#F8FAF5')
    .border({ width: primary ? 0 : 1, color: primary ? '#071725' : '#E7EFE4' })
    .borderRadius(16)
    .onClick(() => {
      this.openPanel(mode);
    })
  }
  @Builder
  authPanel() {
    Stack({ alignContent: Alignment.Center }) {
      Text('')
        .width('100%')
        .height('100%')
        .backgroundColor('#07172580')

      Column({ space: 14 }) {
        Row() {
          Column({ space: 4 }) {
            Text(this.panelMode === 0 ? '账号登录' : '账号注册')
              .fontSize(25)
              .fontWeight(FontWeight.Bold)
              .fontColor('#071725')
            Text(this.panelMode === 0 ? '登录后进入健康食谱规划系统' : '注册成功后需要重新登录')
              .fontSize(13)
              .fontColor('#5F6670')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('×')
            .width(36)
            .height(36)
            .fontSize(22)
            .lineHeight(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#156B45')
            .textAlign(TextAlign.Center)
            .backgroundColor('#E8F4EC')
            .borderRadius(18)
            .onClick(() => {
              this.closePanel();
            })
        }
        .width('100%')

        if (this.panelMode === 0) {
          Column({ space: 14 }) {
            TextInput({ placeholder: '用户名', text: $$this.loginUsername })
              .type(InputType.Normal)
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor('#071725')
              .placeholderColor('#657064')
              .backgroundColor('#F8FAF5')
              .border({ width: 1, color: '#E7EFE4' })
              .borderRadius(14)
              .padding({ left: 16, right: 16 })
              .onChange(() => {
                this.clearMessages();
              })

            TextInput({ placeholder: '密码', text: $$this.loginPassword })
              .type(this.showPassword ? InputType.Normal : InputType.Password)
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor('#071725')
              .placeholderColor('#657064')
              .backgroundColor('#F8FAF5')
              .border({ width: 1, color: '#E7EFE4' })
              .borderRadius(14)
              .padding({ left: 16, right: 16 })
              .showPasswordIcon(false)
              .onChange(() => {
                this.clearMessages();
              })
          }
          .width('100%')
        } else {
          Column({ space: 14 }) {
            TextInput({ placeholder: '用户名', text: $$this.registerUsername })
              .type(InputType.Normal)
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor('#071725')
              .placeholderColor('#657064')
              .backgroundColor('#F8FAF5')
              .border({ width: 1, color: '#E7EFE4' })
              .borderRadius(14)
              .padding({ left: 16, right: 16 })
              .onChange(() => {
                this.clearMessages();
              })

            TextInput({ placeholder: '密码', text: $$this.registerPassword })
              .type(this.showPassword ? InputType.Normal : InputType.Password)
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor('#071725')
              .placeholderColor('#657064')
              .backgroundColor('#F8FAF5')
              .border({ width: 1, color: '#E7EFE4' })
              .borderRadius(14)
              .padding({ left: 16, right: 16 })
              .showPasswordIcon(false)
              .onChange(() => {
                this.clearMessages();
              })

            TextInput({ placeholder: '确认密码', text: $$this.registerConfirmPassword })
              .type(this.showPassword ? InputType.Normal : InputType.Password)
              .width('100%')
              .height(48)
              .fontSize(16)
              .fontColor('#071725')
              .placeholderColor('#657064')
              .backgroundColor('#F8FAF5')
              .border({ width: 1, color: '#E7EFE4' })
              .borderRadius(14)
              .padding({ left: 16, right: 16 })
              .showPasswordIcon(false)
              .onChange(() => {
                this.clearMessages();
              })
          }
          .width('100%')
        }

        Row() {
          Button(this.showPassword ? '隐藏密码' : '显示密码')
            .height(34)
            .fontSize(13)
            .fontColor('#071725')
            .backgroundColor('#EEF4EA')
            .borderRadius(17)
            .onClick(() => {
              this.showPassword = !this.showPassword;
            })

          Blank()
        }
        .width('100%')

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor('#8B2418')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('#FFE8DE')
            .borderRadius(8)
            .width('100%')
        }

        if (this.successMessage.length > 0) {
          Text(this.successMessage)
            .fontSize(13)
            .fontColor('#156B45')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('#E8F4EC')
            .borderRadius(8)
            .width('100%')
        }

        Button(this.isSubmitting ? '处理中...' : (this.panelMode === 0 ? '登录' : '注册'))
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFF6D5')
          .backgroundColor('#071725')
          .borderRadius(24)
          .enabled(!this.isSubmitting)
          .onClick(async () => {
            await this.submit();
          })

        Button(this.panelMode === 0 ? '还没有账号？去注册' : '已有账号？去登录')
          .height(38)
          .fontSize(14)
          .fontColor('#071725')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.openPanel(this.panelMode === 0 ? 1 : 0);
          })
      }
      .width('84%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: '#E7EFE4' })
      .borderRadius(18)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  mainTabs() {
    Tabs({ barPosition: BarPosition.End, index: this.currentTabIndex }) {
      TabContent() {
        DashboardPage({ selectedTabIndex: $currentTabIndex })
      }
      .tabBar('首页')

      TabContent() {
        ProfilePage({ activeUserId: this.currentUserId })
      }
      .tabBar('档案')

      TabContent() {
        RecipeHubPage()
      }
      .tabBar('食谱')

      TabContent() {
        ReportPage()
      }
      .tabBar('统计')

      TabContent() {
        UserCenterPage({ isAuthed: $isAuthed })
      }
      .tabBar('我的')
    }
    .backgroundColor('#F6F8F3')
    .onChange((index: number) => {
      this.currentTabIndex = index;
    })
  }

  private openPanel(mode: number) {
    this.panelMode = mode;
    this.showPassword = false;
    if (mode === 0) {
      this.loginUsername = '';
      this.loginPassword = '';
    } else {
      this.registerUsername = '';
      this.registerPassword = '';
      this.registerConfirmPassword = '';
    }
    this.errorMessage = '';
    this.successMessage = '';
    this.topMessage = '';
    this.isSubmitting = false;
  }

  private closePanel() {
    this.panelMode = -1;
    this.errorMessage = '';
    this.successMessage = '';
    this.topMessage = '';
    this.isSubmitting = false;
  }

  private clearMessages() {
    this.errorMessage = '';
    this.successMessage = '';
    this.topMessage = '';
  }

  private async submit() {
    if (this.isSubmitting) {
      return;
    }

    const cleanUsername = this.panelMode === 0 ? this.loginUsername.trim() : this.registerUsername.trim();
    const cleanPassword = this.panelMode === 0 ? this.loginPassword.trim() : this.registerPassword.trim();
    const cleanConfirmPassword = this.registerConfirmPassword.trim();
    const isAdminLogin = this.panelMode === 0 && cleanUsername.toLowerCase() === 'admin';

    if (cleanUsername.length === 0 || (!isAdminLogin && cleanPassword.length === 0)) {
      this.errorMessage = '请输入用户名和密码';
      return;
    }

    if (this.panelMode === 1 && cleanPassword !== cleanConfirmPassword) {
      this.errorMessage = '两次输入的密码不一致';
      return;
    }

    this.isSubmitting = true;
    this.errorMessage = '';

    try {
      if (this.panelMode === 0) {
        const request: LoginRequest = {
          username: cleanUsername,
          password: cleanPassword
        };
        const session = await ApiClient.login(request);
        this.finishAuth(session);
      } else {
        const request: RegisterRequest = {
          username: cleanUsername,
          password: cleanPassword,
          displayName: cleanUsername
        };
        await ApiClient.register(request);
        this.panelMode = 0;
        this.loginUsername = '';
        this.loginPassword = '';
        this.registerUsername = '';
        this.registerPassword = '';
        this.registerConfirmPassword = '';
        this.errorMessage = '';
        this.successMessage = '';
        this.topMessage = '注册成功，请重新输入账号和密码登录';
      }
    } catch (error) {
      if (ApiClient.lastError.length > 0) {
        this.errorMessage = ApiClient.lastError;
      } else {
        this.errorMessage = this.panelMode === 0 ? '登录失败：请确认账号已注册且密码正确' : '注册失败：请更换用户名后重试';
      }
    } finally {
      this.isSubmitting = false;
    }
  }

  private finishAuth(session: UserSession) {
    this.currentUserId = session.userId;
    this.currentUserName = session.displayName.length > 0 ? session.displayName : session.username;
    this.currentTabIndex = 0;
    AppStorage.set('aiRecommendationLoading', false);
    AppStorage.set('aiRecommendedRecipeNames', []);
    this.isAuthed = true;
  }
}
