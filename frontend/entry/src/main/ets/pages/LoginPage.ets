import { LoginRequest, RegisterRequest, UserSession } from '../common/Models';
import { ApiClient } from '../services/ApiClient';

@Component
export struct LoginPage {
  @Link isAuthed: boolean;
  @Link currentUserName: string;
  @State mode: number = 0;
  @State username: string = '';
  @State password: string = '';
  @State displayName: string = '';
  @State showPassword: boolean = false;
  @State errorMessage: string = '';

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Image($r('app.media.login_hero'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)

      if (this.mode === 0) {
        this.loginOverlay()
      } else {
        this.registerPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFC334')
  }

  @Builder
  loginOverlay() {
    Column() {
      Blank()
        .height('46.2%')

      Stack({ alignContent: Alignment.Start }) {
        if (this.username.length > 0) {
          Text(' ')
            .width(220)
            .height(34)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 68, top: 12 })
        }

        TextInput({ text: this.username })
          .type(InputType.Normal)
          .width('100%')
          .height(54)
          .fontSize(17)
          .fontColor('#142B3B')
          .backgroundColor(Color.Transparent)
          .padding({ left: 78, right: 18 })
          .onChange((text: string) => {
            this.username = text;
            this.errorMessage = '';
          })
      }
      .width('86%')
      .height(58)

      Blank()
        .height(18)

      Stack({ alignContent: Alignment.Start }) {
        if (this.password.length > 0) {
          Text(' ')
            .width(178)
            .height(34)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 68, top: 12 })
        }

        TextInput({ text: this.password })
          .type(this.showPassword ? InputType.Normal : InputType.Password)
          .width('100%')
          .height(54)
          .fontSize(17)
          .fontColor('#142B3B')
          .backgroundColor(Color.Transparent)
          .padding({ left: 78, right: 142 })
          .showPasswordIcon(false)
          .onChange((text: string) => {
            this.password = text;
            this.errorMessage = '';
          })

        Row() {
          Blank()
            .layoutWeight(1)

          Button('')
            .width(118)
            .height(52)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.showPassword = !this.showPassword;
            })
        }
        .width('100%')
        .height(58)
      }
      .width('86%')
      .height(58)

      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor('#A33122')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#FFF1EE')
          .borderRadius(8)
          .margin({ top: 8 })
      } else {
        Blank()
          .height(22)
      }

      Button('')
        .width('86%')
        .height(58)
        .backgroundColor(Color.Transparent)
        .onClick(async () => {
          await this.submit();
        })

      Blank()
        .layoutWeight(1)

      Button('')
        .width(190)
        .height(40)
        .backgroundColor(Color.Transparent)
        .margin({ bottom: 22 })
        .onClick(() => {
          this.toggleMode();
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  registerPanel() {
    Column({ space: 12 }) {
      Blank()
        .height('26%')

      Column({ space: 12 }) {
        Text('注册账号')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#142B3B')
          .width('100%')
          .textAlign(TextAlign.Center)

        this.inputBox('手机号 / 用户名', this.username, InputType.Normal, (value: string) => {
          this.username = value;
        })

        this.inputBox('昵称', this.displayName, InputType.Normal, (value: string) => {
          this.displayName = value;
        })

        this.inputBox('密码', this.password, this.showPassword ? InputType.Normal : InputType.Password, (value: string) => {
          this.password = value;
        })

        Button(this.showPassword ? '隐藏密码' : '显示密码')
          .height(36)
          .fontSize(14)
          .fontColor('#142B3B')
          .backgroundColor('#FFF7D7')
          .borderRadius(18)
          .onClick(() => {
            this.showPassword = !this.showPassword;
          })

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor('#A33122')
            .width('100%')
            .textAlign(TextAlign.Center)
        }

        Button('注册并进入')
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#142B3B')
          .borderRadius(24)
          .onClick(async () => {
            await this.submit();
          })

        Button('返回登录')
          .height(40)
          .fontSize(14)
          .fontColor('#142B3B')
          .backgroundColor('#FFFFFF')
          .onClick(() => {
            this.toggleMode();
          })
      }
      .width('86%')
      .padding(18)
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  inputBox(placeholder: string, value: string, inputType: InputType, onChange: (value: string) => void) {
    TextInput({ placeholder: placeholder, text: value })
      .type(inputType)
      .width('100%')
      .height(46)
      .fontSize(15)
      .fontColor('#142B3B')
      .placeholderColor('#A9ADB2')
      .backgroundColor('#F7F8FA')
      .borderRadius(23)
      .padding({ left: 16, right: 16 })
      .onChange((text: string) => {
        onChange(text);
        this.errorMessage = '';
      })
  }

  private toggleMode() {
    this.mode = this.mode === 0 ? 1 : 0;
    this.errorMessage = '';
  }

  private async submit() {
    const cleanUsername = this.username.trim();
    const cleanPassword = this.password.trim();
    const cleanDisplayName = this.displayName.trim();

    if (cleanUsername.length === 0 || cleanPassword.length === 0) {
      this.errorMessage = '请输入账号和密码';
      return;
    }

    try {
      if (this.mode === 0) {
        const request: LoginRequest = {
          username: cleanUsername,
          password: cleanPassword
        };
        const session = await ApiClient.login(request);
        this.finishAuth(session);
        return;
      }

      const request: RegisterRequest = {
        username: cleanUsername,
        password: cleanPassword,
        displayName: cleanDisplayName
      };
      const session = await ApiClient.register(request);
      this.finishAuth(session);
    } catch (error) {
      this.errorMessage = this.mode === 0 ? '登录失败，请检查账号或密码' : '注册失败，请更换账号后重试';
    }
  }

  private finishAuth(session: UserSession) {
    this.currentUserName = session.displayName.length > 0 ? session.displayName : session.username;
    this.isAuthed = true;
  }
}
