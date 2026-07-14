import { DietRecord, DietRecordRequest, MealType, Recipe, WeeklyReport } from '../common/Models';
import { MockData } from '../common/MockData';
import { ApiClient } from '../services/ApiClient';

interface NutritionTotals {
  calories: number;
  protein: number;
  fat: number;
  carbs: number;
  recordCount: number;
  recordDays: number;
}

interface NutritionMetric {
  label: string;
  value: number;
  target: number;
  unit: string;
  color: string;
}

interface MacroSlice {
  label: string;
  value: number;
  color: string;
}

@Component
export struct ReportPage {
  // InsightsPage 原有状态
  @State foodName: string = '';
  @State mealIndex: number = 1;
  @State calories: string = '';
  @State protein: string = '';
  @State fat: string = '';
  @State carbs: string = '';
  @State recipeMatches: Recipe[] = [];
  @State isLookingUpFood: boolean = false;
  @State allRecipes: Recipe[] = [];
  @State activeScope: number = 0;
  @State records: DietRecord[] = [];
  @State selectedDate: string = '';
  @State dateLabel: string = '选择日期（默认今天）';
  @State viewDate: string = '';
  @State viewDateLabel: string = '';
  @State todayTotals: NutritionTotals = {
    calories: 0,
    protein: 0,
    fat: 0,
    carbs: 0,
    recordCount: 0,
    recordDays: 0
  };
  @State weekTotals: NutritionTotals = {
    calories: 0,
    protein: 0,
    fat: 0,
    carbs: 0,
    recordCount: 0,
    recordDays: 0
  };
  @State message: string = '';
  @State isError: boolean = false;
  private pieSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private pieContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.pieSettings);
  private foodLookupVersion: number = 0;

  // 保留 health ReportPage 的 AI 建议功能
  @State report: WeeklyReport = MockData.weeklyReport;
  @State isLoading: boolean = false;
  @State weeklyMessage: string = '';

  // AI 单日分析状态
  @State aiAnalysis: string[] = [];
  @State aiAnalysisLoading: boolean = false;
  @State aiAnalysisError: string = '';
  @State aiAnalysisDate: string = '';

  // AI 单周分析状态
  @State aiWeeklyDate: string = '';
  @State aiWeeklyStart: string = '';
  @State aiWeeklyEnd: string = '';
  @State aiWeeklyHighlights: string[] = [];
  @State aiWeeklySuggestions: string[] = [];
  @State aiWeeklyLoading: boolean = false;
  @State aiWeeklyError: string = '';

  aboutToAppear() {
    const today = this.dateKey(new Date());
    this.selectedDate = today;
    this.dateLabel = `选择日期（当前：${this.selectedDate}）`;
    this.viewDate = today;
    this.viewDateLabel = `查看日期：${this.viewDate}（默认今天）`;
    this.aiAnalysisDate = this.viewDate;
    this.aiWeeklyDate = this.viewDate;
    this.aiWeeklyStart = this.weekStartKey(this.viewDate);
    this.aiWeeklyEnd = this.weekEndKey(this.viewDate);
    this.load();
    this.loadWeeklyReport();
    this.loadAllRecipes();
  }

  async loadAllRecipes() {
    await this.loadRecipesByMeal(this.mealTypeValue());
  }

  private async loadRecipesByMeal(mealType: MealType) {
    this.isLookingUpFood = true;
    try {
      this.allRecipes = await ApiClient.searchRecipes('', undefined, mealType);
    } catch (_err) {
      this.allRecipes = [];
    } finally {
      this.isLookingUpFood = false;
    }
    this.filterRecipeMatches(this.foodName);
  }

  async load() {
    try {
      this.records = await ApiClient.listDietRecords(ApiClient.currentUserId);
    } catch (error) {
      this.records = [];
      this.showError(ApiClient.lastError.length > 0 ? ApiClient.lastError : '饮食记录加载失败，请稍后重试');
    }
    this.recalculateTotals();
    this.drawMacroPie();
  }

  async loadWeeklyReport() {
    this.isLoading = true;
    try {
      this.report = await ApiClient.getWeeklyReport(ApiClient.currentUserId, MockData.mealPlan.assessment.target.dailyCalories, this.viewDate);
    } catch (error) {
      this.weeklyMessage = ApiClient.lastError.length > 0 ? ApiClient.lastError : '周报加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.header()
        this.recordForm()
        this.scopeDateBar()
        this.scopeTabs()
        this.recordHistory()
        this.summaryPanel()
        this.targetBarChart()
        this.macroPieChart()
        this.aiAnalyzeSection()
        this.aiSuggestionSection()
      }
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
    }
    .backgroundColor('#F4F7F1')
  }

  @Builder
  header() {
    Column({ space: 8 }) {
      Text('饮食记录与营养统计')
        .fontSize(25)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')
      Text('手动记录每日饮食，自动汇总今日与本周营养摄入')
        .fontSize(13)
        .fontColor('#657064')
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  recordForm() {
    Column({ space: 12 }) {
      Text('新增饮食')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Button(this.dateLabel)
        .height(44)
        .fontSize(13)
        .fontColor('#405146')
        .backgroundColor('#F8FAF5')
        .borderRadius(8)
        .width('100%')
        .onClick(() => {
          this.onDateSelect();
        })

      Row({ space: 8 }) {
        TextInput({ placeholder: '食物名称，例如 糙米鸡胸蔬菜碗', text: $$this.foodName })
          .height(44)
          .fontSize(14)
          .backgroundColor('#F8FAF5')
          .borderRadius(8)
          .padding({ left: 14, right: 14 })
          .layoutWeight(1)
          .onChange((text: string) => {
            this.onFoodNameChange(text);
          })
      }
      .width('100%')

      Column({ space: 8 }) {
        Row() {
          Text(this.foodName.trim().length === 0 ? '全部食物' :
            (this.isLookingUpFood ? '正在匹配菜品…' : '匹配的菜品'))
            .fontSize(12)
            .fontColor('#657064')
            .layoutWeight(1)
          Text('点击自动填入营养值')
            .fontSize(12)
            .fontColor('#156B45')
        }
        .width('100%')

        if (this.recipeMatches.length > 0) {
          List({ space: 6 }) {
            ForEach(this.recipeMatches, (recipe: Recipe) => {
              ListItem() {
                this.recipeOption(recipe)
              }
            })
          }
          .height(160)
          .width('100%')
          .divider({ strokeWidth: 0 })
          .scrollBar(BarState.Auto)
        } else {
          Text(this.foodName.trim().length === 0 ? '暂无食物数据' : '未匹配到菜品，可手动填写营养值')
            .fontSize(12)
            .fontColor('#9CA3AF')
            .padding({ top: 12, bottom: 12 })
            .width('100%')
            .textAlign(TextAlign.Center)
        }
      }
      .padding(10)
      .backgroundColor('#F8FAF5')
      .borderRadius(8)
      .width('100%')

      Row({ space: 8 }) {
        this.mealButton('早餐', 0)
        this.mealButton('午餐', 1)
        this.mealButton('晚餐', 2)
        this.mealButton('加餐', 3)
      }
      .width('100%')

      Row({ space: 8 }) {
        TextInput({ placeholder: '热量 kcal', text: $$this.calories })
          .type(InputType.Number)
          .height(42)
          .layoutWeight(1)
          .fontSize(14)
          .backgroundColor('#F8FAF5')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .onChange(() => {
            this.clearMessage();
          })
        TextInput({ placeholder: '蛋白质 g', text: $$this.protein })
          .type(InputType.Number)
          .height(42)
          .layoutWeight(1)
          .fontSize(14)
          .backgroundColor('#F8FAF5')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .onChange(() => {
            this.clearMessage();
          })
      }
      .width('100%')

      Row({ space: 8 }) {
        TextInput({ placeholder: '脂肪 g', text: $$this.fat })
          .type(InputType.Number)
          .height(42)
          .layoutWeight(1)
          .fontSize(14)
          .backgroundColor('#F8FAF5')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .onChange(() => {
            this.clearMessage();
          })
        TextInput({ placeholder: '碳水 g', text: $$this.carbs })
          .type(InputType.Number)
          .height(42)
          .layoutWeight(1)
          .fontSize(14)
          .backgroundColor('#F8FAF5')
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .onChange(() => {
            this.clearMessage();
          })
      }
      .width('100%')

      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(13)
          .fontColor(this.isError ? '#8B2418' : '#156B45')
          .padding({ left: 12, right: 12, top: 9, bottom: 9 })
          .backgroundColor(this.isError ? '#FFE8DE' : '#E8F4EC')
          .borderRadius(8)
          .width('100%')
      }

      Button('保存并更新统计')
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
    .borderRadius(8)
    .width('100%')
  }

  @Builder
  recipeOption(recipe: Recipe) {
    Row() {
      Column({ space: 3 }) {
        Text(recipe.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.mealTypeName(recipe.mealType)} · ${recipe.calories} kcal · 蛋白 ${recipe.proteinGram}g / 脂肪 ${recipe.fatGram}g / 碳水 ${recipe.carbohydrateGram}g`)
          .fontSize(12)
          .fontColor('#657064')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('填入')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#156B45')
    }
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .width('100%')
    .onClick(() => {
      this.applyRecipe(recipe);
    })
  }

  @Builder
  mealButton(label: string, index: number) {
      Button(label)
        .height(34)
        .layoutWeight(1)
        .fontSize(12)
        .fontColor(this.mealIndex === index ? '#FFF6D5' : '#405146')
        .backgroundColor(this.mealIndex === index ? '#156B45' : '#EEF4EA')
        .borderRadius(17)
        .onClick(async () => {
          this.mealIndex = index;
          this.clearMessage();
          await this.loadRecipesByMeal(this.mealTypeValue());
          this.filterRecipeMatches(this.foodName);
        })
  }

  private onViewDateSelect() {
    const defaultDate = new Date();
    DatePickerDialog.show({
      start: new Date('2020-01-01'),
      end: new Date('2030-12-31'),
      selected: this.parseDate(this.viewDate, defaultDate),
      onAccept: (value: DatePickerResult) => {
        const year = value.year ?? defaultDate.getFullYear();
        const month = this.pad2((value.month ?? 0) + 1);
        const day = this.pad2((value.day ?? 1));
        this.viewDate = `${year}-${month}-${day}`;
        this.viewDateLabel = `查看日期：${this.viewDate}`;
        this.aiAnalysisDate = this.viewDate;
        this.aiWeeklyDate = this.viewDate;
        this.aiWeeklyStart = this.weekStartKey(this.viewDate);
        this.aiWeeklyEnd = this.weekEndKey(this.viewDate);
        this.recalculateTotals();
        this.drawMacroPie();
      }
    });
  }

  @Builder
  scopeDateBar() {
    Row({ space: 8 }) {
      Button(this.viewDateLabel)
        .height(38)
        .fontSize(13)
        .fontColor('#405146')
        .backgroundColor('#F8FAF5')
        .borderRadius(8)
        .layoutWeight(1)
        .onClick(() => {
          this.onViewDateSelect();
        })
    }
    .width('100%')
  }

  @Builder
  scopeTabs() {
    Row({ space: 8 }) {
      this.scopeButton('今日', 0)
      this.scopeButton('本周', 1)
    }
    .padding(4)
    .backgroundColor('#E7EFE4')
    .borderRadius(8)
    .width('100%')
  }

  @Builder
  scopeButton(label: string, index: number) {
    Button(label)
      .height(38)
      .layoutWeight(1)
      .fontSize(15)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.activeScope === index ? '#FFF6D5' : '#405146')
      .backgroundColor(this.activeScope === index ? '#156B45' : Color.Transparent)
      .borderRadius(8)
      .onClick(() => {
        this.activeScope = index;
        this.drawMacroPie();
      })
  }

  @Builder
  summaryPanel() {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 4 }) {
          Text(this.activeScope === 0 ? '今日摄入' : '本周摄入')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor('#071725')
          Text(this.scopeDescription())
            .fontSize(12)
            .fontColor('#657064')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 2 }) {
          Text(`${this.activeTotals().recordCount}`)
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor('#156B45')
          Text('条记录')
            .fontSize(12)
            .fontColor('#657064')
        }
      }
      .width('100%')

      Row({ space: 10 }) {
        ForEach(this.metricList().slice(0, 2), (item: NutritionMetric) => {
          this.metricTile(item)
        })
      }
      .width('100%')

      Row({ space: 10 }) {
        ForEach(this.metricList().slice(2, 4), (item: NutritionMetric) => {
          this.metricTile(item)
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
  metricTile(item: NutritionMetric) {
    Column({ space: 6 }) {
      Row() {
        Text(item.label)
          .fontSize(12)
          .fontColor('#657064')
          .layoutWeight(1)
        Text(`${this.percent(item.value, item.target)}%`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
      }
      .width('100%')

      Text(`${item.value}`)
        .fontSize(23)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Text(`目标 ${item.target}${item.unit}`)
        .fontSize(12)
        .fontColor('#657064')
        .width('100%')

      Row()
        .height(4)
        .width(`${this.percent(item.value, item.target)}%`)
        .backgroundColor(item.color)
        .borderRadius(2)
    }
    .alignItems(HorizontalAlign.Start)
    .padding(12)
    .layoutWeight(1)
    .backgroundColor('#F8FAF5')
    .borderRadius(8)
  }

  @Builder
  targetBarChart() {
    Column({ space: 12 }) {
      Text('达标柱状图')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      ForEach(this.metricList(), (item: NutritionMetric) => {
        this.targetBar(item)
      })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .width('100%')
  }

  @Builder
  targetBar(item: NutritionMetric) {
    Column({ space: 6 }) {
      Row() {
        Text(item.label)
          .fontSize(13)
          .fontColor('#657064')
          .layoutWeight(1)
        Text(`${item.value}/${item.target}${item.unit}`)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
      }
      .width('100%')

      Stack({ alignContent: Alignment.Start }) {
        Row()
          .height(12)
          .width('100%')
          .backgroundColor('#EEF4EA')
          .borderRadius(6)
        Row()
          .height(12)
          .width(`${this.percent(item.value, item.target)}%`)
          .backgroundColor(item.color)
          .borderRadius(6)
      }
      .height(12)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  macroPieChart() {
    Column({ space: 12 }) {
      Text('三大营养素饼图')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Row({ space: 16 }) {
        Stack({ alignContent: Alignment.Center }) {
          Canvas(this.pieContext)
            .width(154)
            .height(154)
            .onReady(() => {
              this.drawMacroPie();
            })
          Column({ space: 2 }) {
            Text(`${this.macroTotal()}`)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#071725')
            Text('g')
              .fontSize(12)
              .fontColor('#657064')
          }
        }
        .width(154)
        .height(154)

        Column({ space: 10 }) {
          ForEach(this.macroSlices(), (item: MacroSlice) => {
            this.pieLegend(item)
          })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Text(this.macroTotal() === 0 ? '暂无营养素数据，保存记录后会生成占比。' : '饼图按蛋白质、脂肪、碳水的克数占比展示。')
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
  pieLegend(item: MacroSlice) {
    Row({ space: 8 }) {
      Text('')
        .width(10)
        .height(10)
        .backgroundColor(item.color)
        .borderRadius(5)
      Text(item.label)
        .fontSize(13)
        .fontColor('#657064')
        .layoutWeight(1)
      Text(`${item.value}g · ${this.macroPercent(item.value)}%`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
    }
    .width('100%')
  }

  @Builder
  recordHistory() {
    Column({ space: 10 }) {
      Row() {
        Text(this.activeScope === 0 ? '今日记录' : '本周记录')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .layoutWeight(1)
        Text(`共 ${this.activeHistoryRecords().length} 条`)
          .fontSize(12)
          .fontColor('#657064')
      }
      .width('100%')

      if (this.activeHistoryRecords().length === 0) {
        Text('暂无饮食记录')
          .fontSize(13)
          .fontColor('#657064')
          .width('100%')
      }

      Scroll() {
        Column({ space: 10 }) {
          ForEach(this.activeHistoryRecords(), (record: DietRecord) => {
            Column({ space: 4 }) {
              Row() {
                Text(record.foodName)
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#071725')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                Text(`${record.calories} kcal`)
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#156B45')
              }
              .width('100%')

              Row() {
                Text(`${this.formatRecordDate(record.eatenAt)} · ${this.mealTypeName(record.mealType)}`)
                  .fontSize(12)
                  .fontColor('#657064')
                  .layoutWeight(1)
                Text('删除')
                  .fontSize(12)
                  .fontColor('#D28A3A')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#FFF4E5')
                  .borderRadius(6)
                  .onClick(() => {
                    this.deleteRecord(record.id);
                  })
              }
              .width('100%')

              Row() {
                Text(`蛋白 ${record.proteinGram}g / 脂肪 ${record.fatGram}g / 碳水 ${record.carbohydrateGram}g`)
                  .fontSize(11)
                  .fontColor('#8B9A8F')
                  .layoutWeight(1)
              }
              .width('100%')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F8FAF5')
            .borderRadius(8)
            .width('100%')
          }, (record: DietRecord) => record.id)
        }
        .width('100%')
      }
      .height(360)
      .scrollable(ScrollDirection.Vertical)
      .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .width('100%')
  }

  private activeHistoryRecords(): DietRecord[] {
    const todayKey = this.viewDate.length > 0 ? this.viewDate : this.dateKey(new Date());
    if (this.activeScope === 0) {
      return this.records.filter((record: DietRecord) => this.recordDateKey(record) === todayKey);
    }
    const weekStart = this.weekStartKey(this.viewDate);
    const weekEnd = this.weekEndKey(this.viewDate);
    return this.records.filter((record: DietRecord) => {
      const recordKey = this.recordDateKey(record);
      return recordKey.length > 0 && recordKey >= weekStart && recordKey <= weekEnd;
    });
  }

  private async deleteRecord(id: string) {
    try {
      await ApiClient.deleteDietRecord(id, ApiClient.currentUserId);
      this.records = this.records.filter((record: DietRecord) => record.id !== id);
      this.recalculateTotals();
      this.drawMacroPie();
      this.message = '记录已删除';
      this.isError = false;
      const version = (AppStorage.get<number>('dietVersion') ?? 0) + 1;
      AppStorage.setOrCreate('dietVersion', version);
      await this.load();
      await this.loadWeeklyReport();
    } catch (error) {
      this.showError(ApiClient.lastError.length > 0 ? ApiClient.lastError : '删除失败，请稍后重试');
    }
  }

  @Builder
  aiSuggestionSection() {
    Column({ space: 12 }) {
      Row({ space: 6 }) {
        Text('🤖')
          .fontSize(18)
        Text('AI 单周分析')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
        Blank()
        Text('AI')
          .fontSize(9)
          .fontColor('#156B45')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('#E8F4EC')
          .borderRadius(8)
      }
      .width('100%')

      Text('选择一周内任意日期，AI 将分析该自然周（周一至周日）的饮食记录。')
        .fontSize(12)
        .fontColor('#657064')
        .width('100%')

      Row({ space: 8 }) {
        Button(this.aiWeeklyStart.length > 0 && this.aiWeeklyEnd.length > 0
          ? `分析周：${this.aiWeeklyStart} 至 ${this.aiWeeklyEnd}`
          : '点击选择分析日期')
          .height(42)
          .fontSize(13)
          .fontColor('#405146')
          .backgroundColor('#F8FAF5')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.onAiWeeklyDateSelect();
          })

        Button('生成单周报告')
          .height(42)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFF6D5')
          .backgroundColor('#156B45')
          .borderRadius(8)
          .onClick(() => {
            this.runAiWeeklyAnalysis();
          })
      }
      .width('100%')

      if (this.aiWeeklyLoading) {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(16)
            .height(16)
            .color('#156B45')
          Text('AI 正在生成周报...')
            .fontSize(12)
            .fontColor('#66706A')
        }
        .padding({ top: 8, bottom: 8 })
      }

      if (this.aiWeeklyError.length > 0) {
        Text(this.aiWeeklyError)
          .fontSize(12)
          .fontColor('#D28A3A')
          .padding(10)
          .backgroundColor('#FFF4E5')
          .borderRadius(8)
          .width('100%')
      }

      if (this.aiWeeklyHighlights.length > 0) {
        Column({ space: 8 }) {
          Text('趋势摘要')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#405146')
            .width('100%')

          ForEach(this.aiWeeklyHighlights, (item: string, index: number) => {
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
      }

      if (this.aiWeeklySuggestions.length > 0) {
        Column({ space: 8 }) {
          Text('改善建议')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#405146')
            .width('100%')

          ForEach(this.aiWeeklySuggestions, (item: string) => {
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
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .width('100%')
  }

  private async submitRecord() {
    if (this.foodName.trim().length === 0) {
      this.showError('请填写食物名称');
      return;
    }

    const caloriesValue = this.readNumber(this.calories);
    if (caloriesValue <= 0) {
      this.showError('请填写有效热量');
      return;
    }

    const targetDate = this.selectedDate.length > 0 ? this.selectedDate : this.dateKey(new Date());
    const mealType = this.mealTypeValue();
    const existsSameMeal = this.records.some((r: DietRecord) =>
      this.recordDateKey(r) === targetDate && r.mealType === mealType
    );
    if (existsSameMeal) {
      this.showError('该餐次已有记录，请先删除后再新增');
      return;
    }

    const record: DietRecordRequest = {
      userId: ApiClient.currentUserId,
      foodName: this.foodName.trim(),
      mealType: mealType,
      calories: caloriesValue,
      proteinGram: this.readNumber(this.protein),
      fatGram: this.readNumber(this.fat),
      carbohydrateGram: this.readNumber(this.carbs),
      eatenAt: this.selectedDate.length > 0 ? this.selectedDate : undefined
    };
    try {
      const savedRecord = await ApiClient.addDietRecord(record);
      this.records.unshift(savedRecord);
      this.recalculateTotals();
      this.activeScope = 0;
      this.drawMacroPie();
      this.foodName = '';
      this.clearNutritionInputs();
      this.filterRecipeMatches('');
      this.message = '记录成功，今日与本周统计已更新';
      this.isError = false;
      const version = (AppStorage.get<number>('dietVersion') ?? 0) + 1;
      AppStorage.setOrCreate('dietVersion', version);
      await this.load();
      await this.loadWeeklyReport();
    } catch (error) {
      this.showError(ApiClient.lastError.length > 0 ? ApiClient.lastError : '保存失败，请稍后重试');
    }
  }

  private async onFoodNameChange(text: string) {
    this.foodName = text;
    this.clearMessage();
    await this.filterRecipeMatchesAsync(text);
  }

  private async filterRecipeMatchesAsync(text: string) {
    const keyword = text.trim();
    const currentMealType = this.mealTypeValue();

    if (keyword.length === 0) {
      // 输入为空时，按当前餐次显示所有食物
      this.recipeMatches = this.allRecipes.filter((r: Recipe) => r.mealType === currentMealType);
      this.isLookingUpFood = false;
      return;
    }

    // 先从本地 allRecipes 过滤，快速响应：名称包含输入且餐次匹配
    const lowerKeyword = keyword.toLowerCase();
    const localMatches = this.allRecipes.filter((r: Recipe) =>
      r.mealType === currentMealType && r.name.toLowerCase().indexOf(lowerKeyword) >= 0
    );
    if (localMatches.length > 0) {
      this.recipeMatches = localMatches;
    }

    const lookupVersion = this.foodLookupVersion + 1;
    this.foodLookupVersion = lookupVersion;
    this.isLookingUpFood = true;
    try {
      const recipes = await ApiClient.searchRecipes(keyword, undefined, currentMealType);
      if (this.foodName.trim() !== keyword || this.foodLookupVersion !== lookupVersion) {
        return;
      }
      this.recipeMatches = recipes;
    } catch (error) {
      if (this.foodLookupVersion === lookupVersion && localMatches.length === 0) {
        this.recipeMatches = [];
      }
    } finally {
      if (this.foodLookupVersion === lookupVersion) {
        this.isLookingUpFood = false;
      }
    }
  }

  private filterRecipeMatches(text: string) {
    const keyword = text.trim();
    const currentMealType = this.mealTypeValue();
    if (keyword.length === 0) {
      this.recipeMatches = this.allRecipes.filter((r: Recipe) => r.mealType === currentMealType);
      this.isLookingUpFood = false;
      return;
    }
    const lowerKeyword = keyword.toLowerCase();
    this.recipeMatches = this.allRecipes.filter((r: Recipe) =>
      r.mealType === currentMealType && r.name.toLowerCase().indexOf(lowerKeyword) >= 0
    );
  }

  private applyRecipe(recipe: Recipe) {
    this.foodName = recipe.name;
    this.calories = `${recipe.calories}`;
    this.protein = `${recipe.proteinGram}`;
    this.fat = `${recipe.fatGram}`;
    this.carbs = `${recipe.carbohydrateGram}`;
    this.mealIndex = this.mealIndexFromType(recipe.mealType);
    this.filterRecipeMatches(recipe.name);
    this.isLookingUpFood = false;
    this.clearMessage();
  }

  private clearNutritionInputs() {
    this.calories = '';
    this.protein = '';
    this.fat = '';
    this.carbs = '';
  }

  private recalculateTotals() {
    const todayKey = this.viewDate.length > 0 ? this.viewDate : this.dateKey(new Date());
    const weekStart = this.weekStartKey(this.viewDate);
    const weekEnd = this.weekEndKey(this.viewDate);
    const today: NutritionTotals = this.emptyTotals();
    const week: NutritionTotals = this.emptyTotals();
    const weekDays: string[] = [];

    this.records.forEach((record: DietRecord) => {
      const recordKey = this.recordDateKey(record);
      if (recordKey === todayKey) {
        this.addRecord(today, record);
      }
      if (recordKey >= weekStart && recordKey <= weekEnd) {
        this.addRecord(week, record);
        if (weekDays.indexOf(recordKey) < 0) {
          weekDays.push(recordKey);
        }
      }
    });

    today.recordDays = today.recordCount > 0 ? 1 : 0;
    week.recordDays = weekDays.length;
    this.todayTotals = today;
    this.weekTotals = week;
  }

  private emptyTotals(): NutritionTotals {
    return {
      calories: 0,
      protein: 0,
      fat: 0,
      carbs: 0,
      recordCount: 0,
      recordDays: 0
    };
  }

  private addRecord(target: NutritionTotals, record: DietRecord) {
    target.calories += record.calories;
    target.protein += record.proteinGram;
    target.fat += record.fatGram;
    target.carbs += record.carbohydrateGram;
    target.recordCount += 1;
  }

  private activeTotals(): NutritionTotals {
    return this.activeScope === 0 ? this.todayTotals : this.weekTotals;
  }

  private metricList(): NutritionMetric[] {
    const totals = this.activeTotals();
    return [
      {
        label: '热量',
        value: totals.calories,
        target: this.targetCalories(),
        unit: 'kcal',
        color: '#F8DD77'
      },
      {
        label: '蛋白质',
        value: totals.protein,
        target: this.targetProtein(),
        unit: 'g',
        color: '#83C988'
      },
      {
        label: '脂肪',
        value: totals.fat,
        target: this.targetFat(),
        unit: 'g',
        color: '#E7A0B9'
      },
      {
        label: '碳水',
        value: totals.carbs,
        target: this.targetCarbs(),
        unit: 'g',
        color: '#76B7E8'
      }
    ];
  }

  private macroSlices(): MacroSlice[] {
    const totals = this.activeTotals();
    return [
      {
        label: '蛋白质',
        value: totals.protein,
        color: '#83C988'
      },
      {
        label: '脂肪',
        value: totals.fat,
        color: '#E7A0B9'
      },
      {
        label: '碳水',
        value: totals.carbs,
        color: '#76B7E8'
      }
    ];
  }

  private drawMacroPie() {
    const center = 77;
    const radius = 58;
    const slices = this.macroSlices();
    const total = this.macroTotal();

    this.pieContext.clearRect(0, 0, 154, 154);
    if (total <= 0) {
      this.pieContext.beginPath();
      this.pieContext.arc(center, center, radius, 0, Math.PI * 2);
      this.pieContext.fillStyle = '#EEF4EA';
      this.pieContext.fill();
      this.pieContext.beginPath();
      this.pieContext.arc(center, center, 34, 0, Math.PI * 2);
      this.pieContext.fillStyle = '#FFFFFF';
      this.pieContext.fill();
      return;
    }

    let start = -Math.PI / 2;
    slices.forEach((item: MacroSlice) => {
      const angle = Math.PI * 2 * item.value / total;
      this.pieContext.beginPath();
      this.pieContext.moveTo(center, center);
      this.pieContext.arc(center, center, radius, start, start + angle);
      this.pieContext.closePath();
      this.pieContext.fillStyle = item.color;
      this.pieContext.fill();
      start += angle;
    });

    this.pieContext.beginPath();
    this.pieContext.arc(center, center, 34, 0, Math.PI * 2);
    this.pieContext.fillStyle = '#FFFFFF';
    this.pieContext.fill();
  }

  private scopeDescription(): string {
    const todayKey = this.viewDate.length > 0 ? this.viewDate : this.dateKey(new Date());
    if (this.activeScope === 0) {
      return `${todayKey} 已记录 ${this.todayTotals.recordCount} 条`;
    }
    return `${this.weekStartKey(this.viewDate)} 至 ${this.weekEndKey(this.viewDate)}，已记录 ${this.weekTotals.recordDays} 天`;
  }

  private targetCalories(): number {
    return MockData.mealPlan.assessment.target.dailyCalories * this.scopeFactor();
  }

  private targetProtein(): number {
    return MockData.mealPlan.assessment.target.proteinGram * this.scopeFactor();
  }

  private targetFat(): number {
    return MockData.mealPlan.assessment.target.fatGram * this.scopeFactor();
  }

  private targetCarbs(): number {
    return MockData.mealPlan.assessment.target.carbohydrateGram * this.scopeFactor();
  }

  private scopeFactor(): number {
    return this.activeScope === 0 ? 1 : this.weekElapsedDays(this.viewDate);
  }

  private weekElapsedDays(dateStr: string): number {
    const date = this.parseDate(dateStr, new Date());
    const weekday = date.getDay();
    return weekday === 0 ? 7 : weekday;
  }

  private macroTotal(): number {
    const totals = this.activeTotals();
    return totals.protein + totals.fat + totals.carbs;
  }

  private macroPercent(value: number): number {
    const total = this.macroTotal();
    if (total <= 0) {
      return 0;
    }
    return Math.round(value * 100 / total);
  }

  private percent(value: number, target: number): number {
    if (target <= 0) {
      return 0;
    }
    return Math.min(100, Math.round(value * 100 / target));
  }

  private readNumber(value: string): number {
    const numberValue = Number(value);
    if (Number.isNaN(numberValue) || numberValue < 0) {
      return 0;
    }
    return Math.round(numberValue);
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

  private mealIndexFromType(type: MealType): number {
    if (type === MealType.BREAKFAST) {
      return 0;
    }
    if (type === MealType.DINNER) {
      return 2;
    }
    if (type === MealType.SNACK) {
      return 3;
    }
    return 1;
  }

  private mealTypeName(type: MealType): string {
    if (type === MealType.BREAKFAST) {
      return '早餐';
    }
    if (type === MealType.DINNER) {
      return '晚餐';
    }
    if (type === MealType.SNACK) {
      return '加餐';
    }
    return '午餐';
  }

  private formatRecordTime(value: string): string {
    if (value.length <= 16) {
      return value.replace('T', ' ');
    }
    return value.substring(0, 16).replace('T', ' ');
  }

  private formatRecordDate(value: string): string {
    if (value.length >= 10) {
      return value.substring(0, 10);
    }
    return value;
  }

  private recordDateKey(record: DietRecord): string {
    if (record.eatenAt.length >= 10) {
      return record.eatenAt.substring(0, 10);
    }
    return '';
  }

  private weekEndKey(dateStr: string): string {
    const date = this.parseDate(dateStr, new Date());
    const weekday = date.getDay();
    const offset = weekday === 0 ? 0 : 7 - weekday;
    const sunday = new Date(date.getTime());
    sunday.setDate(date.getDate() + offset);
    return this.dateKey(sunday);
  }

  private weekStartKey(dateStr: string): string {
    const date = this.parseDate(dateStr, new Date());
    const weekday = date.getDay();
    const offset = weekday === 0 ? 6 : weekday - 1;
    const monday = new Date(date.getTime());
    monday.setDate(date.getDate() - offset);
    return this.dateKey(monday);
  }

  private dateKey(date: Date): string {
    const month = this.pad2(date.getMonth() + 1);
    const day = this.pad2(date.getDate());
    return `${date.getFullYear()}-${month}-${day}`;
  }

  private pad2(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private showError(message: string) {
    this.message = message;
    this.isError = true;
  }

  private clearMessage() {
    this.message = '';
    this.isError = false;
  }

  private onDateSelect() {
    const defaultDate = new Date();
    DatePickerDialog.show({
      start: new Date('2020-01-01'),
      end: new Date('2030-12-31'),
      selected: this.parseDate(this.selectedDate, defaultDate),
      onAccept: (value: DatePickerResult) => {
        const year = value.year ?? defaultDate.getFullYear();
        // DatePickerResult.month is 0-based (0=Jan), so add 1
        const month = this.pad2((value.month ?? 0) + 1);
        const day = this.pad2((value.day ?? 1));
        this.selectedDate = `${year}-${month}-${day}`;
        this.dateLabel = `选择日期（当前：${this.selectedDate}）`;
      }
    });
  }

  private parseDate(dateStr: string, fallback: Date): Date {
    try {
      if (dateStr.length >= 10) {
        const parts = dateStr.substring(0, 10).split('-');
        const year = Number(parts[0]);
        // dateStr month is 1-based, Date constructor expects 0-based
        const month = Number(parts[1]) - 1;
        const day = Number(parts[2]);
        if (!Number.isNaN(year) && !Number.isNaN(month) && !Number.isNaN(day)) {
          return new Date(year, month, day);
        }
      }
    } catch (_) {
      // fallback
    }
    return fallback;
  }

  @Builder
  aiAnalyzeSection() {
    Column({ space: 12 }) {
      Row({ space: 6 }) {
        Text('🤖')
          .fontSize(18)
        Text('AI 单日分析')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
      }
      .width('100%')

      Text('选择日期，AI 将分析当天饮食记录的合理性并给出改善建议。')
        .fontSize(12)
        .fontColor('#657064')
        .width('100%')

      Row({ space: 8 }) {
        Button(this.aiAnalysisDate.length > 0 ? `分析日期：${this.aiAnalysisDate}` : '点击选择分析日期')
          .height(42)
          .fontSize(13)
          .fontColor('#405146')
          .backgroundColor('#F8FAF5')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.onAnalysisDateSelect();
          })

        Button('AI 分析')
          .height(42)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFF6D5')
          .backgroundColor('#156B45')
          .borderRadius(8)
          .onClick(() => {
            this.runAiAnalysis();
          })
      }
      .width('100%')

      if (this.aiAnalysisLoading) {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(16)
            .height(16)
            .color('#156B45')
          Text('AI 正在分析中...')
            .fontSize(12)
            .fontColor('#66706A')
        }
        .padding({ top: 8, bottom: 8 })
      }

      if (this.aiAnalysisError.length > 0) {
        Text(this.aiAnalysisError)
          .fontSize(12)
          .fontColor('#D28A3A')
          .padding(10)
          .backgroundColor('#FFF4E5')
          .borderRadius(8)
          .width('100%')
      }

      if (this.aiAnalysis.length > 0) {
        Column({ space: 8 }) {
          Text('分析结果')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#405146')
            .width('100%')

          ForEach(this.aiAnalysis, (item: string) => {
            Row({ space: 8 }) {
              Text('•')
                .fontSize(13)
                .fontColor('#156B45')
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
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .width('100%')
  }

  private onAnalysisDateSelect() {
    const defaultDate = new Date();
    const selected = this.aiAnalysisDate.length > 0
      ? this.parseDate(this.aiAnalysisDate, defaultDate)
      : defaultDate;
    DatePickerDialog.show({
      start: new Date('2020-01-01'),
      end: new Date('2030-12-31'),
      selected: selected,
      onAccept: (value: DatePickerResult) => {
        const year = value.year ?? defaultDate.getFullYear();
        // DatePickerResult.month is 0-based (0=Jan), so add 1
        const month = this.pad2((value.month ?? 0) + 1);
        const day = this.pad2((value.day ?? 1));
        this.aiAnalysisDate = `${year}-${month}-${day}`;
        this.aiAnalysisError = '';
      }
    });
  }

  private async runAiAnalysis() {
    if (this.aiAnalysisDate.length === 0) {
      this.aiAnalysisError = '请先选择要分析的日期';
      return;
    }
    this.aiAnalysisLoading = true;
    this.aiAnalysisError = '';
    this.aiAnalysis = [];

    try {
      const targetCal = MockData.mealPlan.assessment.target.dailyCalories;
      const targetProt = MockData.mealPlan.assessment.target.proteinGram;
      const targetFat = MockData.mealPlan.assessment.target.fatGram;
      const targetCarb = MockData.mealPlan.assessment.target.carbohydrateGram;

      // 调用后端 AI 单日分析 API
      const results = await ApiClient.aiAnalyzeDay(
        ApiClient.currentUserId,
        this.aiAnalysisDate,
        targetCal, targetProt, targetFat, targetCarb
      );
      this.aiAnalysis = results;
    } catch (error) {
      // 后端不可用时，本地兜底
      const dateRecords = this.records.filter((r: DietRecord) =>
        r.eatenAt.length >= 10 && r.eatenAt.substring(0, 10) === this.aiAnalysisDate
      );
      if (dateRecords.length === 0) {
        this.aiAnalysis = [`${this.aiAnalysisDate} 暂无饮食记录，请先添加记录后再进行分析。`];
        return;
      }
      let totalCal = 0, totalProt = 0, totalFat = 0, totalCarb = 0;
      const mealMap: Record<string, boolean> = { '早餐': false, '午餐': false, '晚餐': false, '加餐': false };
      dateRecords.forEach((r: DietRecord) => {
        totalCal += r.calories;
        totalProt += r.proteinGram;
        totalFat += r.fatGram;
        totalCarb += r.carbohydrateGram;
        mealMap[this.mealTypeName(r.mealType)] = true;
      });
      const targetCal = MockData.mealPlan.assessment.target.dailyCalories;
      const targetProt = MockData.mealPlan.assessment.target.proteinGram;
      const targetFat = MockData.mealPlan.assessment.target.fatGram;
      const targetCarb = MockData.mealPlan.assessment.target.carbohydrateGram;
      const results: string[] = [];
      const calPercent = Math.round(totalCal * 100 / targetCal);
      results.push(`${this.aiAnalysisDate} 共记录 ${dateRecords.length} 条饮食数据，总摄入 ${totalCal} kcal（目标 ${targetCal} kcal）。`);
      if (calPercent < 80) {
        results.push(`热量摄入偏低（${calPercent}%），建议适当增加主食和优质蛋白的摄入。`);
      } else if (calPercent > 110) {
        results.push(`热量摄入偏高（${calPercent}%），建议控制油脂和精制碳水的摄入。`);
      } else {
        results.push(`热量摄入接近目标（${calPercent}%），整体控制良好。`);
      }
      const protPercent = Math.round(totalProt * 100 / targetProt);
      if (protPercent < 70) {
        results.push(`蛋白质摄入不足（${protPercent}%），建议每餐搭配瘦肉、鱼虾、鸡蛋或豆制品。`);
      } else {
        results.push(`蛋白质摄入达标（${protPercent}%）。`);
      }
      if (!mealMap['早餐']) {
        results.push('缺少早餐记录，早餐是一天能量的起点，建议保持规律早餐习惯。');
      }
      if (!mealMap['午餐']) {
        results.push('缺少午餐记录，午餐建议搭配主食+蛋白+蔬菜。');
      }
      if (!mealMap['晚餐']) {
        results.push('缺少晚餐记录，晚餐建议清淡为主，避免高油高盐。');
      }
      if (totalCarb < targetCarb * 0.7) {
        results.push('碳水摄入偏低，可适当增加全谷物、薯类等优质碳水来源。');
      }
      if (totalFat > targetFat * 1.2) {
        results.push('脂肪摄入偏高，建议减少油炸食品，选择蒸煮等烹饪方式。');
      }
      results.push('（以上为本地分析结果，AI 实时分析暂时不可用，请稍后重试）');
      this.aiAnalysis = results;
    } finally {
      this.aiAnalysisLoading = false;
    }
  }

  private onAiWeeklyDateSelect() {
    const defaultDate = new Date();
    const selected = this.aiWeeklyDate.length > 0
      ? this.parseDate(this.aiWeeklyDate, defaultDate)
      : defaultDate;
    DatePickerDialog.show({
      start: new Date('2020-01-01'),
      end: new Date('2030-12-31'),
      selected: selected,
      onAccept: (value: DatePickerResult) => {
        const year = value.year ?? defaultDate.getFullYear();
        const month = this.pad2((value.month ?? 0) + 1);
        const day = this.pad2((value.day ?? 1));
        this.aiWeeklyDate = `${year}-${month}-${day}`;
        this.aiWeeklyStart = this.weekStartKey(this.aiWeeklyDate);
        this.aiWeeklyEnd = this.weekEndKey(this.aiWeeklyDate);
        this.aiWeeklyError = '';
      }
    });
  }

  private async runAiWeeklyAnalysis() {
    if (this.aiWeeklyDate.length === 0 || this.aiWeeklyStart.length === 0 || this.aiWeeklyEnd.length === 0) {
      this.aiWeeklyError = '请先选择要分析的日期';
      return;
    }
    this.aiWeeklyLoading = true;
    this.aiWeeklyError = '';
    this.aiWeeklyHighlights = [];
    this.aiWeeklySuggestions = [];

    try {
      const targetCalories = MockData.mealPlan.assessment.target.dailyCalories;

      // 先从后端获取周报数据（含 highlights），再调用 AI 获取建议
      const report = await ApiClient.getWeeklyReport(ApiClient.currentUserId, targetCalories, this.aiWeeklyDate);
      this.aiWeeklyHighlights = report.trendHighlights != null && report.trendHighlights.length > 0
        ? report.trendHighlights : [];

      // 调用后端 AI 单周建议 API
      const suggestions = await ApiClient.aiGetWeeklySuggestions(ApiClient.currentUserId, targetCalories, this.aiWeeklyDate);
      this.aiWeeklySuggestions = suggestions;
    } catch (error) {
      this.aiWeeklyError = ApiClient.lastError.length > 0 ? ApiClient.lastError : '周报生成失败，请稍后重试';
      // 本地兜底
      this.runLocalWeeklyAnalysis();
    } finally {
      this.aiWeeklyLoading = false;
    }
  }

  private runLocalWeeklyAnalysis() {
    const start = this.aiWeeklyStart;
    const end = this.aiWeeklyEnd;
    const targetCalories = MockData.mealPlan.assessment.target.dailyCalories;
    const targetProtein = MockData.mealPlan.assessment.target.proteinGram;
    const targetFat = MockData.mealPlan.assessment.target.fatGram;
    const targetCarb = MockData.mealPlan.assessment.target.carbohydrateGram;

    const weekRecords = this.records.filter((r: DietRecord) => {
      const recordKey = this.recordDateKey(r);
      return recordKey.length > 0 && recordKey >= start && recordKey <= end;
    });

    let recordDays = 0;
    let totalCalories = 0;
    let totalProtein = 0;
    let totalFat = 0;
    let totalCarbs = 0;
    let breakfastCount = 0;
    let lunchCount = 0;
    let dinnerCount = 0;
    let snackCount = 0;
    const dayMap: Map<string, boolean> = new Map();

    weekRecords.forEach((r: DietRecord) => {
      const recordKey = this.recordDateKey(r);
      if (!dayMap.has(recordKey)) {
        dayMap.set(recordKey, true);
        recordDays++;
      }
      totalCalories += r.calories;
      totalProtein += r.proteinGram;
      totalFat += r.fatGram;
      totalCarbs += r.carbohydrateGram;
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

    const averageCalories = recordDays === 0 ? 0 : Math.round(totalCalories / recordDays);
    const avgProtein = recordDays === 0 ? 0 : Math.round(totalProtein / recordDays);
    const avgFat = recordDays === 0 ? 0 : Math.round(totalFat / recordDays);
    const avgCarbs = recordDays === 0 ? 0 : Math.round(totalCarbs / recordDays);
    const calorieCompletionRate = targetCalories <= 0 ? 0 : Math.round(Math.min(100, averageCalories * 100 / targetCalories) * 10) / 10;
    const proteinCompletionRate = targetProtein <= 0 ? 0 : Math.round(Math.min(100, avgProtein * 100 / targetProtein) * 10) / 10;
    const recordDayRate = Math.round(recordDays * 1000 / 7) / 10;

    const highlights: string[] = [];
    highlights.push(`${start} 至 ${end} 共记录 ${recordDays}/7 天饮食数据，记录率 ${recordDayRate}%。`);
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
      suggestions.push('建议从本周开始记录三餐，系统会自动生成趋势分析。');
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

    if (this.aiWeeklyHighlights.length === 0) {
      this.aiWeeklyHighlights = highlights;
    }
    if (this.aiWeeklySuggestions.length === 0) {
      this.aiWeeklySuggestions = suggestions;
    }
  }

  private completionLabel(): string {
    return this.report.completionLevel != null && this.report.completionLevel.length > 0
      ? this.report.completionLevel
      : '暂无数据';
  }

  private safeNum(value: number | undefined): number {
    if (value == null || Number.isNaN(value)) {
      return 0;
    }
    return value;
  }
}
