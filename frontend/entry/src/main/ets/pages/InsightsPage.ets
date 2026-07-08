import { DietRecord, DietRecordRequest, MealType, NutritionSummary, WeeklyReport } from '../common/Models';
import { MockData } from '../common/MockData';
import { ApiClient } from '../services/ApiClient';

@Component
export struct InsightsPage {
  @State foodName: string = '';
  @State mealIndex: number = 1;
  @State calories: string = '';
  @State protein: string = '';
  @State fat: string = '';
  @State carbs: string = '';
  @State summary: NutritionSummary = MockData.summary;
  @State report: WeeklyReport = MockData.weeklyReport;
  @State records: DietRecord[] = [];
  @State message: string = '';

  aboutToAppear() {
    this.load();
  }

  async load() {
    const target = MockData.mealPlan.assessment.target.dailyCalories;
    this.summary = await ApiClient.getSummary(ApiClient.currentUserId, target);
    this.report = await ApiClient.getWeeklyReport(ApiClient.currentUserId, target);
    this.records = await ApiClient.listDietRecords(ApiClient.currentUserId);
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.header()
        this.recordForm()
        this.todayChart()
        this.weekReport()
        this.recordHistory()
      }
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
    }
    .backgroundColor('#F4F7F1')
  }

  @Builder
  header() {
    Column({ space: 8 }) {
      Text('营养统计')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
      Text('记录饮食、查看营养占比、追踪周报趋势')
        .fontSize(13)
        .fontColor('#657064')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  recordForm() {
    Column({ space: 12 }) {
      Text('新增饮食记录')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      TextInput({ placeholder: '食物名称，例如 糙米鸡胸蔬菜碗', text: $$this.foodName })
        .height(44)
        .fontSize(14)
        .backgroundColor('#F8FAF5')
        .borderRadius(14)
        .padding({ left: 14, right: 14 })

      Row({ space: 8 }) {
        this.mealButton('早餐', 0)
        this.mealButton('午餐', 1)
        this.mealButton('晚餐', 2)
        this.mealButton('加餐', 3)
      }
      .width('100%')

      Row({ space: 8 }) {
        this.numberInput('热量', this.calories, (value: string) => {
          this.calories = value;
        })
        this.numberInput('蛋白质', this.protein, (value: string) => {
          this.protein = value;
        })
      }
      .width('100%')

      Row({ space: 8 }) {
        this.numberInput('脂肪', this.fat, (value: string) => {
          this.fat = value;
        })
        this.numberInput('碳水', this.carbs, (value: string) => {
          this.carbs = value;
        })
      }
      .width('100%')

      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(13)
          .fontColor('#156B45')
          .padding(10)
          .backgroundColor('#E8F4EC')
          .borderRadius(10)
          .width('100%')
      }

      Button('保存记录')
        .height(46)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFF6D5')
        .backgroundColor('#071725')
        .borderRadius(23)
        .width('100%')
        .onClick(async () => {
          await this.submitRecord();
        })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  mealButton(label: string, index: number) {
    Button(label)
      .height(32)
      .fontSize(12)
      .fontColor(this.mealIndex === index ? '#FFF6D5' : '#405146')
      .backgroundColor(this.mealIndex === index ? '#156B45' : '#EEF4EA')
      .borderRadius(16)
      .onClick(() => {
        this.mealIndex = index;
      })
  }

  @Builder
  numberInput(label: string, value: string, onChange: (value: string) => void) {
    TextInput({ placeholder: label, text: value })
      .type(InputType.Number)
      .height(42)
      .layoutWeight(1)
      .fontSize(14)
      .backgroundColor('#F8FAF5')
      .borderRadius(14)
      .padding({ left: 12, right: 12 })
      .onChange((text: string) => {
        onChange(text);
      })
  }

  @Builder
  todayChart() {
    Column({ space: 12 }) {
      Row() {
        Text('今日营养达成')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .layoutWeight(1)
        Text(`${this.summary.calorieCompletion}%`)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#156B45')
      }
      .width('100%')

      this.bar('热量', this.summary.totalCalories, MockData.mealPlan.assessment.target.dailyCalories, '#F8DD77')
      this.bar('蛋白质', this.summary.totalProteinGram, MockData.mealPlan.assessment.target.proteinGram, '#A8D9A1')
      this.bar('脂肪', this.summary.totalFatGram, MockData.mealPlan.assessment.target.fatGram, '#E7B4C8')
      this.bar('碳水', this.summary.totalCarbohydrateGram, MockData.mealPlan.assessment.target.carbohydrateGram, '#93BFE8')

      Row({ space: 10 }) {
        this.pieItem('蛋白质', '#A8D9A1')
        this.pieItem('脂肪', '#E7B4C8')
        this.pieItem('碳水', '#93BFE8')
      }
      .width('100%')

      ForEach(this.summary.suggestions, (item: string) => {
        Text(item)
          .fontSize(13)
          .fontColor('#405146')
          .width('100%')
      })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  bar(label: string, value: number, target: number, color: string) {
    Column({ space: 6 }) {
      Row() {
        Text(label)
          .fontSize(13)
          .fontColor('#657064')
          .layoutWeight(1)
        Text(`${value}/${target}`)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
      }
      .width('100%')
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .height(10)
          .width('100%')
          .backgroundColor('#EEF4EA')
          .borderRadius(5)
        Row()
          .height(10)
          .width(`${this.percent(value, target)}%`)
          .backgroundColor(color)
          .borderRadius(5)
      }
      .height(10)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  pieItem(label: string, color: string) {
    Row({ space: 6 }) {
      Text('')
        .width(10)
        .height(10)
        .backgroundColor(color)
        .borderRadius(5)
      Text(label)
        .fontSize(12)
        .fontColor('#657064')
    }
  }

  @Builder
  weekReport() {
    Column({ space: 12 }) {
      Text('健康周报')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Row() {
        Column({ space: 4 }) {
          Text(this.report.completionLevel)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#156B45')
          Text(`${this.report.startDate} 至 ${this.report.endDate}`)
            .fontSize(12)
            .fontColor('#657064')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 2 }) {
          Text(`${this.report.averageCalories}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#071725')
          Text('日均千卡')
            .fontSize(12)
            .fontColor('#657064')
        }
      }
      .width('100%')

      ForEach(this.report.trendHighlights, (item: string) => {
        Text(item)
          .fontSize(13)
          .fontColor('#405146')
          .width('100%')
      })

      ForEach(this.report.aiSuggestions, (item: string) => {
        Text(`AI 建议：${item}`)
          .fontSize(13)
          .fontColor('#071725')
          .padding(12)
          .backgroundColor('#F4E8BA')
          .borderRadius(10)
          .width('100%')
      })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  recordHistory() {
    Column({ space: 10 }) {
      Text('饮食历史')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      if (this.records.length === 0) {
        Text('暂无历史记录')
          .fontSize(13)
          .fontColor('#657064')
          .width('100%')
      }

      ForEach(this.records.slice(0, 5), (record: DietRecord) => {
        Row() {
          Column({ space: 3 }) {
            Text(record.foodName)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#071725')
            Text(`${record.mealType} · ${record.proteinGram}g 蛋白质 · ${record.carbohydrateGram}g 碳水`)
              .fontSize(12)
              .fontColor('#657064')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text(`${record.calories} 千卡`)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#156B45')
        }
        .padding(12)
        .backgroundColor('#F8FAF5')
        .borderRadius(12)
        .width('100%')
      })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  private async submitRecord() {
    if (this.foodName.trim().length === 0 || this.calories.trim().length === 0) {
      this.message = '请填写食物名称和热量';
      return;
    }
    const record: DietRecordRequest = {
      userId: ApiClient.currentUserId,
      foodName: this.foodName.trim(),
      mealType: this.mealTypeValue(),
      calories: Number(this.calories),
      proteinGram: Number(this.protein),
      fatGram: Number(this.fat),
      carbohydrateGram: Number(this.carbs)
    };
    await ApiClient.addDietRecord(record);
    this.foodName = '';
    this.calories = '';
    this.protein = '';
    this.fat = '';
    this.carbs = '';
    this.message = '记录成功，统计已更新';
    await this.load();
  }

  private mealTypeValue(): MealType {
    if (this.mealIndex === 0) {
      return MealType.BREAKFAST;
    }
    if (this.mealIndex === 2) {
      return MealType.DINNER;
    }
    if (this.mealIndex === 3) {
      return MealType.SNACK;
    }
    return MealType.LUNCH;
  }

  private percent(value: number, target: number): number {
    if (target <= 0) {
      return 0;
    }
    return Math.min(100, Math.round(value * 100 / target));
  }
}
