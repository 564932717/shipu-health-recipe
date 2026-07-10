import { WeeklyReport } from '../common/Models';
import { MockData } from '../common/MockData';
import { ApiClient } from '../services/ApiClient';

interface TrendPoint {
  label: string;
  value: number;
}

interface MacroRing {
  label: string;
  percent: number;
  value: number;
  color: string;
}

@Component
export struct ReportPage {
  @State report: WeeklyReport = MockData.weeklyReport;
  @State isLoading: boolean = false;
  @State message: string = '';
  private lineSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private lineContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.lineSettings);

  aboutToAppear() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      this.report = await ApiClient.getWeeklyReport(
        ApiClient.currentUserId,
        MockData.mealPlan.assessment.target.dailyCalories
      );
    } catch (error) {
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '周报加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.headerCard()
        this.overviewCard()
        this.trendChart()
        this.goalRingSection()
        this.macroBreakdownSection()
        this.mealDistributionSection()
        this.aiSuggestionSection()
        this.actionArea()
      }
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
    }
    .backgroundColor('#F4F7F1')
  }

  @Builder
  headerCard() {
    Row() {
      Column({ space: 6 }) {
        Text('健康周报')
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
        Text(`${this.report.startDate} 至 ${this.report.endDate}`)
          .fontSize(13)
          .fontColor('#657064')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 2 }) {
        Text(this.completionLabel())
          .fontSize(13)
          .fontColor('#156B45')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#E8F4EC')
          .borderRadius(14)
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }

  @Builder
  overviewCard() {
    Column({ space: 14 }) {
      Text('本周概览')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Row({ space: 10 }) {
        this.statTile('日均热量', `${this.report.averageCalories}`, 'kcal', '#F8DD77')
        this.statTile('记录天数', `${this.report.recordDays}/7`, '天', '#83C988')
        this.statTile('热量完成', `${this.report.calorieCompletionRate}`, '%', '#76B7E8')
        this.statTile('记录率', `${this.report.recordDayRate}`, '%', '#E7A0B9')
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .width('100%')
  }

  @Builder
  statTile(label: string, value: string, unit: string, color: string) {
    Column({ space: 4 }) {
      Row() {
        Text(value)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
        Text(unit)
          .fontSize(11)
          .fontColor('#657064')
          .margin({ left: 2 })
      }
      Text(label)
        .fontSize(11)
        .fontColor('#657064')
      Row()
        .height(3)
        .width('100%')
        .backgroundColor(color)
        .borderRadius(1.5)
    }
    .layoutWeight(1)
    .padding(10)
    .backgroundColor('#F8FAF5')
    .borderRadius(8)
  }

  @Builder
  trendChart() {
    Column({ space: 12 }) {
      Text('每日热量趋势')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Column({ space: 6 }) {
        Canvas(this.lineContext)
          .width('100%')
          .height(180)
          .onReady(() => {
            this.drawTrendLine();
          })

        Row({ space: 4 }) {
          ForEach(this.trendPoints(), (point: TrendPoint) => {
            Column({ space: 3 }) {
              Text(point.label)
                .fontSize(9)
                .fontColor('#657064')
                .textAlign(TextAlign.Center)
              Text('')
                .width(6)
                .height(6)
                .backgroundColor(point.value > 0 ? '#156B45' : '#CFE3D4')
                .borderRadius(3)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          })
        }
        .width('100%')
      }

      Text('橙色虚线为建议目标')
        .fontSize(11)
        .fontColor('#657064')
        .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .width('100%')
  }

  private drawTrendLine() {
    const points = this.trendPoints();
    const canvasWidth = 320;
    const canvasHeight = 180;
    const padLeft = 40;
    const padRight = 20;
    const padTop = 20;
    const padBottom = 30;
    const chartWidth = canvasWidth - padLeft - padRight;
    const chartHeight = canvasHeight - padTop - padBottom;

    const maxVal = Math.max(this.targetCalPerDay(), ...points.map((p: TrendPoint): number => p.value));
    const scale = chartHeight / (maxVal > 0 ? maxVal : 1);

    this.lineContext.clearRect(0, 0, canvasWidth, canvasHeight);

    const targetY = padTop + chartHeight - Math.round(this.targetCalPerDay() * scale);
    this.lineContext.beginPath();
    this.lineContext.setDash([6, 4]);
    this.lineContext.moveTo(padLeft, targetY);
    this.lineContext.lineTo(canvasWidth - padRight, targetY);
    this.lineContext.strokeStyle = '#F2B84B';
    this.lineContext.lineWidth = 1;
    this.lineContext.stroke();
    this.lineContext.setDash([]);

    this.lineContext.fillStyle = '#F2B84B';
    this.lineContext.font = '9px sans-serif';
    this.lineContext.fillText(`${this.targetCalPerDay()}kcal`, padLeft + 2, targetY - 4);

    for (let i = 0; i < points.length; i++) {
      const x = padLeft + Math.round(i * chartWidth / Math.max(points.length - 1, 1));
      const y = padTop + chartHeight - Math.round(points[i].value * scale);

      this.lineContext.beginPath();
      this.lineContext.arc(x, y, 4, 0, Math.PI * 2);
      this.lineContext.fillStyle = points[i].value > 0 ? '#156B45' : '#CFE3D4';
      this.lineContext.fill();

      if (points[i].value > 0) {
        this.lineContext.fillStyle = '#071725';
        this.lineContext.font = '10px sans-serif';
        const textW = this.lineContext.measureText(`${points[i].value}`).width;
        this.lineContext.fillText(`${points[i].value}`, x - textW / 2, y - 10);
      }
    }

    for (let i = 0; i < points.length - 1; i++) {
      const x1 = padLeft + Math.round(i * chartWidth / Math.max(points.length - 1, 1));
      const y1 = padTop + chartHeight - Math.round(points[i].value * scale);
      const x2 = padLeft + Math.round((i + 1) * chartWidth / Math.max(points.length - 1, 1));
      const y2 = padTop + chartHeight - Math.round(points[i + 1].value * scale);

      this.lineContext.beginPath();
      this.lineContext.moveTo(x1, y1);
      this.lineContext.lineTo(x2, y2);
      this.lineContext.strokeStyle = '#156B45';
      this.lineContext.lineWidth = 2;
      this.lineContext.stroke();
    }
  }

  @Builder
  goalRingSection() {
    Column({ space: 12 }) {
      Text('目标完成度')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Row({ space: 10 }) {
        ForEach(this.macroRings(), (item: MacroRing) => {
          Column({ space: 6 }) {
            Text(`${item.percent}%`)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(item.percent >= 80 ? '#156B45' : item.percent >= 50 ? '#D28A3A' : '#8B2418')

            Text(item.label)
              .fontSize(11)
              .fontColor('#657064')

            Stack({ alignContent: Alignment.Start }) {
              Row()
                .height(4)
                .width('100%')
                .backgroundColor('#EEF4EA')
                .borderRadius(2)
              Row()
                .height(4)
                .width(`${Math.min(item.percent, 100)}%`)
                .backgroundColor(item.color)
                .borderRadius(2)
            }
            .height(4)
            .width('100%')

            Text(`${item.value}g`)
              .fontSize(11)
              .fontColor('#657064')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding(10)
          .backgroundColor('#F8FAF5')
          .borderRadius(8)
        })
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .width('100%')
  }

  @Builder
  macroBreakdownSection() {
    Column({ space: 12 }) {
      Text('营养结构分析')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Column({ space: 10 }) {
        this.macroBar('蛋白质', this.report.avgProtein, this.targetProtein(), '#83C988', 'g')
        this.macroBar('脂肪', this.report.avgFat, this.targetFat(), '#E7A0B9', 'g')
        this.macroBar('碳水', this.report.avgCarbs, this.targetCarbs(), '#76B7E8', 'g')
      }
      .width('100%')

      Text(this.macroAdvice())
        .fontSize(12)
        .fontColor('#657064')
        .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .width('100%')
  }

  @Builder
  macroBar(label: string, actual: number, target: number, color: string, unit: string) {
    Column({ space: 4 }) {
      Row() {
        Text(label)
          .fontSize(13)
          .fontColor('#657064')
          .layoutWeight(1)
        Text(`${actual}/${target}${unit}`)
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
          .width(`${this.barPercent(actual, target)}%`)
          .backgroundColor(color)
          .borderRadius(5)
      }
      .height(10)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  mealDistributionSection() {
    Column({ space: 12 }) {
      Text('餐次分布')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Row({ space: 8 }) {
        this.mealTile('早餐', this.report.breakfastCount, '#F8DD77')
        this.mealTile('午餐', this.report.lunchCount, '#83C988')
        this.mealTile('晚餐', this.report.dinnerCount, '#E7A0B9')
        this.mealTile('加餐', this.report.snackCount, '#76B7E8')
      }
      .width('100%')

      if (this.report.breakfastCount === 0) {
        Text('提示：本周缺少早餐记录，规律三餐有益健康。')
          .fontSize(12)
          .fontColor('#D28A3A')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#FFF3E0')
          .borderRadius(8)
          .width('100%')
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .width('100%')
  }

  @Builder
  mealTile(label: string, count: number, color: string) {
    Column({ space: 4 }) {
      Text(`${count}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
      Text(label)
        .fontSize(11)
        .fontColor('#657064')
      Row()
        .height(3)
        .width('100%')
        .backgroundColor(count > 0 ? color : '#EEF4EA')
        .borderRadius(1.5)
    }
    .layoutWeight(1)
    .padding(10)
    .backgroundColor('#F8FAF5')
    .borderRadius(8)
  }

  @Builder
  aiSuggestionSection() {
    Column({ space: 12 }) {
      Row({ space: 6 }) {
        Text('🤖')
          .fontSize(18)
        Text('AI 改善建议')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
      }
      .width('100%')

      Column({ space: 8 }) {
        Text('趋势摘要')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#405146')
          .width('100%')

        ForEach(this.report.trendHighlights, (item: string, index: number) => {
          Row({ space: 8 }) {
            Text(`${index + 1}`)
              .fontSize(11)
              .fontColor('#156B45')
              .backgroundColor('#E8F4EC')
              .borderRadius(9)
              .width(18)
              .height(18)
              .textAlign(TextAlign.Center)
            Text(item)
              .fontSize(13)
              .fontColor('#4D5A50')
              .layoutWeight(1)
          }
          .width('100%')
        })
      }
      .padding(14)
      .backgroundColor('#F8FAF5')
      .borderRadius(8)
      .width('100%')

      Column({ space: 8 }) {
        Text('改善建议')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#405146')
          .width('100%')

        ForEach(this.report.aiSuggestions, (item: string, index: number) => {
          Row({ space: 8 }) {
            Text('✓')
              .fontSize(13)
              .fontColor('#156B45')
              .fontWeight(FontWeight.Bold)
            Text(item)
              .fontSize(13)
              .fontColor('#4D5A50')
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ top: 4, bottom: 4 })
        })
      }
      .padding(14)
      .backgroundColor('#F0F7EB')
      .borderRadius(8)
      .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .width('100%')
  }

  @Builder
  actionArea() {
    Column({ space: 10 }) {
      Text('快捷操作')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Button('刷新周报')
        .height(44)
        .fontSize(15)
        .fontColor('#FFF6D5')
        .backgroundColor('#071725')
        .borderRadius(22)
        .width('100%')
        .onClick(async () => {
          await this.load();
        })

      if (this.isLoading) {
        Text('加载中...')
          .fontSize(13)
          .fontColor('#657064')
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(13)
          .fontColor('#8B2418')
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .width('100%')
  }

  private trendPoints(): TrendPoint[] {
    const dayOrder: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    const points: TrendPoint[] = [];
    dayOrder.forEach((day: string) => {
      points.push({
        label: day,
        value: this.report.dailyCalories != null ? (this.report.dailyCalories[day] ?? 0) : 0
      });
    });
    return points;
  }

  private targetCalPerDay(): number {
    return MockData.mealPlan.assessment.target.dailyCalories;
  }

  private targetProtein(): number {
    return MockData.mealPlan.assessment.target.proteinGram;
  }

  private targetFat(): number {
    return MockData.mealPlan.assessment.target.fatGram;
  }

  private targetCarbs(): number {
    return MockData.mealPlan.assessment.target.carbohydrateGram;
  }

  private macroRings(): MacroRing[] {
    return [
      {
        label: '热量',
        percent: Math.round(this.safeNum(this.report.calorieCompletionRate)),
        value: this.safeNum(this.report.averageCalories),
        color: '#F8DD77'
      },
      {
        label: '蛋白质',
        percent: Math.round(this.safeNum(this.report.proteinCompletionRate)),
        value: this.safeNum(this.report.avgProtein),
        color: '#83C988'
      },
      {
        label: '脂肪',
        percent: Math.round(this.safeNum(this.report.fatCompletionRate)),
        value: this.safeNum(this.report.avgFat),
        color: '#E7A0B9'
      },
      {
        label: '碳水',
        percent: Math.round(this.safeNum(this.report.carbCompletionRate)),
        value: this.safeNum(this.report.avgCarbs),
        color: '#76B7E8'
      }
    ];
  }

  private completionLabel(): string {
    return this.report.completionLevel != null && this.report.completionLevel.length > 0
      ? this.report.completionLevel
      : '暂无数据';
  }

  private barPercent(value: number, target: number): number {
    if (target <= 0) {
      return 0;
    }
    return Math.min(100, Math.round(value * 100 / target));
  }

  private safeNum(value: number | undefined): number {
    if (value == null || Number.isNaN(value)) {
      return 0;
    }
    return value;
  }

  private macroAdvice(): string {
    const proteinRate = this.safeNum(this.report.proteinCompletionRate);
    const fatRate = this.safeNum(this.report.fatCompletionRate);
    const carbRate = this.safeNum(this.report.carbCompletionRate);
    if (proteinRate < 70) {
      return '蛋白质摄入偏少，建议每餐搭配鸡蛋、鱼虾或豆制品。';
    }
    if (carbRate > 120) {
      return '碳水摄入偏高，建议用粗粮替代精制主食。';
    }
    return '三大营养素结构整体均衡，继续保持。';
  }
}