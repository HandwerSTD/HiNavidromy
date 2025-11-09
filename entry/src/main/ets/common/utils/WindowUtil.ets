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

import { Context } from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import Logger, { MyLogUtil } from './Logger';

const TAG: string = '[WindowUtil]';

export class WindowUtil {
  public static registerRotationControl(context: Context) {
    try {
      if (canIUse('SystemCapability.Window.SessionManager')) {
        if (display.isFoldable()) {
          WindowUtil.changeOrientation(display.getFoldStatus(), context);
          display.on('foldStatusChange', (status: display.FoldStatus) => {
            WindowUtil.changeOrientation(status, context);
          });
        }
      }
    } catch (exception) {
      MyLogUtil.err(exception as Error, TAG, 'Is not fold able device error');
    }
  }
  private static changeOrientation(status: display.FoldStatus, context: Context) {
    if (canIUse('SystemCapability.Window.SessionManager')) {
      if (status !== display.FoldStatus.FOLD_STATUS_FOLDED) {
        AppStorage.setOrCreate('foldExpanded', true);
        WindowUtil.setMainWindowRestricted(context);
      } else {
        AppStorage.setOrCreate('foldExpanded', false);
        WindowUtil.setMainWindowPortrait(context);
      }
    }
  }

  static getDeviceSize(context: Context): Promise<WindowHWInfo> {
    // Get device height.
    return window.getLastWindow(context).then((data: window.Window) => {
      let properties = data.getWindowProperties();
      return new WindowHWInfo(px2vp(properties.windowRect.height), px2vp(properties.windowRect.width))
    });
  }

  static setMainWindowRestricted(context: Context): void {
    window.getLastWindow(context).then((windowClass: window.Window) => {
      if (windowClass === undefined) {
        MyLogUtil.err(new Error(`MainWindowClass is undefined`), `MainWindowClass is undefined`);
        return;
      }
      // Setting restricted display.
      windowClass.setPreferredOrientation(window.Orientation.AUTO_ROTATION_RESTRICTED);
    });
  }
  static setMainWindowDoNotRotate(context: Context): void {
    window.getLastWindow(context).then((windowClass: window.Window) => {
      if (windowClass === undefined) {
        MyLogUtil.err(new Error(`MainWindowClass is undefined`), `MainWindowClass is undefined`);
        return;
      }
      // Setting restricted display.
      windowClass.setPreferredOrientation(window.Orientation.LOCKED);
    });
  }
  static setMainWindowPortrait(context: Context): void {
    window.getLastWindow(context).then((windowClass: window.Window) => {
      if (windowClass === undefined) {
        MyLogUtil.err(new Error(`MainWindowClass is undefined`), `MainWindowClass is undefined`);
        return;
      }
      // Setting restricted display.
      windowClass.setPreferredOrientation(window.Orientation.PORTRAIT);
    });
  }
}

@ObservedV2
export class WindowAvoidanceData {
  @Trace bottom: number
  @Trace _top: number
  @Trace decorAvoid: number = -1

  constructor(bottom: number, top: number) {
    this.bottom = bottom
    this._top = top
  }
  get top() {
    if (this.decorAvoid !== -1 && this.decorAvoid !== 0) return this.decorAvoid;
    return this._top
  }
}

export class WindowHWInfo {
  height: number
  width: number

  constructor(height: number, width: number) {
    this.height = height
    this.width = width
  }
}