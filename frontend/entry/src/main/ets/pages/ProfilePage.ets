import {
  Gender,
  HealthAssessment,
  HealthGoal,
  HealthProfile,
  NutritionTarget
} from '../common/Models';
import { MockData } from '../common/MockData';
import { ApiClient } from '../services/ApiClient';

@Component
export struct ProfilePage {
  @State profile: HealthProfile = MockData.profile;
  @State assessment: HealthAssessment = MockData.mealPlan.assessment;
  @State chronicText: string = '';
  @State tabooText: string = '';
  @State tasteText: string = '';
  @State bmiValue: number = MockData.mealPlan.assessment.bmi;
  @State bmiLevelText: string = MockData.mealPlan.assessment.bmiLevel;
  @State dailyCalories: number = MockData.mealPlan.assessment.target.dailyCalories;
  @State proteinGram: number = MockData.mealPlan.assessment.target.proteinGram;
  @State fatGram: number = MockData.mealPlan.assessment.target.fatGram;
  @State carbohydrateGram: number = MockData.mealPlan.assessment.target.carbohydrateGram;
  @State macroRatioText: string = MockData.mealPlan.assessment.target.macroRatio;
  @State adviceItems: string[] = MockData.mealPlan.assessment.advices;
  @State portraitImageKey: string = '';
  @State portraitBmiRangeKey: string = '';
  @State portraitBmiCalloutText: string = '';
  @State portraitChronicCalloutText: string = '';
  @State portraitNutritionCalloutText: string = '';
  @State portraitGoalCalloutText: string = '';
  @State saveMessage: string = '';

  aboutToAppear() {
    this.load();
  }

