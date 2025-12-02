import { File, InputStream, TarArchiveInputStream, TarArchiveEntry, OutputStream } from "@ohos/commons-compress";
import { PermissionUtil } from "@pura/harmony-utils";
import { PortMapping, startVm } from "../lib/startVm";
import { VMSwitcher } from "../lib/VMSwitcher";
import appOption from "../model/appOption";
import { application, bundleManager, common } from "@kit.AbilityKit";
import { promptAction, window } from "@kit.ArkUI";
import { hilog } from "@kit.PerformanceAnalysisKit";
import preference from '@ohos.data.preferences';
import fs from '@ohos.file.fs';
import { geoLocationManager } from "@kit.LocationKit";
import { BackgroundTaskManager } from "./utils/BackgroundTaskManager";
import GlobalStore from "./statemgmt/GlobalStore";
import { DEBUG } from '../../../../BuildProfile'

const DOMAIN = 0x0000;

class ServiceInitUtils {
  async onWindowStageCreate(context: Context): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    const jit = await PermissionUtil.checkPermissions('ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY')
    if (VMSwitcher.isSecurityMode() || !jit) {
      VMSwitcher.isTCI = true;
    } else {
      VMSwitcher.isTCI = false;
    }
    if (VMSwitcher.isTCI || !DEBUG) {
      GlobalStore.developerMode = false;
    } else {
      GlobalStore.developerMode = true
    }

    const appContext = context.getApplicationContext();
    const appPref: preference.Preferences = await preference.getPreferences(appContext, appOption.preferenceName);

    await this.extractKernelAndRootFilesystem(appContext, appPref);

    console.log('EXTRACT COMPLETED')

    await this.loadPreferences(appPref);

    console.log('PREPARE START VM')

    await this.startVm(appContext);

