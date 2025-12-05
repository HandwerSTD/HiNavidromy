import axios, { AxiosRequestConfig } from '@ohos/axios'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { buffer } from '@kit.ArkTS'

// 1. 请求上下文配置
export interface NavidromeRequestContext {
  baseUrl: string       // Navidrome 服务器地址，如 'http://192.168.1.100:4533'
  username: string      // 用户名
  password: string      // 密码
}

// 2. MD5 生成函数 (Subsonic API 认证需要)
function getMD5Sync(message: string): string {
  const md = cryptoFramework.createMd('MD5')
  md.updateSync({ data: new Uint8Array(buffer.from(message, 'utf-8').buffer) })
  const mdResult = md.digestSync()
  return Array.from(mdResult.data)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('')
}

// 3. 核心请求函数
async function navidromeRequest<T>(ctx: NavidromeRequestContext, endpoint: string, params: Record<string, string> = {}): Promise<T> {
  // 生成随机 salt 和 token
  const salt = Math.random().toString(36).substring(2, 8)
  const token = getMD5Sync(ctx.password + salt)
  
  // Subsonic API 必需的认证参数
  const authParams: Record<string, string> = {
    u: ctx.username,      // 用户名
    t: token,             // MD5(password + salt)
    s: salt,              // 随机盐值
    v: '1.16.1',          // API 版本
    c: 'MyClient',        // 客户端名称
    f: 'json'             // 返回格式
  }
  
  const config: AxiosRequestConfig = {
    baseURL: ctx.baseUrl,
    url: endpoint,
    params: { ...authParams, ...params },
    timeout: 15000
  }
  
  const response = await axios.request(config)
  return response.data['subsonic-response']
}

const ctx: NavidromeRequestContext = {
  baseUrl: 'http://localhost:4533',
  username: 'CloudPurePlay',
  password: 'localhostPurePlay'
}

export class NavidromeRequestUtil {
  static async refreshLibrary(): Promise<void> {
    await navidromeRequest(ctx, '/rest/startScan')
  }
}