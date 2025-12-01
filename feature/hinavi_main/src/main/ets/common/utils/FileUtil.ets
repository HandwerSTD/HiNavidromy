/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { fileIo, fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import Logger, { MyLogUtil } from './Logger';
import { Context } from '@kit.AbilityKit';

const TAG: string = '[FileUtils]';

export class FileUtils {
  static async accessLocalFile(fileName: string): Promise<string> {
    try {
      const fileType: Array<string> = ['flac', 'FLAC', 'mp3', 'MP3']
      for(let type of fileType) {
        let filePath = FileUtils.getFilesDir() + `/${fileName}.${type}`
        if(await(FileUtils.fileExists(filePath))) {
          let file = await fileIo.open(filePath)
          let fdPath = 'fd://' + file.fd
          return fdPath
        }
      }
      return ''
    } catch (e) {
      return ''
    }
  }
  static moveFile(src: string, dest: string, mode: number = 0): Promise<void> {
    return fileIo.moveFile(src, dest, mode)
  }
  static getCacheDir() {
    return (getContext()).cacheDir + '/cloud_cache'
  }
  static getFilesDir() {
    return (getContext()).filesDir + '/cloud_files'
  }
  static getFilenameFromUri(uri: string) {
    return uri.substring(uri.lastIndexOf('/') + 1);
  }
  public static copyFileSync(src: string, dest: string): void {
    Logger.info(TAG, 'copyFile path src: ' + src);
    Logger.info(TAG, 'copyFile path dest: ' + dest);
    try {
      let srcFile = fileIo.openSync(src, fileIo.OpenMode.READ_ONLY);
      let distFile = fileIo.openSync(dest, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      fileIo.copyFileSync(srcFile.fd, distFile.fd);
      fileIo.closeSync(srcFile);
      fileIo.closeSync(distFile);
      Logger.info(TAG, 'copyFile success');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      MyLogUtil.err(err as Error, TAG, `copyFile failed code: ${err.code}`);
    }
  }
  public static async copyFileAsync(src: string, dest: string): Promise<void> {
    Logger.info(TAG, 'copyFile path src: ' + src);
    Logger.info(TAG, 'copyFile path dest: ' + dest);
    try {
      let srcFile = await fileIo.open(src, fileIo.OpenMode.READ_ONLY);
      let distFile = await fileIo.open(dest, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      await fileIo.copyFile(srcFile.fd, distFile.fd);
      await fileIo.close(srcFile);
      await fileIo.close(distFile);
      Logger.info(TAG, 'copyFile success');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      MyLogUtil.err(err as Error, TAG, `copyFile failed code: ${err.code}`);
    }
  }
  public static deleteFile(filePath: string): void {
    Logger.info(TAG, 'rmdir deleteFile:' + filePath);
    fileIo.rmdir(filePath, (err: BusinessError) => {
      if (err) {
        MyLogUtil.err(err as Error, TAG, `deleteFile failed code: ${err.code}`);
      } else {
        Logger.info(TAG, 'deleteFile succeed');
      }
    });
  }

  public static saveBuffer2File(filePath: string, buffer: ArrayBuffer): void {
    Logger.info(TAG, 'saveBuffer2File filePath:' + filePath);
    try {
      let distFile = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      fileIo.write(distFile.fd, buffer);
      fileIo.closeSync(distFile.fd)
      Logger.info(TAG, 'saveBuffer2File success');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      MyLogUtil.err(err as Error, TAG, `saveBuffer2File failed code: ${err.code}`);
    }
  }

  public static getFileUri(filePath: string): string {
    return fileUri.getUriFromPath(filePath);
  }

  public static savePixelMap2File(pixelMap: PixelMap, filePath: string) {
    Logger.info(TAG, 'savePixelMap2File filePath:' + filePath);
    let packOpts: image.PackingOption = { format: "image/png ", quality: 100 };
    let file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
    let imagePackerApi = image.createImagePacker();
    imagePackerApi.packToFile(pixelMap, file.fd, packOpts).then(() => {
      Logger.info(TAG, 'savePixelMap2File success');
      fileIo.closeSync(file.fd);
    }).catch((err: BusinessError) => {
      fileIo.closeSync(file.fd);
      MyLogUtil.err(err as Error, TAG, `savePixelMap2File failed code: ${err.code}`);
    })
  }

  public static async fileExists(path: string): Promise<boolean> {
    return await fileIo.access(path);
  }

  public static async createDir(path: string) {
    return await fileIo.mkdir(path, true);
  }

  public static async deleteDir(path: string) {
    return await fileIo.rmdir(path);
  }

  public static async createDirIfNE(path: string) {
    try {
      await fileIo.mkdir(path);
    } catch (e) {
      Logger.warn(`FileUtil`, `createDirIfExist error: ${JSON.stringify(e)}`)
    }
  }
  public static async deleteDirIfExist(path: string) {
    try {
      await fileIo.rmdir(path);
    } catch (e) {
      Logger.warn(`FileUtil`, `deleteirIfExist error: ${JSON.stringify(e)}`)
    }
  }

  public static async writeStrToFile(path: string, content: string) {
    let file = await fileIo.open(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    await fileIo.write(file.fd, content);
    await fileIo.close(file);
  }

  public static async ls(path: string) {
    return fileIo.listFile(path)
  }
}
