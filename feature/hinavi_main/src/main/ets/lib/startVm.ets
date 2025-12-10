import { fileIo as fs } from '@kit.CoreFileKit'
import { SystemImageUtils } from '../../../../Index'
import { VMSwitcher } from './VMSwitcher'
import { application } from '@kit.AbilityKit'

interface PortMapping {
  guest?: number
  host?: number
}

interface VmOptions {
  baseDir: string
  cpu: number
  memory: number
  portMapping: PortMapping[]
  kernel: string
  rootFilesystem: string
  sharedFolder: string
  serialUnixSocket: string
  guestAgentSocket: string
}

function startVm_legacy(options: VmOptions) {

  const basic = ['-machine', 'virt', '-cpu', 'cortex-a53', '-nographic', '-L', options.baseDir]
  const serial = ['-serial', "unix:" + options.serialUnixSocket + ",server,nowait"]
  const cpuMem = ['-smp', options.cpu.toString(), '-m', options.memory + 'M']
  const kernel = ['-kernel', options.kernel]
  const network =
    ['-netdev', "user,id=eth0" + options.portMapping.map(it => `,hostfwd=tcp::${it.host}-:${it.guest}`).join('')]
  const shared = ["-device", "virtio-net-device,netdev=eth0",
    "-fsdev", "local,security_model=mapped-file,id=fsdev0,path=" + options.sharedFolder,
    "-device", "virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare"]
  const drive = ["-drive", "if=none,format=qcow2,file=" + options.rootFilesystem + ",id=hd0", "-device",
    "virtio-blk-device,drive=hd0"]
  const kernelParam = ["-append",
    "root=/dev/vda rw rootfstype=ext4 console=ttyAMA0 TERM=ansi"]

  const args =
    ['qemu-system-aarch64', ...basic, ...serial, ...cpuMem, ...kernel, ...network, ...shared, ...drive, ...kernelParam]

  if (fs.accessSync(options.serialUnixSocket, fs.AccessModeType.EXIST)) {
    fs.unlinkSync(options.serialUnixSocket)
  }
  if (!fs.accessSync(options.sharedFolder, fs.AccessModeType.EXIST)) {
    fs.mkdirSync(options.sharedFolder)
  }

  VMSwitcher.startVM({
    argsLines: args.join('\n'),
    unixSocket: options.serialUnixSocket
  });
}

async function startVm(options: VmOptions) {
  if (await SystemImageUtils.getStoredVersion(application.getApplicationContext()) === 0) {
    startVm_legacy(options)
    return
  }

  const basic = ['-machine', 'virt,gic-version=max,usb=off,memory-backend=mem0',
    '-cpu', 'max,pauth-impdef=on', '-accel', 'tcg,thread=multi,tb-size=1024',
    "-object", "rng-random,filename=/dev/urandom,id=rng0",
    "-device", "virtio-rng-pci-non-transitional,rng=rng0",
    '-nographic', '-L', options.baseDir]

  const serial = ['-serial', "unix:" + options.serialUnixSocket + ",server,nowait"]

  const cpuMem = ['-smp', options.cpu.toString(),
    "-object", `memory-backend-ram,id=mem0,size=${options.memory}M,merge=off,prealloc=off`, '-m', options.memory + 'M']

  const kernel = ['-kernel', options.kernel]

  const network = ["-device", "virtio-net-pci-non-transitional," +
    "netdev=eth0,csum=on,gso=on,guest_tso4=on,guest_tso6=on,guest_ecn=off,mrg_rxbuf=on",
    '-netdev', "user,id=eth0" + options.portMapping.map(it => `,hostfwd=tcp::${it.host}-:${it.guest}`).join('')]

  const shared =
    ["-fsdev", "local,security_model=mapped-file,id=fsdev0,path=" + options.sharedFolder,
      "-device", "virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare"]

  const drive = ["-drive", "if=none,format=qcow2,file=" + options.rootFilesystem
    + ",id=hd0,cache=none,aio=threads,discard=unmap,detect-zeroes=unmap",
    "-object", "iothread,id=iothread0",
    "-device", "virtio-scsi-pci-non-transitional,id=scsi0,num_queues=" + options.cpu.toString() + ",iothread=iothread0",
    "-device", "scsi-hd,drive=hd0,bus=scsi0.0"]

  const kernelParam = ["-append",
    "root=" + '/dev/sda' + " rw rootfstype=ext4 rootwait console=ttyAMA0 " +
      "mitigations=off audit=0 nmi_watchdog=0 hardened_usercopy=off random.trust_cpu=on virtio_balloon.config_impl=0 " +
      "TERM=ansi init=" + '/init']

  const guestAgent = [
    '-device', 'virtio-serial-pci-non-transitional,id=virtio-serial0',
    '-chardev', 'socket,path=' + options.guestAgentSocket + ',server=on,wait=off,id=qga0',
    '-device', 'virtserialport,chardev=qga0,bus=virtio-serial0.0,name=org.qemu.guest_agent.0'
  ]


  const args: string[] = [
    'qemu-system-aarch64',
    ...basic,
    ...serial,
    ...cpuMem,
    ...kernel,
    ...network,
    ...shared,
    ...drive,
    ...kernelParam,
    ...guestAgent
  ]

  if (fs.accessSync(options.serialUnixSocket, fs.AccessModeType.EXIST)) {
    fs.unlinkSync(options.serialUnixSocket)
  }
  if (fs.accessSync(options.guestAgentSocket, fs.AccessModeType.EXIST)) {
    fs.unlinkSync(options.guestAgentSocket)
  }
  if (!fs.accessSync(options.sharedFolder, fs.AccessModeType.EXIST)) {
    fs.mkdirSync(options.sharedFolder)
  }

  VMSwitcher.startVM({
    argsLines: args.join('\n'),
    unixSocket: options.serialUnixSocket
  });
}

export { startVm, PortMapping, VmOptions }