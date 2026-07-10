interface SortOption {
  label: string;
  value: string;
}

@Component
export struct SortSelector {
  @Prop currentSort: string = 'default';
  onSortChange?: (value: string) => void;
  @State isExpanded: boolean = false;

  readonly sortOptions: SortOption[] = [
    { label: '默认推荐', value: 'default' } as SortOption,
    { label: '热量最低', value: 'calories_asc' } as SortOption,
    { label: '热量最高', value: 'calories_desc' } as SortOption,
    { label: '蛋白质最高', value: 'protein_desc' } as SortOption,
    { label: '脂肪最低', value: 'fat_asc' } as SortOption,
    { label: '碳水最低', value: 'carbohydrate_asc' } as SortOption
  ];

  build() {
    Column() {
      this.headerRow()

      if (this.isExpanded) {
        Scroll() {
          Column() {
            ForEach(this.sortOptions, (option: SortOption) => {
              this.optionItem(option)
            })
          }
          .width('100%')
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .constraintSize({ maxHeight: 300 })
        .width('100%')
        .backgroundColor('#F6F8F2')
        .borderRadius(14)
      }
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  headerRow() {
    Row() {
      Text(`当前排序：${this.sortLabel()}`)
        .fontSize(14)
        .fontColor('#405146')
        .layoutWeight(1)

      Text(this.isExpanded ? '▲' : '▼')
        .fontSize(12)
        .fontColor('#657064')
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)
        .backgroundColor('#F6F8F2')
        .borderRadius(14)
    }
    .width('100%')
    .padding({ top: 2, bottom: this.isExpanded ? 10 : 2 })
    .onClick(() => {
      this.toggleExpand();
    })
  }

  @Builder
  optionItem(option: SortOption) {
    Row() {
      Text(option.label)
        .fontSize(14)
        .fontColor(this.currentSort === option.value ? '#156B45' : '#405146')
        .fontWeight(this.currentSort === option.value ? FontWeight.Bold : FontWeight.Normal)
        .layoutWeight(1)

      if (this.currentSort === option.value) {
        Text('✓')
          .fontSize(16)
          .fontColor('#156B45')
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(this.currentSort === option.value ? '#E8F4EC' : '#FFFFFF')
    .onClick(() => {
      if (this.onSortChange != null) {
        this.onSortChange(option.value);
      }
      this.isExpanded = false;
    })
  }

  private sortLabel(): string {
    for (let i = 0; i < this.sortOptions.length; i++) {
      if (this.sortOptions[i].value === this.currentSort) {
        return this.sortOptions[i].label;
      }
    }
    return '默认推荐';
  }

  private toggleExpand() {
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
      this.isExpanded = !this.isExpanded;
    });
  }
}
