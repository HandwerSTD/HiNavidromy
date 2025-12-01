import util from '@ohos.util';
import { buffer } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { webview } from '@kit.ArkWeb';
import { deviceInfo } from '@kit.BasicServicesKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';
import { VMSwitcher } from '../lib/VMSwitcher';

const DOMAIN = 0x0000;

const VKeyMargin = 5;
const VKeyPadding = 8;
const VKeyHeight = 28;

function stringToArrayBuffer(str: string, encoding: buffer.BufferEncoding = 'utf-8'): ArrayBuffer {
  const buf = buffer.from(str, encoding);
  return buf.buffer;
}

// Web 组件的参数接口
interface WebNodeParams {
  controller: WebTerminalController;
}

// 用于构建 Web 节点的 Builder
@Builder
function webBuilder(params: WebNodeParams) {
  Web({
    src: $rawfile('term/term.html'),
    controller: params.controller.webviewController
  })
    .javaScriptProxy({
      object: params.controller,
      name: 'native',
      methodList: ['sendInput', 'resize', 'load', 'getFontSize'],
      controller: params.controller.webviewController,
      asyncMethodList: [],
      permission: `{
      "javascriptProxyPermission": {
        "urlPermissionList": [
          {
            "scheme": "resource",
            "host": "rawfile",
            "port": "",
            "path": ""
          }
        ]
      }
    }`
    })
    .backgroundColor('#000')
    .layoutWeight(1)
}

// WebTerminal 控制器，负责管理 Web 节点和终端交互逻辑
export class WebTerminalController extends NodeController {
  webviewController: webview.WebviewController = new webview.WebviewController();
  private utf8Decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
  private builderNode: BuilderNode<[WebNodeParams]> | null = null;
  private ctrlPressed: boolean = false;
  private onCtrlChangedCallback: ((pressed: boolean) => void) | null = null;

  constructor() {
    super();
  }

  setOnCtrlChangedCallback(callback: (pressed: boolean) => void) {
    this.onCtrlChangedCallback = callback;
  }

  makeNode(uiContext: UIContext): FrameNode | null {
    if (!this.builderNode) {
      this.builderNode = new BuilderNode(uiContext);
      this.builderNode.build(wrapBuilder<[WebNodeParams]>(webBuilder), { controller: this });
    }
    return this.builderNode.getFrameNode();
  }

  toggleCtrl() {
    this.ctrlPressed = !this.ctrlPressed;
    this.webviewController.runJavaScript('exports.setCtrlPressed(' + this.ctrlPressed + ')');
    this.onCtrlChangedCallback?.(this.ctrlPressed);
  }

  getCtrlPressed(): boolean {
    return this.ctrlPressed;
  }

  //  ============== for javascript in ArkWeb ================

  sendInput(data: string): void {
    hilog.info(DOMAIN, 'WebTerminal', 'sendInput, data: %{public}s', data);
    let buf = stringToArrayBuffer(data, 'utf-8');
    VMSwitcher.sendInput(buf);

    if (this.ctrlPressed) {
      this.toggleCtrl();
    }
  }

  async load(): Promise<void> {
    this.webviewController.runJavaScript('exports.setFocused(true)');
    VMSwitcher.onData((d: ArrayBuffer) => this.onData(d));
  }

  async resize(): Promise<void> {
  }

  getFontSize(): number | null {
    if (deviceInfo.deviceType === 'phone'
      || deviceInfo.deviceType === 'default') {
      return 11;
    } else if (deviceInfo.deviceType === 'tablet') {
      return 13;
    }
    return null;
  }

  private onData(ab: ArrayBuffer) {
    let s: string = this.utf8Decoder.decodeToString(new Uint8Array(ab), { stream: true });
    hilog.info(DOMAIN, 'WebTerminal', 'write, data: %{public}s', s);
    this.webviewController.runJavaScript('exports.write("' + s + '")');
  }

  async copySelection(): Promise<void> {
    const selection = await this.webviewController.runJavaScript('exports.copy()');
    if (selection !== '""') {
      let text: string = JSON.parse(selection);
      const board = pasteboard.getSystemPasteboard();
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      board.setData(pasteData);
    }
  }

  async paste(text: string): Promise<void> {
    const array = util.TextEncoder.create().encodeInto(text);
    const base64 = new util.Base64Helper().encodeToStringSync(array);
    this.webviewController.runJavaScript(`exports.paste(atob('${base64}'))`);
  }
}
const controller: WebTerminalController = new WebTerminalController();

@Component
export default struct WebTerminal {
  showVirtKey: boolean = true;
  @State ctrlPressed: boolean = false;
  private repeatTimer: number = -1;

