import { DietRecord, DietRecordRequest, MealType, Recipe } from '../common/Models';
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
export struct InsightsPage {
  @State foodName: string = '';
  @State mealIndex: number = 1;
  @State calories: string = '';
  @State protein: string = '';
  @State fat: string = '';
  @State carbs: string = '';
  @State recipeMatches: Recipe[] = [];
  @State matchedRecipeName: string = '';
  @State isLookingUpFood: boolean = false;
  @State activeScope: number = 0;
  @State records: DietRecord[] = [];
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

  aboutToAppear() {
    this.load();
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

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.header()
        this.recordForm()
        this.scopeTabs()
        this.summaryPanel()
        this.targetBarChart()
        this.macroPieChart()
        this.recordHistory()
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

      TextInput({ placeholder: '食物名称，例如 糙米鸡胸蔬菜碗', text: $$this.foodName })
        .height(44)
        .fontSize(14)
        .backgroundColor('#F8FAF5')
        .borderRadius(8)
        .padding({ left: 14, right: 14 })
        .onChange((text: string) => {
          this.onFoodNameChange(text);
        })

      if (this.matchedRecipeName.length > 0) {
        Text(`已自动带出：${this.matchedRecipeName}`)
          .fontSize(12)
          .fontColor('#156B45')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#E8F4EC')
          .borderRadius(8)
          .width('100%')
      }

      if (this.recipeMatches.length > 0) {
        Column({ space: 8 }) {
          Row() {
            Text(this.isLookingUpFood ? '正在匹配菜品' : '选择数据库菜品')
              .fontSize(12)
              .fontColor('#657064')
              .layoutWeight(1)
            Text('点击自动填入营养值')
              .fontSize(12)
              .fontColor('#156B45')
          }
          .width('100%')

          ForEach(this.recipeMatches.slice(0, 4), (recipe: Recipe) => {
            this.recipeOption(recipe)
          })
        }
        .padding(10)
        .backgroundColor('#F8FAF5')
        .borderRadius(8)
        .width('100%')
      }

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
      .onClick(() => {
        this.mealIndex = index;
        this.clearMessage();
      })
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
        Text('最近记录')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .layoutWeight(1)
        Text(`共 ${this.records.length} 条`)
          .fontSize(12)
          .fontColor('#657064')
      }
      .width('100%')

      if (this.records.length === 0) {
        Text('暂无饮食记录')
          .fontSize(13)
          .fontColor('#657064')
          .width('100%')
      }

      ForEach(this.records.slice(0, 8), (record: DietRecord) => {
        Row() {
          Column({ space: 4 }) {
            Text(record.foodName)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#071725')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(`${this.mealTypeName(record.mealType)} · ${this.formatRecordTime(record.eatenAt)} · 蛋白 ${record.proteinGram}g / 脂肪 ${record.fatGram}g / 碳水 ${record.carbohydrateGram}g`)
              .fontSize(12)
              .fontColor('#657064')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text(`${record.calories} kcal`)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#156B45')
        }
        .padding(12)
        .backgroundColor('#F8FAF5')
        .borderRadius(8)
        .width('100%')
      })
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

    const record: DietRecordRequest = {
      userId: ApiClient.currentUserId,
      foodName: this.foodName.trim(),
      mealType: this.mealTypeValue(),
      calories: caloriesValue,
      proteinGram: this.readNumber(this.protein),
      fatGram: this.readNumber(this.fat),
      carbohydrateGram: this.readNumber(this.carbs)
    };
    try {
      const savedRecord = await ApiClient.addDietRecord(record);
      this.records.unshift(savedRecord);
      this.recalculateTotals();
      this.activeScope = 0;
      this.drawMacroPie();
      this.foodName = '';
      this.clearNutritionInputs();
      this.recipeMatches = [];
      this.matchedRecipeName = '';
      this.message = '记录成功，今日与本周统计已更新';
      this.isError = false;
      await this.load();
    } catch (error) {
      this.showError(ApiClient.lastError.length > 0 ? ApiClient.lastError : '保存失败，请稍后重试');
    }
  }

  private async onFoodNameChange(text: string) {
    this.foodName = text;
    this.clearMessage();
    if (this.matchedRecipeName.length > 0 && text.trim() !== this.matchedRecipeName) {
      this.clearNutritionInputs();
    }
    this.matchedRecipeName = '';

    const keyword = text.trim();
    const lookupVersion = this.foodLookupVersion + 1;
    this.foodLookupVersion = lookupVersion;
    if (keyword.length === 0) {
      this.recipeMatches = [];
      this.isLookingUpFood = false;
      return;
    }

    this.isLookingUpFood = true;
    try {
      const recipes = await ApiClient.searchRecipes(keyword);
      if (this.foodName.trim() !== keyword || this.foodLookupVersion !== lookupVersion) {
        return;
      }
      this.recipeMatches = recipes.slice(0, 6);
      const exactRecipe = this.findExactRecipe(recipes, keyword);
      if (exactRecipe != null) {
        this.applyRecipe(exactRecipe);
        return;
      }
      if (recipes.length === 1) {
        this.applyRecipe(recipes[0]);
      }
    } catch (error) {
      if (this.foodLookupVersion === lookupVersion) {
        this.recipeMatches = [];
      }
    } finally {
      if (this.foodLookupVersion === lookupVersion) {
        this.isLookingUpFood = false;
      }
    }
  }

  private findExactRecipe(recipes: Recipe[], keyword: string): Recipe | null {
    for (let index = 0; index < recipes.length; index++) {
      const recipe = recipes[index];
      if (recipe.name === keyword) {
        return recipe;
      }
    }
    return null;
  }

  private applyRecipe(recipe: Recipe) {
    this.foodName = recipe.name;
    this.calories = `${recipe.calories}`;
    this.protein = `${recipe.proteinGram}`;
    this.fat = `${recipe.fatGram}`;
    this.carbs = `${recipe.carbohydrateGram}`;
    this.mealIndex = this.mealIndexFromType(recipe.mealType);
    this.matchedRecipeName = recipe.name;
    this.recipeMatches = [];
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
    const todayKey = this.dateKey(new Date());
    const weekStart = this.weekStartKey();
    const weekEnd = todayKey;
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
    if (this.activeScope === 0) {
      return `${this.dateKey(new Date())} 已记录 ${this.todayTotals.recordCount} 条`;
    }
    return `${this.weekStartKey()} 至 ${this.dateKey(new Date())}，覆盖 ${this.weekTotals.recordDays} 天`;
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
    return this.activeScope === 0 ? 1 : this.weekElapsedDays();
  }

  private weekElapsedDays(): number {
    const today = new Date();
    const weekday = today.getDay();
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

  private recordDateKey(record: DietRecord): string {
    if (record.eatenAt.length >= 10) {
      return record.eatenAt.substring(0, 10);
    }
    return '';
  }

  private weekStartKey(): string {
    const today = new Date();
    const weekday = today.getDay();
    const offset = weekday === 0 ? 6 : weekday - 1;
    const monday = new Date(today.getTime());
    monday.setDate(today.getDate() - offset);
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
}