  async load() {
    try {
      this.profile = await ApiClient.getProfile(ApiClient.currentUserId);
      this.saveMessage = '';
    } catch (error) {
      this.profile = MockData.profile;
      this.saveMessage = '后端暂不可用，已使用本地档案生成评估';
    }
    this.normalizeProfile();
    this.hydrateTextFields();
    this.rebuildAssessment();
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        this.header()
        this.basicSection()
        this.conditionSection()
        this.assessmentSection()
        this.portraitSection()
        this.saveSection()
      }
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
    }
    .backgroundColor('#F4F7F1')
  }

  @Builder
  header() {
    Column({ space: 6 }) {
      Text('AI 健康档案')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')
      Text('录入身体数据、慢病情况、饮食禁忌和健身目标，自动生成体能评估与健康画像')
        .fontSize(13)
        .fontColor('#657064')
        .lineHeight(20)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  basicSection() {
    Column({ space: 12 }) {
      Text('基础信息')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      this.numberRow('年龄', this.profile.age, '岁', (value: number) => {
        this.profile.age = value;
        this.rebuildAssessment();
      })
      this.numberRow('身高', this.profile.heightCm, 'cm', (value: number) => {
        this.profile.heightCm = value;
        this.rebuildAssessment();
      })
      this.numberRow('体重', this.profile.weightKg, 'kg', (value: number) => {
        this.profile.weightKg = value;
        this.rebuildAssessment();
      })

      Text('性别')
        .fontSize(14)
        .fontColor('#657064')
        .width('100%')
      Row({ space: 8 }) {
        this.genderButton('男', Gender.MALE)
        this.genderButton('女', Gender.FEMALE)
        this.genderButton('暂不设置', Gender.UNKNOWN)
      }
      .width('100%')

      Text('健身目标')
        .fontSize(14)
        .fontColor('#657064')
        .width('100%')
      Row({ space: 8 }) {
        this.goalButton('减脂', HealthGoal.FAT_LOSS)
        this.goalButton('增肌', HealthGoal.MUSCLE_GAIN)
        this.goalButton('均衡', HealthGoal.BALANCED)
      }
      .width('100%')
      Row({ space: 8 }) {
        this.goalButton('控糖', HealthGoal.BLOOD_SUGAR_CONTROL)
        this.goalButton('控压', HealthGoal.BLOOD_PRESSURE_CONTROL)
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  conditionSection() {
    Column({ space: 12 }) {
      Text('健康约束')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      this.textRow('慢病情况', '如：高血压、糖尿病、脂肪肝', this.chronicText, () => {
        this.rebuildAssessment();
      })
      this.textRow('饮食禁忌', '如：花生、海鲜、高盐、乳糖', this.tabooText, () => {
        this.rebuildAssessment();
      })
      this.textRow('口味偏好', '如：清淡、高蛋白、低碳', this.tasteText, () => {
        this.rebuildAssessment();
      })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  assessmentSection() {
    Column({ space: 12 }) {
      Row() {
        Text('体能评估')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .layoutWeight(1)
        Text(this.bmiLevelText)
          .fontSize(13)
          .fontColor('#071725')
          .padding({ left: 12, right: 12, top: 7, bottom: 7 })
          .backgroundColor('#F8DD77')
          .borderRadius(15)
      }
      .width('100%')

      Row({ space: 10 }) {
        this.bmiMetricTile()
        this.calorieMetricTile()
      }
      .width('100%')

      Text('营养摄入比例')
        .fontSize(14)
        .fontColor('#657064')
        .width('100%')
      this.proteinLine()
      this.fatLine()
      this.carbohydrateLine()
      Text(this.macroRatioText)
        .fontSize(13)
        .fontColor('#405146')
        .padding(12)
        .backgroundColor('#F8FAF5')
        .borderRadius(12)
        .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  portraitSection() {
    Column({ space: 10 }) {
      Text('健康画像')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      if (this.shouldShowVisualPortrait()) {
        this.healthPortrait()
      } else {
        Text(this.portraitText())
          .fontSize(14)
          .fontColor('#FFF6D5')
          .lineHeight(22)
          .padding(14)
          .backgroundColor('#071725')
          .borderRadius(14)
          .width('100%')

        ForEach(this.adviceItems, (item: string) => {
          Text(item)
            .fontSize(13)
            .fontColor('#405146')
            .lineHeight(20)
            .padding(12)
            .backgroundColor('#F8FAF5')
            .borderRadius(12)
            .width('100%')
        })
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  healthPortrait() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.portraitBodyImage()

      this.bmiPortraitCalloutBox()

      this.chronicPortraitCalloutBox()

      this.nutritionPortraitCalloutBox()

      this.goalPortraitCalloutBox()
    }
    .width('100%')
    .height(520)
    .backgroundColor('#FFFDF8')
    .border({ width: 1, color: '#F0E4D8' })
    .borderRadius(16)
    .clip(true)
  }

  @Builder
  portraitBodyImage() {
    if (this.portraitImageKey === 'male_bmi_0_18') {
      this.portraitImage($r('app.media.male_bmi_0_18'))
    } else if (this.portraitImageKey === 'male_bmi_18_22') {
      this.portraitImage($r('app.media.male_bmi_18_22'))
    } else if (this.portraitImageKey === 'male_bmi_22_24') {
      this.portraitImage($r('app.media.male_bmi_22_24'))
    } else if (this.portraitImageKey === 'male_bmi_24_30') {
      this.portraitImage($r('app.media.male_bmi_24_30'))
    } else if (this.portraitImageKey === 'male_bmi_30_plus') {
      this.portraitImage($r('app.media.male_bmi_30_plus'))
    } else if (this.portraitImageKey === 'female_bmi_0_18') {
      this.portraitImage($r('app.media.female_bmi_0_18'))
    } else if (this.portraitImageKey === 'female_bmi_18_22') {
      this.portraitImage($r('app.media.female_bmi_18_22'))
    } else if (this.portraitImageKey === 'female_bmi_22_24') {
      this.portraitImage($r('app.media.female_bmi_22_24'))
    } else if (this.portraitImageKey === 'female_bmi_24_30') {
      this.portraitImage($r('app.media.female_bmi_24_30'))
    } else if (this.portraitImageKey === 'female_bmi_30_plus') {
      this.portraitImage($r('app.media.female_bmi_30_plus'))
    }
  }

  @Builder
  portraitImage(imageResource: Resource) {
    Image(imageResource)
      .width(166)
      .height(420)
      .objectFit(ImageFit.Contain)
      .position({ x: 99, y: 54 })
  }

  @Builder
  bmiPortraitCalloutBox() {
    Text(this.portraitBmiCalloutText)
      .fontSize(12)
      .fontColor('#7C2416')
      .lineHeight(17)
      .padding({ left: 8, right: 8, top: 7, bottom: 7 })
      .backgroundColor('#FFF9F2')
      .border({ width: 1, color: '#E25B44' })
      .borderRadius(10)
      .width(132)
      .position({ x: 8, y: 58 })
  }

  @Builder
  chronicPortraitCalloutBox() {
    Text(this.portraitChronicCalloutText)
      .fontSize(12)
      .fontColor('#7C2416')
      .lineHeight(17)
      .padding({ left: 8, right: 8, top: 7, bottom: 7 })
      .backgroundColor('#FFF9F2')
      .border({ width: 1, color: '#E25B44' })
      .borderRadius(10)
      .width(116)
      .position({ x: 198, y: 58 })
  }

  @Builder
  nutritionPortraitCalloutBox() {
    Text(this.portraitNutritionCalloutText)
      .fontSize(12)
      .fontColor('#7C2416')
      .lineHeight(17)
      .padding({ left: 8, right: 8, top: 7, bottom: 7 })
      .backgroundColor('#FFF9F2')
      .border({ width: 1, color: '#E25B44' })
      .borderRadius(10)
      .width(138)
      .position({ x: 8, y: 346 })
  }

  @Builder
  goalPortraitCalloutBox() {
    Text(this.portraitGoalCalloutText)
      .fontSize(12)
      .fontColor('#7C2416')
      .lineHeight(17)
      .padding({ left: 8, right: 8, top: 7, bottom: 7 })
      .backgroundColor('#FFF9F2')
      .border({ width: 1, color: '#E25B44' })
      .borderRadius(10)
      .width(116)
      .position({ x: 198, y: 396 })
  }

  @Builder
  saveSection() {
    Column({ space: 10 }) {
      Button('保存健康档案')
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontColor('#FFF6D5')
        .backgroundColor('#156B45')
        .borderRadius(22)
        .onClick(async () => {
          await this.saveProfile();
        })

      if (this.saveMessage.length > 0) {
        Text(this.saveMessage)
          .fontSize(13)
          .fontColor('#156B45')
          .lineHeight(20)
          .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  numberRow(label: string, value: number, unit: string, onChange: (value: number) => void) {
    Row({ space: 10 }) {
      Text(label)
        .fontSize(15)
        .fontColor('#071725')
        .width(62)
      TextInput({ text: `${value}` })
        .type(InputType.Number)
        .height(42)
        .layoutWeight(1)
        .backgroundColor('#F8FAF5')
        .borderRadius(12)
        .padding({ left: 12, right: 12 })
        .onChange((text: string) => {
          const parsed = Number(text);
          if (!Number.isNaN(parsed) && parsed > 0) {
            onChange(parsed);
          }
        })
      Text(unit)
        .fontSize(13)
        .fontColor('#657064')
        .width(34)
    }
    .width('100%')
  }

  @Builder
  textRow(label: string, placeholder: string, text: string, onChange: () => void) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(14)
        .fontColor('#657064')
        .width('100%')
      TextInput({ placeholder: placeholder, text: text })
        .height(42)
        .fontSize(14)
        .backgroundColor('#F8FAF5')
        .borderRadius(12)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          if (label === '慢病情况') {
            this.chronicText = value;
          }
          if (label === '饮食禁忌') {
            this.tabooText = value;
          }
          if (label === '口味偏好') {
            this.tasteText = value;
          }
          onChange();
        })
    }
    .width('100%')
  }

  @Builder
  genderButton(label: string, gender: Gender) {
    Button(label)
      .height(36)
      .fontSize(13)
      .fontColor(this.profile.gender === gender ? '#FFF6D5' : '#405146')
      .backgroundColor(this.profile.gender === gender ? '#071725' : '#EEF4EA')
      .borderRadius(18)
      .layoutWeight(1)
      .onClick(() => {
        this.profile.gender = gender;
        this.rebuildAssessment();
      })
  }

  @Builder
  goalButton(label: string, goal: HealthGoal) {
    Button(label)
      .height(36)
      .fontSize(13)
      .fontColor(this.profile.goal === goal ? '#FFF6D5' : '#405146')
      .backgroundColor(this.profile.goal === goal ? '#071725' : '#EEF4EA')
      .borderRadius(18)
      .layoutWeight(1)
      .onClick(() => {
        this.profile.goal = goal;
        this.rebuildAssessment();
      })
  }

  @Builder
  bmiMetricTile() {
    Column({ space: 4 }) {
      Text(`${this.bmiValue}`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
      Text('BMI')
        .fontSize(12)
        .fontColor('#657064')
      Text(this.bmiLevelText)
        .fontSize(12)
        .fontColor('#156B45')
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding(12)
    .backgroundColor('#F8FAF5')
    .borderRadius(14)
  }

  @Builder
  calorieMetricTile() {
    Column({ space: 4 }) {
      Text(`${this.dailyCalories}`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
      Text('推荐热量')
        .fontSize(12)
        .fontColor('#657064')
      Text('千卡/日')
        .fontSize(12)
        .fontColor('#156B45')
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding(12)
    .backgroundColor('#F8FAF5')
    .borderRadius(14)
  }

  @Builder
  proteinLine() {
    Row() {
      Text('蛋白质')
        .fontSize(13)
        .fontColor('#657064')
        .width(58)
      Row()
        .height(10)
        .layoutWeight(1)
        .backgroundColor('#A8D9A1')
        .borderRadius(5)
      Text(`${this.proteinGram}g`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width(68)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }

  @Builder
  fatLine() {
    Row() {
      Text('脂肪')
        .fontSize(13)
        .fontColor('#657064')
        .width(58)
      Row()
        .height(10)
        .layoutWeight(1)
        .backgroundColor('#E7B4C8')
        .borderRadius(5)
      Text(`${this.fatGram}g`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width(68)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }

  @Builder
  carbohydrateLine() {
    Row() {
      Text('碳水')
        .fontSize(13)
        .fontColor('#657064')
        .width(58)
      Row()
        .height(10)
        .layoutWeight(1)
        .backgroundColor('#93BFE8')
        .borderRadius(5)
      Text(`${this.carbohydrateGram}g`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width(68)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }

  private hydrateTextFields() {
    this.chronicText = this.profile.chronicConditions.join('、');
    this.tabooText = this.profile.taboos.join('、');
    this.tasteText = this.profile.tastePreferences.join('、');
  }

  private normalizeProfile() {
    if (this.profile.chronicConditions == null) {
      this.profile.chronicConditions = [];
    }
    if (this.profile.taboos == null) {
      this.profile.taboos = [];
    }
    if (this.profile.tastePreferences == null) {
      this.profile.tastePreferences = [];
    }
    if (this.profile.gender == null) {
      this.profile.gender = Gender.UNKNOWN;
    }
    if (this.profile.goal == null) {
      this.profile.goal = HealthGoal.BALANCED;
    }
  }

  private rebuildAssessment() {
    this.profile.userId = ApiClient.currentUserId;
    this.profile.chronicConditions = this.splitTags(this.chronicText);
    this.profile.taboos = this.splitTags(this.tabooText);
    this.profile.tastePreferences = this.splitTags(this.tasteText);

    const bmi = this.calculateBmi();
    const bmiLevel = this.bmiLevel(bmi);
    const target = this.buildNutritionTarget();
    const advices = this.buildAdvices(bmiLevel, target);
    const nextAssessment: HealthAssessment = {
      bmi: bmi,
      bmiLevel: bmiLevel,
      target: target,
      advices: advices
    };
    this.bmiValue = bmi;
    this.bmiLevelText = bmiLevel;
    this.dailyCalories = target.dailyCalories;
    this.proteinGram = target.proteinGram;
    this.fatGram = target.fatGram;
    this.carbohydrateGram = target.carbohydrateGram;
    this.macroRatioText = target.macroRatio;
    this.adviceItems = advices;
    this.assessment = nextAssessment;
    this.refreshPortraitState();
    this.persistLocalAssessment();
  }

  private calculateBmi(): number {
    if (this.profile.heightCm <= 0 || this.profile.weightKg <= 0) {
      return 0;
    }
    const heightMeter = this.profile.heightCm / 100;
    return Number((this.profile.weightKg / (heightMeter * heightMeter)).toFixed(1));
  }

  private bmiLevel(bmi: number): string {
    if (bmi <= 0) {
      return '待完善';
    }
    if (bmi < 18.5) {
      return '偏瘦';
    }
    if (bmi < 24) {
      return '正常';
    }
    if (bmi < 28) {
      return '超重';
    }
    return '肥胖';
  }

  private buildNutritionTarget(): NutritionTarget {
    const baseCalories = this.calculateBaseCalories();
    const goalCalories = this.adjustCaloriesByGoal(baseCalories);
    const proteinRatio = this.proteinRatio();
    const fatRatio = this.fatRatio();
    const carbRatio = 1 - proteinRatio - fatRatio;
    const proteinGram = Math.round(goalCalories * proteinRatio / 4);
    const fatGram = Math.round(goalCalories * fatRatio / 9);
    const carbGram = Math.round(goalCalories * carbRatio / 4);
    const target: NutritionTarget = {
      dailyCalories: goalCalories,
      proteinGram: proteinGram,
      fatGram: fatGram,
      carbohydrateGram: carbGram,
      macroRatio: `蛋白质 ${Math.round(proteinRatio * 100)}% / 脂肪 ${Math.round(fatRatio * 100)}% / 碳水 ${Math.round(carbRatio * 100)}%`
    };
    return target;
  }

  private calculateBaseCalories(): number {
    const age = this.profile.age > 0 ? this.profile.age : 25;
    const height = this.profile.heightCm > 0 ? this.profile.heightCm : 170;
    const weight = this.profile.weightKg > 0 ? this.profile.weightKg : 65;
    let bmr = 10 * weight + 6.25 * height - 5 * age;
    if (this.profile.gender === Gender.FEMALE) {
      bmr -= 161;
    } else if (this.profile.gender === Gender.MALE) {
      bmr += 5;
    } else {
      bmr -= 78;
    }
    return Math.round(bmr * 1.45);
  }

  private adjustCaloriesByGoal(baseCalories: number): number {
    let calories = baseCalories;
    if (this.profile.goal === HealthGoal.FAT_LOSS) {
      calories -= 350;
    }
    if (this.profile.goal === HealthGoal.MUSCLE_GAIN) {
      calories += 250;
    }
    if (this.profile.goal === HealthGoal.BLOOD_SUGAR_CONTROL || this.profile.goal === HealthGoal.BLOOD_PRESSURE_CONTROL) {
      calories -= 150;
    }
    if (calories < 1200) {
      calories = 1200;
    }
    return Math.round(calories);
  }

  private proteinRatio(): number {
    if (this.profile.goal === HealthGoal.FAT_LOSS) {
      return 0.30;
    }
    if (this.profile.goal === HealthGoal.MUSCLE_GAIN) {
      return 0.28;
    }
    if (this.profile.goal === HealthGoal.BLOOD_SUGAR_CONTROL) {
      return 0.25;
    }
    return 0.22;
  }

  private fatRatio(): number {
    if (this.profile.goal === HealthGoal.BLOOD_SUGAR_CONTROL) {
      return 0.30;
    }
    if (this.profile.goal === HealthGoal.BLOOD_PRESSURE_CONTROL) {
      return 0.24;
    }
    return 0.25;
  }

  private buildAdvices(bmiLevel: string, target: NutritionTarget): string[] {
    const advices: string[] = [];
    advices.push(`BMI 评估为${bmiLevel}，每日推荐热量约 ${target.dailyCalories} 千卡。`);
    advices.push(`建议每日摄入蛋白质 ${target.proteinGram}g、脂肪 ${target.fatGram}g、碳水 ${target.carbohydrateGram}g。`);
    advices.push(this.goalAdvice());
    if (this.profile.chronicConditions.length > 0) {
      advices.push(`慢病关注：${this.profile.chronicConditions.join('、')}，食谱推荐会优先避开高风险饮食模式。`);
    }
    if (this.profile.taboos.length > 0) {
      advices.push(`饮食禁忌：${this.profile.taboos.join('、')}，推荐食谱需要过滤相关食材。`);
    }
    return advices;
  }

  private goalAdvice(): string {
    if (this.profile.goal === HealthGoal.FAT_LOSS) {
      return '减脂目标建议保持轻度热量缺口，优先保证蛋白质和蔬菜摄入。';
    }
    if (this.profile.goal === HealthGoal.MUSCLE_GAIN) {
      return '增肌目标建议配合力量训练，并在训练日前后补充优质碳水和蛋白质。';
    }
    if (this.profile.goal === HealthGoal.BLOOD_SUGAR_CONTROL) {
      return '控糖目标建议选择低 GI 主食，减少含糖饮料和精制碳水。';
    }
    if (this.profile.goal === HealthGoal.BLOOD_PRESSURE_CONTROL) {
      return '控压目标建议控制钠摄入，增加钾、镁丰富的蔬果和全谷物。';
    }
    return '均衡目标建议稳定三餐结构，保证蛋白质、优质脂肪和复合碳水比例。';
  }

  private refreshPortraitState() {
    const range = this.resolvePortraitBmiRange(this.bmiValue);
    this.portraitBmiRangeKey = range;
    this.portraitImageKey = this.resolvePortraitImageKey(this.profile.gender, range);
    this.portraitBmiCalloutText = `BMI评估：${this.resolvePortraitBmiLabel(range)}。${this.resolveBmiPortraitAdvice(range)}`;
    this.portraitChronicCalloutText = this.buildChronicPortraitCallout(range);
    this.portraitNutritionCalloutText =
      `建议摄入比例：${this.macroRatioText}。每日约蛋白质${this.proteinGram}g、脂肪${this.fatGram}g、碳水${this.carbohydrateGram}g。`;
    this.portraitGoalCalloutText = this.buildGoalPortraitCallout(range);
  }

  private shouldShowVisualPortrait(): boolean {
    return this.portraitImageKey.length > 0;
  }

  private resolvePortraitBmiRange(bmi: number): string {
    if (bmi <= 0) {
      return '';
    }
    if (bmi <= 18) {
      return '0_18';
    }
    if (bmi < 22) {
      return '18_22';
    }
    if (bmi < 24) {
      return '22_24';
    }
    if (bmi < 30) {
      return '24_30';
    }
    return '30_plus';
  }

  private resolvePortraitImageKey(gender: Gender, range: string): string {
    if (range.length === 0) {
      return '';
    }
    if (gender === Gender.MALE) {
      return `male_bmi_${range}`;
    }
    if (gender === Gender.FEMALE) {
      return `female_bmi_${range}`;
    }
    return '';
  }

  private resolvePortraitBmiLabel(range: string): string {
    if (range === '0_18') {
      return '偏瘦';
    }
    if (range === '18_22') {
      return '正常';
    }
    if (range === '22_24') {
      return '正常偏高';
    }
    if (range === '24_30') {
      return '超重';
    }
    if (range === '30_plus') {
      return '肥胖';
    }
    return '待完善';
  }

  private resolveBmiPortraitAdvice(range: string): string {
    if (range === '0_18') {
      return '建议稳定加餐，并配合力量训练逐步增重。';
    }
    if (range === '18_22') {
      return '状态较理想，建议保持规律饮食和稳定运动。';
    }
    if (range === '22_24') {
      return '接近偏高区间，建议控制甜饮、夜宵和久坐。';
    }
    if (range === '24_30') {
      return '建议建立轻度热量缺口，优先减少高油高糖摄入。';
    }
    return '建议先关注体脂管理，循序渐进降低总热量摄入。';
  }

  private buildChronicPortraitCallout(range: string): string {
    const chronicItems = this.splitTags(this.chronicText);
    let suffix = '保持规律体检，留意身体状态变化。';
    if (range === '0_18') {
      suffix = '增重期间保持规律体检，留意血脂和血糖变化。';
    } else if (range === '24_30' || range === '30_plus') {
      suffix = '重点关注血压、血脂、血糖和关节负担。';
    }
    if (chronicItems.length === 0) {
      return `慢病关注：暂无慢病标记。${suffix}`;
    }
    const keywordAdvice = this.chronicKeywordAdvice(chronicItems);
    if (keywordAdvice.length > 0) {
      return `慢病关注：${this.compactTags(chronicItems)}。${keywordAdvice}。`;
    }
    return `慢病关注：${this.compactTags(chronicItems)}。${suffix}`;
  }

  private chronicKeywordAdvice(items: string[]): string {
    const advices: string[] = [];
    items.forEach((item: string) => {
      const text = item.toLowerCase();
      if ((text.indexOf('高血压') >= 0 || text.indexOf('血压') >= 0) && advices.indexOf('少盐控钠，少吃腌制和高盐食物') < 0) {
        advices.push('少盐控钠，少吃腌制和高盐食物');
      } else if ((text.indexOf('糖尿病') >= 0 || text.indexOf('血糖') >= 0 || text.indexOf('控糖') >= 0) && advices.indexOf('选择低GI主食，减少甜饮和精制糖') < 0) {
        advices.push('选择低GI主食，减少甜饮和精制糖');
      } else if (text.indexOf('脂肪肝') >= 0 && advices.indexOf('控油控糖，避免酒精和油炸食物') < 0) {
        advices.push('控油控糖，避免酒精和油炸食物');
      } else if ((text.indexOf('高血脂') >= 0 || text.indexOf('血脂') >= 0 || text.indexOf('胆固醇') >= 0 || text.indexOf('甘油三酯') >= 0) && advices.indexOf('少动物油和反式脂肪，增加膳食纤维') < 0) {
        advices.push('少动物油和反式脂肪，增加膳食纤维');
      } else if ((text.indexOf('痛风') >= 0 || text.indexOf('尿酸') >= 0) && advices.indexOf('少酒精、内脏、浓汤和高嘌呤海鲜') < 0) {
        advices.push('少酒精、内脏、浓汤和高嘌呤海鲜');
      } else if ((text.indexOf('肾病') >= 0 || text.indexOf('肾功能') >= 0) && advices.indexOf('蛋白质和钠摄入需按医嘱控制') < 0) {
        advices.push('蛋白质和钠摄入需按医嘱控制');
      } else if ((text.indexOf('胃病') >= 0 || text.indexOf('胃炎') >= 0 || text.indexOf('胃溃疡') >= 0 || text.indexOf('反流') >= 0) && advices.indexOf('少刺激性食物，保持规律少量多餐') < 0) {
        advices.push('少刺激性食物，保持规律少量多餐');
      } else if (text.indexOf('贫血') >= 0 && advices.indexOf('增加铁和优质蛋白，搭配维C蔬果') < 0) {
        advices.push('增加铁和优质蛋白，搭配维C蔬果');
      }
    });
    return advices.slice(0, 2).join('；');
  }

  private buildGoalPortraitCallout(range: string): string {
    if (this.profile.goal === HealthGoal.FAT_LOSS) {
      if (range === '0_18') {
        return '健身目标：减脂。当前偏瘦，不建议继续减脂，可先增肌或均衡维护。';
      }
      return '健身目标：减脂。建议从低冲击有氧和力量训练开始，保持轻度热量缺口。';
    }
    if (this.profile.goal === HealthGoal.MUSCLE_GAIN) {
      if (range === '24_30' || range === '30_plus') {
        return '健身目标：增肌。建议先控体脂，再用力量训练保留和提升肌肉量。';
      }
      return '健身目标：增肌。建议每周3-4次力量训练，并保持轻度热量盈余。';
    }
    if (this.profile.goal === HealthGoal.BLOOD_SUGAR_CONTROL) {
      return '健身目标：控糖。优先选择低 GI 主食，用规律运动提升肌肉量和代谢稳定性。';
    }
    if (this.profile.goal === HealthGoal.BLOOD_PRESSURE_CONTROL) {
      if (range === '0_18') {
        return '健身目标：控压。增重时少靠高盐高油食物，搭配中低强度有氧和力量训练。';
      }
      return '健身目标：控压。建议低盐饮食，搭配中低强度有氧和力量训练。';
    }
    if (range === '0_18') {
      return `健身目标：${this.goalLabel()}。建议以增加优质蛋白、主食和规律训练为重点。`;
    }
    if (range === '18_22') {
      return `健身目标：${this.goalLabel()}。建议保持当前节奏，稳定三餐和运动频率。`;
    }
    if (range === '22_24') {
      return `健身目标：${this.goalLabel()}。建议减少久坐，增加日常步行和力量训练。`;
    }
    return `健身目标：${this.goalLabel()}。建议控制总热量，先从低冲击运动和规律作息开始。`;
  }

  private compactTags(items: string[]): string {
    if (items.length <= 3) {
      return items.join('、');
    }
    return `${items.slice(0, 3).join('、')}等`;
  }

  private portraitText(): string {
    const chronic = this.profile.chronicConditions.length === 0 ? '暂无慢病标记' : `关注${this.profile.chronicConditions.join('、')}`;
    const taboos = this.profile.taboos.length === 0 ? '暂无明确忌口' : `需避开${this.profile.taboos.join('、')}`;
    const tastes = this.profile.tastePreferences.length === 0 ? '偏好待完善' : `偏好${this.profile.tastePreferences.join('、')}`;
    return `${this.profile.age} 岁${this.genderLabel()}，BMI ${this.bmiValue}（${this.bmiLevelText}），目标为${this.goalLabel()}。${chronic}，${taboos}，${tastes}。建议以 ${this.dailyCalories} 千卡/日为基础管理饮食。`;
  }

  private splitTags(text: string): string[] {
    const normalized = text.replace(/[,，;；\s]+/g, '、');
    const parts = normalized.split('、');
    const result: string[] = [];
    parts.forEach((item: string) => {
      const clean = item.trim();
      if (clean.length > 0) {
        result.push(clean);
      }
    });
    return result;
  }

  private genderLabel(): string {
    if (this.profile.gender === Gender.MALE) {
      return '男性';
    }
    if (this.profile.gender === Gender.FEMALE) {
      return '女性';
    }
    return '用户';
  }

  private goalLabel(): string {
    if (this.profile.goal === HealthGoal.FAT_LOSS) {
      return '减脂';
    }
    if (this.profile.goal === HealthGoal.MUSCLE_GAIN) {
      return '增肌';
    }
    if (this.profile.goal === HealthGoal.BLOOD_SUGAR_CONTROL) {
      return '控糖';
    }
    if (this.profile.goal === HealthGoal.BLOOD_PRESSURE_CONTROL) {
      return '控压';
    }
    return '均衡健康';
  }

  private async saveProfile() {
    this.rebuildAssessment();
    try {
      await ApiClient.saveProfile(this.profile);
      this.saveMessage = '健康档案已保存，体能评估和营养目标已更新';
    } catch (error) {
      this.saveMessage = '后端暂不可用，已在本地更新健康档案和评估结果';
    }
  }

  private persistLocalAssessment() {
    MockData.profile = this.profile;
    MockData.mealPlan.assessment = this.assessment;
    MockData.mealPlan.estimatedIntake = this.assessment.target;
  }
}