  aboutToAppear(): void {
    controller.setOnCtrlChangedCallback((pressed) => {
      this.ctrlPressed = pressed;
    });
  }

  aboutToDisappear(): void {
    this.stopRepeat();
  }

  private startRepeat(input: string) {
    controller.sendInput(input);
    this.repeatTimer = setInterval(() => {
      controller.sendInput(input);
    }, 500);
  }

  private stopRepeat() {
    if (this.repeatTimer !== -1) {
      clearInterval(this.repeatTimer);
      this.repeatTimer = -1;
    }
  }

  @Builder
  contextMenu() {
    Flex({
      direction: FlexDirection.Column
    }) {
      MenuItem({ content: $r('app.string.copy_text') })
        .width('100%')
        .onClick(async () => {
          await controller.copySelection();
        })
      MenuItem() {
        PasteButton({ buttonType: ButtonType.ROUNDED_RECTANGLE })
          .onClick(async (event: ClickEvent, result: PasteButtonOnClickResult) => {
            if (PasteButtonOnClickResult.SUCCESS === result) {
              let board = pasteboard.getSystemPasteboard();
              const data = await board.getData();
              const text = data.getPrimaryText();
              await controller.paste(text);
            }
          })
          .width('100%')
          .align(Alignment.Start)
          .backgroundColor('#292b2e')
      }
    }
    .width('160vp')
  }

  build() {
    Column({space: 12}) {
      Column() {
        NodeContainer(controller)
          .layoutWeight(1)
          .bindContextMenu(this.contextMenu, ResponseType.RightClick)
      }.borderRadius(12).clip(true)
      .layoutWeight(1)

      Row() {
        Button('Tab')
          .height(VKeyHeight)
          .margin({ left: VKeyMargin })
          .padding({ left: VKeyPadding, right: VKeyPadding })
          .onClick(() => {
            controller.sendInput('\t');
          })
        Toggle({ type: ToggleType.Button, isOn: this.ctrlPressed }) {
          Text('Ctrl')
            .height(20)
        }
        .height(VKeyHeight)
        .margin({ left: VKeyMargin })
        .selectedColor($r('sys.color.interactive_active'))
        .onClick(() => controller.toggleCtrl())

        Button('Esc')
          .height(VKeyHeight)
          .margin({ left: VKeyMargin })
          .padding({ left: VKeyPadding, right: VKeyPadding })
          .onClick(() => {
            controller.sendInput('\x1b');
          })

        Row().layoutWeight(1)

        Button('↑')
          .height(VKeyHeight)
          .margin({ right: VKeyMargin })
          .padding({ left: VKeyPadding, right: VKeyPadding })
          .onClick(() => {
            controller.sendInput('\x1b[A');
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.startRepeat('\x1b[A');
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.stopRepeat();
            }
          })
        Button('↓')
          .height(VKeyHeight)
          .margin({ right: VKeyMargin })
          .padding({ left: VKeyPadding, right: VKeyPadding })
          .onClick(() => {
            controller.sendInput('\x1b[B');
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.startRepeat('\x1b[B');
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.stopRepeat();
            }
          })
        Button('←')
          .height(VKeyHeight)
          .margin({ right: VKeyMargin })
          .padding({ left: VKeyPadding, right: VKeyPadding })
          .onClick(() => {
            controller.sendInput('\x1b[D');
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.startRepeat('\x1b[D');
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.stopRepeat();
            }
          })
        Button('→')
          .height(VKeyHeight)
          .margin({ right: VKeyMargin })
          .padding({ left: VKeyPadding, right: VKeyPadding })
          .onClick(() => {
            controller.sendInput('\x1b[C');
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.startRepeat('\x1b[C');
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.stopRepeat();
            }
          })
      }
      .margin({ left: 5, right: 5 })
      Row() {
        Button('^C')
          .height(VKeyHeight)
          .margin({ left: VKeyMargin })
          .padding({ left: VKeyPadding, right: VKeyPadding })
          .onClick(() => {
            controller.sendInput('\x03');
          })
        Button('^Z')
          .height(VKeyHeight)
          .margin({ left: VKeyMargin })
          .padding({ left: VKeyPadding, right: VKeyPadding })
          .onClick(() => {
            controller.sendInput('\x1a');
          })
        Button('q')
          .height(VKeyHeight)
          .margin({ left: VKeyMargin })
          .padding({ left: VKeyPadding, right: VKeyPadding })
          .onClick(() => {
            controller.sendInput('q');
          })
      }
      .margin({ left: 5, right: 5 })
      .width('100%')
      .justifyContent(FlexAlign.Start)
    }
  }
}
