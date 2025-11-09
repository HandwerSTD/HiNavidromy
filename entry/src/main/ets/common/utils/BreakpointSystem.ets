/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { display, window } from '@kit.ArkUI'; 
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import Logger, { MyLogUtil } from './Logger';
import GlobalStore from '../statemgmt/GlobalStore';
import { WindowAvoidanceData } from './WindowUtil';

const TAG = 'BreakpointSystem'

export enum BreakpointTypeEnum {
  XS = 'xs',
  SM = 'sm',
  MD = 'md',
  LG = 'lg',
  XL = 'xl'
}

@ObservedV2
export class BreakpointInfo {
  @Trace value: string = ''

  constructor(val: string) {
    this.value = val
  }
}

export class BreakpointSystem {
  private windowStage?: window.WindowStage;
  private mainWindowClass?: window.Window;

  private static singleton_: BreakpointSystem;
  static instance() {
    if(!BreakpointSystem.singleton_) {
      BreakpointSystem.singleton_ = new BreakpointSystem();
    };
    return BreakpointSystem.singleton_;
  }

  init(windowStage: window.WindowStage): void {
    this.windowStage = windowStage;
    this.windowStage.getMainWindow((err, windowClass: window.Window) => {
      this.mainWindowClass = windowClass;
      this.setFullScreen() // 设置全屏
      // 窗口大小更新时触发断点更新
      this.updateBreakpointAndUI()
      windowClass.on("windowSizeChange", (windowSize: window.Size) => {
        this.updateBreakpointAndUI()
      })

      if (err.code) {
        hilog.error(0x0000, 'testTag', `Failed to obtain the main window. Code: ${err.code}, message: ${err.message}`,
          JSON.stringify(err) ?? '');
        return;
      }
    });
  }

  setFullScreen(): void {
    this.windowStage!.getMainWindow((err: BusinessError, data: window.Window) => {
      if (err.code) {
        MyLogUtil.err(err as Error, TAG, 'Failed to obtain the main window.');
        return;
      }
      let windowClass: window.Window = data;
      Logger.info(TAG, 'Succeeded in obtaining the main window. Data: ' + JSON.stringify(data));

      // Realize the immersive effect
      this.setFullScreenAvoidanceData(windowClass, true)
      windowClass.on('avoidAreaChange', () => {
        this.setFullScreenAvoidanceData(windowClass)
      })
      this.setPCMode(windowClass)
      windowClass.on('windowStatusChange', () => {
        this.setPCMode(windowClass)
      })
    });
  }
  setPCMode(windowClass: window.Window) {
    try {
      const stat = windowClass.getWindowStatus()
      if (stat == window.WindowStatusType.FLOATING || stat == window.WindowStatusType.MAXIMIZE || deviceInfo.deviceType == '2in1') {
        GlobalStore.isPCMode = true
        Logger.info(TAG, `PC Mode enabled`)
      } else {
        GlobalStore.isPCMode = false
        Logger.info(TAG, `PC Mode disabled`)
      }
    } catch {

    }
  }
  setFullScreenAvoidanceData(windowClass: window.Window, onFirstOpen: boolean = false) {
    try {
      // 判断是否为 PC/自由多窗悬浮模式，如是则尝试标题栏
      const stat = windowClass.getWindowStatus()
      let decorHeight = -1;
      if ((stat === window.WindowStatusType.FLOATING || stat == window.WindowStatusType.MAXIMIZE)) {
        decorHeight = windowClass.getTitleButtonRect().height
        // 首次拿的时候拿不到，手动指定一下
        if (onFirstOpen && decorHeight == 0) decorHeight = 37
        windowClass.setWindowDecorVisible(false)
        Logger.info(TAG,
          `Succeeded get the window decor height when FLOATING/MAXIMIZE = ${(windowClass.getTitleButtonRect().height)}`);
      } else {
        windowClass.setWindowDecorVisible(true)
        Logger.info(TAG,
          `Succeeded set the window decor height when not FLOATING/MAXIMIZE`);
      }
      // 拿完之后再尝试拿一下导航栏避让区域
      let area: window.AvoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      let naviBarArea: window.AvoidArea =
        windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      Logger.info(TAG,
        `Succeeded get the window navigation indicator HEIGHT: ${px2vp(naviBarArea.bottomRect.height)}; SYSTEM top height = ${px2vp(area.topRect.height)}`);
      // 导航栏避让、状态栏避让、标题栏避让，三个都记一下
      let data = new WindowAvoidanceData(px2vp(naviBarArea.bottomRect.height),px2vp(area.topRect.height))
      data.decorAvoid = decorHeight
      GlobalStore.wd = data
      // 如果没有标题栏避让，设置全屏沉浸式
      if (area.topRect.height > 0 && decorHeight === -1) {
        let promise: Promise<void> = windowClass.setWindowLayoutFullScreen(true);
        promise.then(() => {
          Logger.info(TAG, 'Succeeded in setting the window layout to full-screen mode.');
        }).catch((err: BusinessError) => {
          MyLogUtil.err(err as Error, TAG, 'Failed to set the window layout to full-screen mode.');
        });
      }
    } catch (e) {
      MyLogUtil.err(e as Error, TAG, 'Failed to set the window layout to full-screen mode.');
    }
  }

