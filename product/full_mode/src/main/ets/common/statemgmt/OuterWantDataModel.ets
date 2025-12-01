
export type OuterWantType = 'new_config' | 'share_song' | 'quick_play' | '';

@ObservedV2
export class OuterWantDataModel {
  @Trace type: OuterWantType
  @Trace ui: boolean = false
  @Trace data: Record<string, Object>

  constructor(t: OuterWantType = '', d: Record<string, Object> = {}, ui: boolean = false) {
    this.type = t;
    this.data = d;
    this.ui = ui
  }
}

// export interface NewConfigOuterWant {
//   apiName: string
//   apiConfig: Object
// }