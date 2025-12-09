import preference from '@ohos.data.preferences';
import appOption from '../model/appOption';
import { common } from '@kit.AbilityKit';

/**
 * 系统镜像版本工具类
 */
class SystemImageUtils {
  /**
   * 当前系统版本号
   */
  static readonly CURRENT_VERSION: number = 3;

  /**
   * 检测是否为旧版镜像
   * 当系统版本为空或小于当前版本时，视为旧版镜像
   * @param context 应用上下文
   * @returns true 表示是旧版镜像，false 表示是当前版本
   */
  async isOldImage(context: common.ApplicationContext): Promise<boolean> {
    const appPref = await preference.getPreferences(context, appOption.preferenceName);
    return this.isOldImageByPref(appPref);
  }

  /**
   * 通过已有的 Preferences 实例检测是否为旧版镜像
   * @param appPref Preferences 实例
   * @returns true 表示是旧版镜像，false 表示是当前版本
   */
  async isOldImageByPref(appPref: preference.Preferences): Promise<boolean> {
    const version = await appPref.get(appOption.systemVersion, 0) as number;
    return version === 0 || version < SystemImageUtils.CURRENT_VERSION;
  }

  /**
   * 获取当前存储的系统版本
   * @param context 应用上下文
   * @returns 系统版本号，如果未设置则返回 0
   */
  async getStoredVersion(context: common.ApplicationContext): Promise<number> {
    const appPref = await preference.getPreferences(context, appOption.preferenceName);
    return await appPref.get(appOption.systemVersion, 0) as number;
  }

  /**
   * 更新系统版本为当前版本
   * @param context 应用上下文
   */
  async updateToCurrentVersion(context: common.ApplicationContext): Promise<void> {
    const appPref = await preference.getPreferences(context, appOption.preferenceName);
    await this.updateToCurrentVersionByPref(appPref);
  }

  /**
   * 通过已有的 Preferences 实例更新系统版本为当前版本
   * @param appPref Preferences 实例
   */
  async updateToCurrentVersionByPref(appPref: preference.Preferences): Promise<void> {
    await appPref.put(appOption.systemVersion, SystemImageUtils.CURRENT_VERSION);
    await appPref.flush();
  }
}

export default new SystemImageUtils();