  disableWindowSystemBar(): void {
    // Set the status bar and navigation bar to be invisible in full-screen mode.
    this.mainWindowClass!.setWindowSystemBarEnable([])
      .then(() => {
        hilog.info(0x0000, 'testTag', '%{public}s', `Succeed in setting the window system bar disable.`);
      })
      .catch((err: BusinessError) => {
        hilog.error(0x0000, 'testTag',
          `Failed to set the window system bar disable. Code: ${err.code}, message: ${err.message}`,
          JSON.stringify(err) ?? '');
      });
  }

  enableWindowSystemBar(): void {
    this.mainWindowClass!.setWindowSystemBarEnable(['status', 'navigation'])
      .then(() => {
        hilog.info(0x0000, 'testTag', '%{public}s', `Succeed in setting the window system bar enable.`);
      })
      .catch((err: BusinessError) => {
        hilog.error(0x0000, 'testTag', `Failed to set the orientation. Code: ${err.code}, message: ${err.message}`,
          JSON.stringify(err) ?? '');
      });
  }

  maximize(): void {
    if (this.mainWindowClass!.getWindowStatus() === window.WindowStatusType.FLOATING) {
      this.mainWindowClass!.maximize()
        .then(() => {
          hilog.info(0x0000, 'testTag', '%{public}s', `Succeed in maximizing the window.`);
        })
        .catch((err: BusinessError) => {
          hilog.error(0x0000, 'testTag', `Failed to maximize the window. Code: ${err.code}, message: ${err.message}`,
            JSON.stringify(err) ?? '');
        });
    }
  }

  recover(): void {
    if (this.mainWindowClass!.getWindowStatus() === window.WindowStatusType.FULL_SCREEN) {
      this.mainWindowClass!.recover()
        .then(() => {
          hilog.info(0x0000, 'testTag', '%{public}s', `Succeed in rovering the window.`);
        })
        .catch((err: BusinessError) => {
          hilog.error(0x0000, 'testTag', `Failed to rover the window. Code: ${err.code}, message: ${err.message}`,
            JSON.stringify(err) ?? '');
        });
    }
  }

  getMainWindow(): window.Window | undefined {
    return this.mainWindowClass;
  }

  offWindowSizeChange(): void {
    try {
      this.mainWindowClass!.off('windowSizeChange');
    } catch (err) {
      hilog.error(0x0000, 'testTag', `Failed to off window size change. Code: ${err.code}, message: ${err.message}`,
        JSON.stringify(err) ?? '');
    }
  }

  updateBreakpointAndUI() {
    this.updateWidthBp()
    this.updateHeightBp() // 更新断点
    this.changeUI()
    Logger.debug(TAG, `updateBreakpoint: width = ${GlobalStore.wbp}, height = ${GlobalStore.hbp}`)
  }

  updateWidthBp(): void {
    let mainWindow: window.WindowProperties = this.mainWindowClass!.getWindowProperties();
    let windowWidth: number = mainWindow.windowRect.width;
    let windowWidthVp = windowWidth / (display.getDefaultDisplaySync().densityDPI / 160);
    let widthBp: string = '';
    if (windowWidthVp < 320) {
      widthBp = BreakpointTypeEnum.XS
    } else if (windowWidthVp >= 320 && windowWidthVp < 600) {
      widthBp = BreakpointTypeEnum.SM
    } else if (windowWidthVp >= 600 && windowWidthVp < 840) {
      widthBp = BreakpointTypeEnum.MD
    } else if (windowWidthVp >= 840 && windowWidthVp < 1440) {
      widthBp = BreakpointTypeEnum.LG
    } else {
      widthBp = BreakpointTypeEnum.XL
    }
    GlobalStore.wbp = new BreakpointInfo(widthBp).value
  }

