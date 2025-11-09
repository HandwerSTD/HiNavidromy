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

/**
 * Public tool class.
 */
export class CommonUtil {
  /**
   * Replace count with text when the count number exceeds the maximum value.
   * @param count
   * @param max
   * @param replaceText
   */
  public static formatNumToMaxText(count: number, max: number, replaceText: string): string {
    return count > max ? max + replaceText : (count ?? 0).toString();
  }

  /**
   * Replace count with plus sign when the count number over one thousand
   * @param count
   */
  public static transNumberOverOneThousand(count: number): string {
    return CommonUtil.formatNumToMaxText(count, 999, '+');
  }

  /**
   * Replace count with plus sign when the count number over one thousand
   * @param count
   */
  public static transNumberWithUnit(count: number): string {
    if(count < 999) {
      return count.toString();
    }else if(count > 999 && count < 9999) {
      return (count / 1000).toFixed(1) + 'k';
    } else {
      return (count / 10000).toFixed(1) + 'w';
    }
  }

  public static transDistanceWithUnit(distance: number): string {
    if (distance > 1000) {
     return (distance / 1000.00).toFixed(2) + '公里';
    } else {
      return distance.toFixed(2) + '米';
    }
  }
}

export class RetryUtil {
  /**
   * 重试执行函数，直到成功或达到最大重试次数
   * @param times 最大重试次数
   * @param func 要执行的函数
   * @param checkIfSuccess 检查是否成功的函数
   * @param delay 重试间隔时间（毫秒），默认1000ms
   * @returns Promise<boolean> 是否最终成功
   */
  static async retry(
    times: number, 
    func: () => PromiseLike<void>, 
    checkIfSuccess: () => PromiseLike<boolean>,
    delay: number = 1000
  ): Promise<boolean> {
    for (let i = 0; i < times; i++) {
      try {
        await func();
        const success = await checkIfSuccess();
        if (success) {
          return true;
        }
      } catch (error) {
        console.error(`Retry 重试第 ${i + 1} 次失败:`, error, (error as Error).stack);
      }
      
      // 如果不是最后一次重试，则等待指定时间后继续
      if (i < times - 1) {
        await RetryUtil.sleep(delay);
      }
    }
    return false;
  }

  /**
   * 重试执行函数（简化版本，无需成功检查函数）
   * @param times 最大重试次数
   * @param func 要执行的函数，返回Promise<T>
   * @param delay 重试间隔时间（毫秒），默认1000ms
   * @returns Promise<T> 函数执行结果
   * @throws 如果所有重试都失败，抛出最后一次的错误
   */
  static async retryWithResult<T>(
    times: number,
    func: () => PromiseLike<T>,
    delay: number = 1000
  ): Promise<T> {
    let lastError: Error = new Error();
    
    for (let i = 0; i < times; i++) {
      try {
        return await func();
      } catch (error) {
        lastError = error;
        console.error(`RetryWithResults 重试第 ${i + 1} 次失败:`, error, error.stack);
        
        // 如果不是最后一次重试，则等待指定时间后继续
        if (i < times - 1) {
          await RetryUtil.sleep(delay);
        }
      }
    }
    
    throw lastError;
  }

  /**
   * 带有指数退避的重试
   * @param times 最大重试次数
   * @param func 要执行的函数
   * @param initialDelay 初始延迟时间（毫秒），默认1000ms
   * @param backoffFactor 退避因子，默认2
   * @param maxDelay 最大延迟时间（毫秒），默认30000ms
   * @returns Promise<T> 函数执行结果
   */
  static async retryWithBackoff<T>(
    times: number,
    func: () => PromiseLike<T>,
    initialDelay: number = 1000,
    backoffFactor: number = 2,
    maxDelay: number = 30000
  ): Promise<T> {
    let lastError: Error = new Error();
    let delay = initialDelay;
    
    for (let i = 0; i < times; i++) {
      try {
        return await func();
      } catch (error) {
        lastError = error;
        console.error(`重试第 ${i + 1} 次失败:`, error);
        
        // 如果不是最后一次重试，则等待指定时间后继续
        if (i < times - 1) {
          await RetryUtil.sleep(delay);
          delay = Math.min(delay * backoffFactor, maxDelay);
        }
      }
    }
    
    throw lastError;
  }

  /**
   * 条件重试：只有满足特定条件的错误才会重试
   * @param times 最大重试次数
   * @param func 要执行的函数
   * @param shouldRetry 判断是否应该重试的函数
   * @param delay 重试间隔时间（毫秒），默认1000ms
   * @returns Promise<T> 函数执行结果
   */
  static async retryIf<T>(
    times: number,
    func: () => PromiseLike<T>,
    shouldRetry: (error: Error) => boolean,
    delay: number = 1000
  ): Promise<T> {
    let lastError: Error = new Error();
    
    for (let i = 0; i < times; i++) {
      try {
        return await func();
      } catch (error) {
        lastError = error;
        console.error(`重试第 ${i + 1} 次失败:`, error);
        
        // 检查是否应该重试
        if (!shouldRetry(error)) {
          lastError = error;
          throw lastError;
        }
        
        // 如果不是最后一次重试，则等待指定时间后继续
        if (i < times - 1) {
          await RetryUtil.sleep(delay);
        }
      }
    }
    
    throw lastError;
  }

  /**
   * 延迟执行
   * @param ms 延迟时间（毫秒）
   * @returns Promise<void>
   */
  private static sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}