    const bundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    AppStorage.setOrCreate('bundleInfo', bundleInfo)
  }
  async startSimulateBg(context: common.UIAbilityContext) {
    if (AppStorage.get<boolean>(appOption.simulateBg)) {
      PermissionUtil.requestPermissionsEasy("ohos.permission.APPROXIMATELY_LOCATION")
        .then((res) => {
          if (!res) {
            promptAction.openToast({
              message: '请授予权限'
            })
            return;
          }
          geoLocationManager.on("locationChange", {
            interval: 10,
            locationScenario: geoLocationManager.PowerConsumptionScenario.NO_POWER_CONSUMPTION
          }, () => {})
          BackgroundTaskManager.startContinuousTask(context as common.UIAbilityContext)
          promptAction.openToast({
            message: '后台模拟启动成功'
          })
        })

    }
  }

  // ----------------------------------------------------------

  private async startVm(appContext: common.ApplicationContext) {

    const cpuCount = AppStorage.get(appOption.cpuCountName) as number;
    const memSize = AppStorage.get(appOption.memSizeName) as number;
    const portMappingEnabled = AppStorage.get(appOption.portMappingEnabled) as boolean;
    const rootFilesystem = AppStorage.get(appOption.rootFilesystem) as string
    const sharedFolder = AppStorage.get(appOption.sharedHost) as string
    const vmBaseDir = AppStorage.get(appOption.vmBaseDir) as string
    const kernelFile = AppStorage.get(appOption.kernel) as string

    let portMapping: PortMapping[] = []
    const portUsed: number[] = []
    if (portMappingEnabled) {
      const candidates = AppStorage.get(appOption.portMapping) as PortMapping[];
      for (let i = 0; i < candidates.length; i++) {
        let item = candidates[i];
        let port: number = item.host!!;
        const used = VMSwitcher.checkPortUsed(port)
        if (!used) {
          portMapping.push(item)
        } else {
          portUsed.push(port)
          hilog.info(DOMAIN, 'testTag', 'host port %{public}d of PortMapping is used by others', port)
        }
      }
    }

    AppStorage.setOrCreate(appOption.portUsedByOthers, portUsed)

    hilog.info(DOMAIN, 'testTag', 'startVM with cpu: %{public}d, mem: %{public}dMB, portMapping: %{public}s',
      cpuCount, memSize, portMapping)

    const serialUnixSocket = appContext.tempDir + '/serial_socket'

    startVm({
      baseDir: vmBaseDir,
      cpu: cpuCount,
      memory: memSize,
      portMapping: portMapping,
      kernel: kernelFile,
      rootFilesystem,
      sharedFolder,
      serialUnixSocket
    })
  }

  private async loadDefaultPref(appPref: preference.Preferences) {
    await appPref.put(appOption.portMappingEnabled, true);
    if (await appPref.get(appOption.portMapping, '[]') === '[]') {
      await appPref.put(appOption.portMapping, JSON.stringify([{ guest: 4533, host: 4533 } as PortMapping]))
    }
  }
  private async loadPreferences(appPref: preference.Preferences) {
    await this.loadDefaultPref(appPref);
    const vmCpuCount = await appPref.get(appOption.cpuCountName, 2);
    const vmMemSize = await appPref.get(appOption.memSizeName, 2048);
    const keepScreenOn = await appPref.get(appOption.keepScreenOn, false) as boolean;
    const portMappingEnabled = await appPref.get(appOption.portMappingEnabled, false) as boolean;
    const portMapping = JSON.parse(await appPref.get(appOption.portMapping, '[]') as string) as PortMapping[];
    const simulateBg = await appPref.get(appOption.simulateBg, false) as boolean;
    AppStorage.setOrCreate(appOption.cpuCountName, vmCpuCount);
    AppStorage.setOrCreate(appOption.memSizeName, vmMemSize);
    AppStorage.setOrCreate(appOption.keepScreenOn, keepScreenOn);
    AppStorage.setOrCreate(appOption.portMappingEnabled, portMappingEnabled);
    AppStorage.setOrCreate(appOption.portMapping, portMapping);
    AppStorage.setOrCreate(appOption.simulateBg, simulateBg)
  }

  private async extractKernelAndRootFilesystem(appContext: common.ApplicationContext,
    appPref: preference.Preferences): Promise<void> {

    const reset: boolean = await this.getResetFlag(appPref)

    hilog.info(DOMAIN, 'testTag',
      'extractResourcesForVM, filesDir: %{public}s, tempDir: %{public}s, reset: %{public}s',
      appContext.filesDir, appContext.tempDir, reset);

    let bundleVmDir = appContext.filesDir + "/vm";
    if (!fs.accessSync(bundleVmDir, fs.AccessModeType.EXIST)) {
      fs.mkdirSync(bundleVmDir);
    }

    for (let filename of ["vm/kernel_aarch64", "vm/efi-virtio.rom"]) {
      this.extractVmResourceFile(appContext, filename, reset);
    }

    const use9pRootFs = false
    AppStorage.setOrCreate(appOption.use9pRootFs, use9pRootFs)

    const sharedGuest = use9pRootFs ? '/' : '/mnt/share'
    const sharedHost = appContext.filesDir + '/' + (use9pRootFs ? 'vm/rootfs' : 'share')
    const rootFilesystem = bundleVmDir + '/' + (use9pRootFs ? 'rootfs' : 'rootfs_aarch64.qcow2')
    AppStorage.setOrCreate(appOption.sharedGuest, sharedGuest)
    AppStorage.setOrCreate(appOption.sharedHost, sharedHost)
    AppStorage.setOrCreate(appOption.rootFilesystem, rootFilesystem)

    // create music folder
    // if (!fs.accessSync(sharedHost + '/music/', fs.AccessModeType.EXIST)) {
    //   fs.mkdirSync(sharedHost + '/music/')
    // }

    AppStorage.setOrCreate(appOption.vmBaseDir, bundleVmDir)
    AppStorage.setOrCreate(appOption.kernel, bundleVmDir + '/kernel_aarch64')

    if (!use9pRootFs) {
      this.extractQcow2RootFs(appContext, reset);
    } else {
      await this.extractTarRootFs(appContext, reset);
    }
  }

  private extractQcow2RootFs(appContext: common.ApplicationContext, reset: boolean) {
    this.extractVmResourceFile(appContext, "vm/rootfs_aarch64.qcow2", reset);
  }

  private async extractTarRootFs(appContext: common.ApplicationContext, reset: boolean) {
    const target = appContext.filesDir + '/vm/rootfs';
    let completeMark: string = appContext.filesDir + '/vm/.rootfs_complete';
    if (reset) {
      await this.deleteDirectoryRecursive(target)
      await this.extractRootFsTar(appContext, target);
      fs.openSync(completeMark, fs.OpenMode.CREATE);
    } else {
      if (!fs.accessSync(completeMark, fs.AccessModeType.EXIST)) {
        await this.deleteDirectoryRecursive(target)
        await this.extractRootFsTar(appContext, target);
        fs.openSync(completeMark, fs.OpenMode.CREATE);
      }
    }
  }

  private async deleteDirectoryRecursive(dirPath: string) {
    try {
      const dirEntries = await fs.listFile(dirPath, { recursion: false });
      for (const entry of dirEntries) {
        const fullPath = `${dirPath}/${entry}`;
        const stat = await fs.stat(fullPath);

        if (stat.isDirectory()) {
          await this.deleteDirectoryRecursive(fullPath);
        } else {
          await fs.unlink(fullPath);
        }
      }
      await fs.rmdir(dirPath);
    } catch (err) {
      console.error(`failed to remove directory: ${JSON.stringify(err)}`);
    }
  }

  private async extractVmResourceFile(appContext: common.ApplicationContext, filename: string, reset: boolean) {
    let filePath = appContext.filesDir + "/" + filename;
    if (!fs.accessSync(filePath, fs.AccessModeType.EXIST) || reset) {
      const resManager = appContext
      let value: Uint8Array = resManager.resourceManager.getRawFileContentSync(filename);
      let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, value.buffer);
      fs.closeSync(file);
      hilog.info(DOMAIN, 'testTag', 'Extract resource file: %{public}s', filePath);
    }
  }

  private async extractRootFsTar(appContext: common.ApplicationContext, target: string) {
    try {
      const resManager = appContext
      const value = resManager.resourceManager.getRawFileContentSync("vm/rootfs_aarch64.tar");
      const tar = appContext.tempDir + '/rootfs_aarch64.tar';
      let file = fs.openSync(tar, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, value.buffer);
      fs.closeSync(file);

      if (!fs.accessSync(target, fs.AccessModeType.EXIST)) {
        fs.mkdirSync(target, true);
      }

      let input: File = new File(appContext.tempDir, 'rootfs_aarch64.tar');
      let inputFileStream: InputStream = new InputStream();
      inputFileStream.setFilePath(input.getPath());
      let fileTarInputStream: TarArchiveInputStream =
        new TarArchiveInputStream(inputFileStream, 512 * 20, 512, '', false);
      let tarArchiveEntry: TarArchiveEntry;
      while ((tarArchiveEntry = fileTarInputStream.getNextTarEntry()) !== null) {

        let name: string = tarArchiveEntry.getName();
        if (name.startsWith('./')) {
          name = name.substring(2)
        }

        if (tarArchiveEntry.isDirectory()) {
          const dir = target + '/' + name
          let acc = fs.accessSync(dir, fs.AccessModeType.EXIST);
          if (!acc) {
            fs.mkdirSync(dir, true);
          }
        } else if (tarArchiveEntry.isFile()) {
          let tarFile: File = new File(target, name);
          let fos: OutputStream | null = null;
          try {
            fos = new OutputStream();
            fos!.setFilePath(tarFile.getPath());
            let read: number = -1;
            let buffer: Int8Array = new Int8Array(tarArchiveEntry.getRealSize().toNumber());
            while ((read = fileTarInputStream.readBytes(buffer)) > 0) {
              fos!.writeBytesOffset(buffer, 0, read);
            }
          } catch (e) {
            console.log('error extract file', e);
          } finally {
            fos!.close();
          }
        }
      }
    } catch (e) {
      console.log('error extract rootfs', e);
    }
  }

  private async getResetFlag(appPref: preference.Preferences): Promise<boolean> {
    const flag = await appPref.get(appOption.resetLinuxFlag, false) as boolean
    await appPref.delete(appOption.resetLinuxFlag)
    await appPref.flush()
    return flag
  }

}

export default new ServiceInitUtils()