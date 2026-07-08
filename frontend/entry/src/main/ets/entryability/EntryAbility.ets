import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want) {
    console.info('HealthRecipe EntryAbility onCreate');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error(`loadContent failed, code: ${err.code}, message: ${err.message}`);
        return;
      }
      console.info(`loadContent succeeded: ${JSON.stringify(data)}`);
    });
  }
}
