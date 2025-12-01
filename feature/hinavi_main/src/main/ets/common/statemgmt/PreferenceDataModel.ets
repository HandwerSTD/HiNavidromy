@ObservedV2
export class PrefDataModel {
  @Trace tabRightHand: boolean = false
  @Trace playerRightHand: boolean = false
  @Trace autoNavRightHandMode: boolean = false
  @Trace useStylusControl: boolean = false
  @Trace swipeToNextTrack: boolean = true
  @Trace enhancedBgStreaming: boolean = false
  @Trace bgFlowColorStrat: BG_FLOW_COLOR_STRAT = 0
  @Trace fistGesture: FIST_GESTURE = 0
  @Trace keepScreenOn: boolean = false
  @Trace audioQuality: number = 0
  @Trace SQ_onCellular: boolean = true
  @Trace enableCoverEdgeGlow: boolean = true
  @Trace imageLoadCompatMode: boolean = false
}

export enum BG_FLOW_COLOR_STRAT {
  LIGHT = 0,
  DARK,
  SYSTEM,
  AUTO
}
export enum FIST_GESTURE {
  PLAYBACK = 0,
  HEART
}