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

import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';


export class LogStorage {

  logInfo: string = ''

  static singleton_: LogStorage;
  static instance() {
    if(!LogStorage.singleton_) {
      LogStorage.singleton_ = new LogStorage();
    };
    return LogStorage.singleton_;
  }
}


class MyLogger {
  private readonly MAX_LOG_SIZE = 50000;
  private domain: number;
  private prefix: string;
  private format: string = "%{public}s, %{public}s";
  private st?: LogStorage

  constructor(prefix: string) {
    this.prefix = prefix;
    this.domain = 0xFF00;
  }
  setLogStorage(st?: LogStorage) {
    this.st = st
  }
  appendLog(level: string, args: Object[], direct: boolean = false) {
    if (!this.st) {
      return
    }
    if (this.st.logInfo.length > this.MAX_LOG_SIZE) this.st.logInfo = this.st.logInfo.substring(this.st.logInfo.length/2)
    this.st.logInfo += '\n';
    if (direct) {
      this.st.logInfo += (args.map((val, index) => {
        return ' '+val.toString()
      }));
    } else {
      this.st.logInfo +=
      (`[${level}] `) + ((new Date()).toLocaleString()) + ', \n' + args.map((val, index) => {
        return ' '+val.toString()
      }) + '\n'
    }
  }

  debug(...args: Object[]): void {
    hilog.debug(this.domain, this.prefix, this.format, args);
    this.appendLog(`DEBUG`, args)
  }

  info(...args: Object[]): void {
    hilog.info(this.domain, this.prefix, this.format, args);
    this.appendLog(`INFO`, args)
  }

  warn(...args: Object[]): void {
    hilog.warn(this.domain, this.prefix, this.format, args);
    this.appendLog(`WARN`, args)
  }

  error(...args: Object[]): void {
    hilog.error(this.domain, this.prefix, this.format, args);
    this.appendLog(`ERROR`, args)
  }
  getLastLogs() {
    return this.st?.logInfo ?? ''
  }
}

const Logger = new MyLogger('[CloudPurePlay]')

export default Logger ;

class StrUtil {
  static repeat(arg0: string, arg1: number) {
    return (new Array(arg1)).fill(arg0).join('')
  }
  static isNotEmpty(tag: string) {
    return tag.length > 0
  }
  static startsWith(str: string, tar: string) {
    return str.startsWith(tar)
  }
  static endsWith(str: string, tar: string) {
    return str.endsWith(tar)
  }
}

export class MyLogUtil {

  private static logSize: number = 2048;
  private static domain: number = 0x0000;
  private static tag: string = 'harmony-utils'; //日志Tag
  private static showLog: boolean = true; //是否显示打印日志
  private static isHilog: boolean = true; //true-hilog、false-console


  /**
   * 初始化日志参数（该方法建议在Ability里调用）
   * @param domain
   * @param tag
   * @param showLog
   */
  static init(domain: number = MyLogUtil.domain, tag: string = MyLogUtil.tag, showLog: boolean = true, isHilog: boolean = true) {
    MyLogUtil.domain = domain;
    MyLogUtil.tag = tag;
    MyLogUtil.showLog = showLog;
    MyLogUtil.isHilog = isHilog;
  }

  /**
   * 设置日志对应的领域标识，范围是0x0~0xFFFF。（该方法建议在Ability里调用）
   * @param domain
   */
  static setDomain(domain: number = MyLogUtil.domain) {
    MyLogUtil.domain = domain
  }

  /**
   * 设置日志标识（该方法建议在Ability里调用）
   * @param tag
   */
  static setTag(tag: string = MyLogUtil.tag) {
    MyLogUtil.tag = tag
  }

  /**
   * 是否打印日志（该方法建议在Ability里调用）
   * @param showLog
   */
  static setShowLog(showLog: boolean = true) {
    MyLogUtil.showLog = showLog
  }

  /**
   * 日志打印方式
   * @param isHilog，true-hilog、false-console
   */
  public static setHilog(isHilog: boolean) {
    MyLogUtil.isHilog = isHilog;
  }


  /**
   * 打印DEBUG级别日志
   * @param args
   */
  static debug(...args: string[] | object[]): void {
    MyLogUtil.uniLog(args, hilog.LogLevel.DEBUG);
  }

  /**
   * 打印INFO级别日志
   * @param args
   */
  static info(...args: string[] | object[]): void {
    MyLogUtil.uniLog(args, hilog.LogLevel.INFO);
  }

  static infoHere(ctx: object, method: string, info: string) {
    const cls = (ctx as any)?.constructor?.name ?? "<anonymous>";
    const parent = Object.getPrototypeOf((ctx as any)?.constructor)?.name ?? "-";
    MyLogUtil.info(`${cls}.${method}() [super: ${parent}] >>> ${info}}`);
  }
  /**
   * 打印WARN级别日志
   * @param args
   */
  static warn(...args: string[] | object[]): void {
    MyLogUtil.uniLog(args, hilog.LogLevel.WARN);
  }