  updateHeightBp(): void {
    let mainWindow: window.WindowProperties = this.mainWindowClass!.getWindowProperties();
    let windowHeight: number = mainWindow.windowRect.height;
    let windowWidth: number = mainWindow.windowRect.width;
    let windowWidthVp = windowWidth / (display.getDefaultDisplaySync().densityDPI / 160);
    let windowHeightVp = windowHeight / (display.getDefaultDisplaySync().densityDPI / 160);
    let heightBp: string = '';
    let aspectRatio: number = windowHeightVp / windowWidthVp;
    if (aspectRatio < 0.8) {
      heightBp = BreakpointTypeEnum.SM
    } else if (aspectRatio >= 0.8 && aspectRatio < 1.2) {
      heightBp = BreakpointTypeEnum.MD
    } else {
      heightBp = BreakpointTypeEnum.LG
    }
    GlobalStore.hbp = new BreakpointInfo(heightBp).value
  }

  changeUI() {
    // 处理 UI 变化逻辑
    if (ResponsiveUtil.PuraXOuterCheck()) {
      this.disableWindowSystemBar()
    } else {
      this.enableWindowSystemBar()
    }
  }

  getWbpByValue(windowWidthVp: number) {
    let widthBp = ''
    if (windowWidthVp < 320) {
      widthBp = BreakpointTypeEnum.XS
    } else if (windowWidthVp >= 320 && windowWidthVp < 600) {
      widthBp = BreakpointTypeEnum.SM
    } else if (windowWidthVp >= 600 && windowWidthVp < 840) {
      widthBp = BreakpointTypeEnum.MD
    } else if (windowWidthVp >= 840 && windowWidthVp < 1440) {
      widthBp = BreakpointTypeEnum.LG
    } else {
      widthBp = BreakpointTypeEnum.XL
    }
    return widthBp
  }
  getHbpByValue(windowWidthVp: number, windowHeightVp: number) {
    let heightBp: string = '';
    let aspectRatio: number = windowHeightVp / windowWidthVp;
    if (aspectRatio < 0.8) {
      heightBp = BreakpointTypeEnum.SM
    } else if (aspectRatio >= 0.8 && aspectRatio < 1.2) {
      heightBp = BreakpointTypeEnum.MD
    } else {
      heightBp = BreakpointTypeEnum.LG
    }
    return heightBp
  }
}

export class ResponsiveUtil {
  static PCDeviceTypeCheck() {
    return deviceInfo.deviceType === '2in1'
  }
  static PuraXOuterCheck(): boolean {
    const hbp = GlobalStore.hbp, wbp = GlobalStore.wbp
    return ResponsiveUtil.smOrMdCheck(hbp) && ResponsiveUtil.smCheck(wbp)
  }
  static wLgXl(): boolean {
    let wbp = GlobalStore.wbp
    return wbp == BreakpointTypeEnum.LG || wbp == BreakpointTypeEnum.XL
  }
  static widthCheck(breakpoint: string[]) {
    let wbp = GlobalStore.wbp
    return breakpoint.indexOf(wbp) !== -1
  }
  static heightCheck(breakpoint: string[]) {
    let wbp = GlobalStore.hbp
    return breakpoint.indexOf(wbp) !== -1
  }
  static lgCheck(bp: string): boolean {
    return bp == BreakpointTypeEnum.LG
  }
  static mdOrLgCheck(bp: string): boolean {
    return bp == BreakpointTypeEnum.LG || bp == BreakpointTypeEnum.MD
  }
  static mdCheck(bp: string): boolean {
    return bp == BreakpointTypeEnum.MD
  }
  static smOrMdCheck(bp: string): boolean {
    return bp == BreakpointTypeEnum.SM || bp == BreakpointTypeEnum.MD
  }
  static smCheck(bp: string): boolean {
    return bp == BreakpointTypeEnum.SM
  }

  static chooseByWidth<T>(item: T[], enableXS: boolean = false) {
    let breakpointOrder = ['sm', 'md', 'lg', 'xl']
    if (enableXS) breakpointOrder = ['xs'].concat(breakpointOrder)
    let wbp = GlobalStore.wbp
    return item[Math.min(breakpointOrder.indexOf(wbp), item.length-1)]
  }
}