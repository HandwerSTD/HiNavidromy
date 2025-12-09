import preference from '@ohos.data.preferences';
import appOption from '../model/appOption';
import { common } from '@kit.AbilityKit';

const IsForceUpdate: Record<number, boolean> = {
  0: false,
  1: false,
  2: false,
  3: true
}

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

  async hasForceUpdateTillNow(context: common.ApplicationContext): Promise<boolean> {
    const now = await this.getStoredVersion(context)
    for (let i = now + 1; i <= SystemImageUtils.CURRENT_VERSION; ++i) {
      if (IsForceUpdate[i]) return true;
    }
    return false;
  }

  /**
   * 忽略当前版本的更新
   * @param context 应用上下文
   */
  async ignoreCurrentVersionUpdate(context: common.ApplicationContext): Promise<void> {
    const appPref = await preference.getPreferences(context, appOption.preferenceName);
    await this.ignoreCurrentVersionUpdateByPref(appPref);
  }

  /**
   * 通过已有的 Preferences 实例忽略当前版本的更新
   * @param appPref Preferences 实例
   */
  private async ignoreCurrentVersionUpdateByPref(appPref: preference.Preferences): Promise<void> {
    const ignoredVersions = await appPref.get(appOption.ignoredUpdateVersions, '[]') as string;
    const ignoredArray: number[] = JSON.parse(ignoredVersions);
    if (!ignoredArray.includes(SystemImageUtils.CURRENT_VERSION)) {
      ignoredArray.push(SystemImageUtils.CURRENT_VERSION);
    }
    await appPref.put(appOption.ignoredUpdateVersions, JSON.stringify(ignoredArray));
    await appPref.flush();
  }

  /**
   * 检查当前版本是否已被忽略
   * @param context 应用上下文
   * @returns true 表示当前版本已被忽略
   */
  async isCurrentVersionIgnored(context: common.ApplicationContext): Promise<boolean> {
    const appPref = await preference.getPreferences(context, appOption.preferenceName);
    const ignoredVersions = await appPref.get(appOption.ignoredUpdateVersions, '[]') as string;
    const ignoredArray: number[] = JSON.parse(ignoredVersions);
    return ignoredArray.includes(SystemImageUtils.CURRENT_VERSION);
  }

  /**
   * 检查是否有可用更新
   * 综合考虑：旧版本、新版本、忽略版本
   * - 如果当前存储版本 >= 最新版本，则无更新
   * - 如果当前版本已被忽略且不是强制更新，则无更新
   * - 其他情况有更新
   * @param context 应用上下文
   * @returns true 表示有可用更新
   */
  async checkHasUpdate(context: common.ApplicationContext): Promise<boolean> {
    const storedVersion = await this.getStoredVersion(context);
    // 已经是最新版本
    if (storedVersion >= SystemImageUtils.CURRENT_VERSION) {
      return false;
    }
    // 检查是否有强制更新
    const hasForce = await this.hasForceUpdateTillNow(context);
    if (hasForce) {
      // 强制更新不可忽略
      return true;
    }
    // 检查当前版本是否已被忽略
    const isIgnored = await this.isCurrentVersionIgnored(context);
    if (isIgnored) {
      return false;
    }
    return true;
  }
}

export default new SystemImageUtils();