  /**
   * 打印ERROR级别日志
   * @param args
   */
  static error(...args: string[] | object[]): void {
    MyLogUtil.uniLog(args, hilog.LogLevel.ERROR);
  }
  static err(e: Error, ...args: string[] | object[]): void {
    MyLogUtil.uniLog(args.concat([`\nerrmsg = ${e.message} stacktrace: ${e.stack ?? '<>'}}`]), hilog.LogLevel.ERROR);
  }

  /**
   * 打印FATAL级别日志
   * @param args
   */
  static fatal(...args: string[] | object[]): void {
    MyLogUtil.uniLog(args, hilog.LogLevel.FATAL);
  }

  /**
   * 打印JSON对象和JSON字符串
   * @param msg
   */
  static print(msg: object | string) {
    try {
      let content = '';
      if (typeof msg === 'object') {
        if (msg instanceof Error) {
          content = content + MyLogUtil.getErrorStr(msg, false);
        } else {
          content = content + MyLogUtil.getObjectToJson(msg, false);
        }
      } else if (typeof msg === 'string') {
        if ((StrUtil.startsWith(msg, '{') && StrUtil.endsWith(msg, '}')) || (StrUtil.startsWith(msg, '[') && StrUtil.endsWith(msg, ']'))) {
          let obj: object = JSON.parse(msg.toString()) ?? new Object(msg);
          content = content + MyLogUtil.getObjectToJson(obj, false);
        } else {
          content = content + msg;
        }
      }
      const len = Math.ceil(content.length / MyLogUtil.logSize);
      for (let i = 0; i < len; i++) {
        let end = (i + 1) * MyLogUtil.logSize;
        if (i === (len - 1)) {
          end = content.length;
        }
        let msg = '\n' + content.substring(i * MyLogUtil.logSize, end);
        MyLogUtil.levelLog(msg, hilog.LogLevel.DEBUG);
      }
    } catch (err) {
      let error = err as BusinessError<void>; //异常了
      console.error(`MyLogUtil-print-异常 ~ code: ${error.code} -·- message: ${error.message}`);
    }
  }


  /**
   * 统一日志输出
   */
  private static uniLog(message: string[] | object[], level: hilog.LogLevel) {
    if (!MyLogUtil.showLog) {
      return; //不打印日志
    }
    switch (level) {
      case hilog.LogLevel.DEBUG:
        Logger.appendLog('DEBUG', [])
        break
      case hilog.LogLevel.INFO:
        Logger.appendLog('INFO', [] )
        break
      case hilog.LogLevel.WARN:
        Logger.appendLog('WARN', [] )
        break
      case hilog.LogLevel.ERROR:
        Logger.appendLog('ERROR', [] )
        break
      case hilog.LogLevel.FATAL:
        Logger.appendLog('FATAL!!', [] )
        break
    }
    let topLine = MyLogUtil.getLine(MyLogUtil.tag);
    MyLogUtil.levelLog(topLine, level);
    if (level === hilog.LogLevel.ERROR || level === hilog.LogLevel.FATAL) {
      let locationLog = MyLogUtil.getLogLocation(); //代码位置
      MyLogUtil.levelLog(locationLog, level);
    }
    let content = MyLogUtil.getMessage(message);
    if (content === '') {
      content = '(EMPTY MSG) ' + MyLogUtil.getLogLocation()
    }
    const len = Math.ceil(content.length / MyLogUtil.logSize);
    for (let i = 0; i < len; i++) {
      let end = (i + 1) * MyLogUtil.logSize;
      if (i === (len - 1)) {
        end = content.length;
      }
      let msg = '\n│  ' + content.substring(i * MyLogUtil.logSize, end);
      MyLogUtil.levelLog(msg, level);
    }
    let bottomLine = MyLogUtil.getLine('');
    MyLogUtil.levelLog(bottomLine, level);
  }


  /**
   * 日志打印
   */
  private static levelLog(msg: string, level: hilog.LogLevel) {
    switch (level) {
      case hilog.LogLevel.DEBUG:
        hilog.debug(MyLogUtil.domain, MyLogUtil.tag, msg);
        Logger.appendLog('DEBUG', [msg], true)
        break
      case hilog.LogLevel.INFO:
        hilog.info(MyLogUtil.domain, MyLogUtil.tag, msg);
        Logger.appendLog('INFO', [msg], true)
        break
      case hilog.LogLevel.WARN:
        hilog.warn(MyLogUtil.domain, MyLogUtil.tag, msg);
        Logger.appendLog('WARN', [msg], true)
        break
      case hilog.LogLevel.ERROR:
        hilog.error(MyLogUtil.domain, MyLogUtil.tag, msg);
        Logger.appendLog('ERROR', [msg], true)
        break
      case hilog.LogLevel.FATAL:
        hilog.fatal(MyLogUtil.domain, MyLogUtil.tag, msg);
        Logger.appendLog('FATAL!!', [msg], true)
        break
    }
  }

