import { FormExtensionAbility, formBindingData, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { HealthCardService } from '../services/HealthCardService';

export default class HealthCardFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const data = HealthCardService.loadData(this.context);
    const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;
    HealthCardService.registerForm(this.context, formId == null ? '' : formId);
    return formBindingData.createFormBindingData(data);
  }

  onUpdateForm(formId: string): void {
    HealthCardService.updateForm(this.context, formId).catch((error: Object) => {
      console.error(`HealthCard onUpdateForm failed: ${JSON.stringify(error)}`);
    });
  }

  onRemoveForm(formId: string): void {
    HealthCardService.removeForm(this.context, formId);
  }
}
