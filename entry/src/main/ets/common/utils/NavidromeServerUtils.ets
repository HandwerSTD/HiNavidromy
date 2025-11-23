import GlobalStore from "../statemgmt/GlobalStore";
import { RetryUtil } from "./CommonUtil";
import { http } from "@kit.NetworkKit";
import { promptAction } from "@kit.ArkUI";

export class NavidromeServerUtils {
  static checkConnectionOnStart() {
    // 90s 登录时间
    RetryUtil.retryIf<void>(30, async () => {
      // http
      const cli = http.createHttp()
      return cli.request('localhost:4533')
        .then((val) => {
          if (val.responseCode === 200) {
            GlobalStore.isServerOnline = true
          }
        })
    }, () => {
      return !GlobalStore.isServerOnline
    }, 3000)
      .catch(() => {
        promptAction.openToast({
          message: '检测服务器连接失败'
        })
      })
  }
}