  /**
   * 获取格式化日志内容
   */
  private static getMessage(message: string[] | object[]): string {
    try {
      let logMessage = '';
      message.forEach((msg: string | object) => {
        if (typeof msg === 'object') {
          if (msg instanceof Error) {
            logMessage = logMessage + MyLogUtil.getErrorStr(msg);
          } else {
            logMessage = logMessage + MyLogUtil.getObjectToJson(msg);
          }
        } else if (typeof msg === 'string') {
          if ((StrUtil.startsWith(msg, '{') && StrUtil.endsWith(msg, '}')) || (StrUtil.startsWith(msg, '[') && StrUtil.endsWith(msg, ']'))) {
            let obj: object = JSON.parse(msg.toString()) ?? new Object(msg);
            logMessage = logMessage + MyLogUtil.getObjectToJson(obj);
          } else {
            logMessage = logMessage + msg;
            logMessage = logMessage.replaceAll('\n', '\n│  ');
          }
        }
      });
      return logMessage;
    } catch (err) {
      return message.toString();
    }
  }

  /**
   * 对象转JSON字符串
   */
  private static getObjectToJson(obj: object, line: boolean = true): string {
    try {
      let jsonStr = JSON.stringify(obj, null, 2);
      if (line) {
        jsonStr = jsonStr.replace(/\n/g, '\n│\t');
        if (jsonStr.endsWith('\t]')) {
          jsonStr = jsonStr.replace(/..$/, '  ]');
        } else if (jsonStr.endsWith('\t}')) {
          jsonStr = jsonStr.replace(/..$/, '  }');
        }
      }
      return jsonStr;
    } catch (err) {
      return '';
    }
  }

  /**
   * 获取Error字符串
   */
  private static getErrorStr(error: Error, line: boolean = true): string {
    let errObj: Record<string, string | number> = {};
    errObj['name'] = error.name;
    errObj['code'] = (error as BusinessError<void>)?.code ?? '';
    errObj['message'] = error.message;
    errObj['stack'] = error.stack ?? '';
    let errorStr = MyLogUtil.getObjectToJson(errObj, line);
    return errorStr;
  }

  /**
   * 获取代码位置（性能开销比较大，当频繁创建带有调用栈信息的错误对象时，会对程序的性能产生明显影响）。
   */
  private static getLogLocation(): string {
    const errorStack = new Error().stack;
    const stackArray = errorStack?.split('\n');
    let errorLocation: string = stackArray?.filter(item => item !== null && item.length > 1)?.map(value => value.trim()
      .concat('\t'))?.splice(3).join('') ?? '';
    return `\n│  ${errorLocation}\n│➼${StrUtil.repeat('┄┄┄┄┄┄┄', 21)}`;
  }

  /**
   * 获取生成的日志边框
   */
  private static getLine(tag: string = '', length: number = 130): string {
    if (StrUtil.isNotEmpty(tag)) {
      return `┌${StrUtil.repeat('─', 15)}► ${tag} ◄${StrUtil.repeat('─', length - tag.length)}`;
    } else {
      return `└${StrUtil.repeat('─', 19)}${StrUtil.repeat('─', length)}`;
    }
  }
}

export function LogHere(
  _target: any,
propertyKey: string,
descriptor: PropertyDescriptor
) {
  const original = descriptor.value;
  descriptor.value = function (...args: any[]) {
    let cls = this?.constructor?.name ?? "<anonymous>";
    // 判断 this 是否是构造函数（静态方法里 this 是类本身）
    if (typeof this === "function") {
      cls = this.name ?? "<anonymous>";
    } else {
      cls = this?.constructor?.name ?? "<anonymous>";
    }
    // 也可加 parent：Object.getPrototypeOf(this.constructor)?.name
    MyLogUtil.info(`${cls}.${propertyKey}() running >>>`);
    return original.apply(this, args);
  };
  return descriptor;
}
export function LogHereEnd(
  _target: any,
  propertyKey: string,
  descriptor: PropertyDescriptor
) {
  const original = descriptor.value;
  descriptor.value = function (...args: any[]) {
    let cls = this?.constructor?.name ?? "<anonymous>";
    // 判断 this 是否是构造函数（静态方法里 this 是类本身）
    if (typeof this === "function") {
      cls = this.name ?? "<anonymous>";
    } else {
      cls = this?.constructor?.name ?? "<anonymous>";
    }

    try {
      const result = original.apply(this, args);
      // 兼容异步函数
      if (result instanceof Promise) {
        return result.finally(() => {
          MyLogUtil.info(`${cls}.${propertyKey}() END <<<`);
        });
      } else {
        MyLogUtil.info(`${cls}.${propertyKey}() END <<<`);
        return result;
      }
    } catch (err) {
      MyLogUtil.info(`${cls}.${propertyKey}() END (with error) <<<<<<<`);
      throw err; // 保持原本异常
    }
  };
  return descriptor;
}
