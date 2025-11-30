export type appOptions = {
  argsLines: string
  unixSocket: string
}

export const startVM: (options: appOptions) => void;