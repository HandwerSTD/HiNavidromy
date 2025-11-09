import { MMKV } from '@tencent/mmkv'
import { common } from '@kit.AbilityKit'

export class KVStoreUtil {
  mmkv: MMKV

  constructor(name?: string) {
    if (name === undefined) {
      this.mmkv = MMKV.defaultMMKV(MMKV.MULTI_PROCESS_MODE)
    } else {
      this.mmkv = MMKV.mmkvWithID(name, MMKV.MULTI_PROCESS_MODE)
    }
  }
  static init(rootPath?: string) {
    MMKV.initializeWithPath(`${rootPath}/MMKVrootDir`, `${rootPath}/MMKVcacheDir`)
  }
  static initDefault(context: common.ApplicationContext) {
    MMKV.initialize(context)
  }

  storeString(key: string, param: string) {
    this.mmkv.encodeString(key, param)
  }
  storeInt32(key: string, param: number) {
    this.mmkv.encodeInt32(key, param)
  }
  storeDouble(key: string, param: number) {
    this.mmkv.encodeDouble(key, param)
  }
  storeBool(key: string, param: boolean) {
    this.mmkv.encodeBool(key, param)
  }
  queryString(key: string): string {
    return this.mmkv.decodeString(key) ?? ""
  }
  queryInt32(key: string, defaultValue?: number) {
    return this.mmkv.decodeInt32(key) ?? defaultValue
  }
  queryDouble(key: string) {
    return this.mmkv.decodeDouble(key)
  }
  queryBool(key: string) {
    return this.mmkv.decodeBool(key)
  }
  getAllKeys(): string[]{
    return this.mmkv.allKeys()
  }
  deleteByKey(key: string) {
    this.mmkv.removeValueForKey(key)
  }
  deleteAllKeys() {
    this.mmkv.clearAll()
  }
  _debug() {
    return JSON.stringify(this.getAllKeys())
  }
}

// 调试用
// export class KVStoreUtil {
//   mmkv?: MMKV
//
//   constructor(name?: string) {
//     // if (name == undefined) {
//     //   this.mmkv = MMKV.defaultMMKV()
//     // } else {
//     //   this.mmkv = MMKV.mmkvWithID(name)
//     // }
//   }
//
//   storeString(key: string, param: string) {
//     // this.mmkv.encodeString(key, param)
//   }
//   storeInt32(key: string, param: number) {
//     // this.mmkv.encodeInt32(key, param)
//   }
//   storeDouble(key: string, param: number) {
//     // this.mmkv.encodeDouble(key, param)
//   }
//   storeBool(key: string, param: boolean) {
//     // this.mmkv.encodeBool(key, param)
//   }
//   queryString(key: string): string {
//     return this.mmkv?.decodeString(key) ?? ""
//   }
//   queryInt32(key: string, defaultValue?: number) {
//     return this.mmkv?.decodeInt32(key) ?? defaultValue
//   }
//   queryDouble(key: string) {
//     return this.mmkv?.decodeDouble(key)
//   }
//   queryBool(key: string) {
//     return this.mmkv?.decodeBool(key)
//   }
//   getAllKeys(): string[]{
//     return this.mmkv?.allKeys() ?? []
//   }
//   deleteByKey(key: string) {
//     // this.mmkv.removeValueForKey(key)
//   }
// }

