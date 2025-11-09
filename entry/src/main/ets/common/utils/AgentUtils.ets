import { Album, Artist, Song } from "@handwer/api_adapter";
import { SongConvertUtils } from "../services/PlaybackController/convert";

// TODO: AgentUtils
export class AgentUtils {
  static readonly agentId = 'agentff076a3ec4214f94ab0d73f605099800'
  static generatePrompt_SearchSongDetail(song: Song) {
    return `介绍一下由 ${SongConvertUtils.getArtists(song.artists)} 等艺术家创作的歌曲 ${song.name} 的信息，以及这首歌的创作背景`
  }
  static generatePrompt_SearchAlbumDetail(album: Album) {
    return `《${album.name}》- ${SongConvertUtils.getArtists(album.artists)} 这张专辑的简介和创作背景是什么？`
  }
  static generatePrompt_SearchArtistDetail(artists: Artist[], song?: Song) {
    return `介绍一下${song ? `歌曲 ${song!.name} 的` : ''}艺术家 ${artists.map(v => v.name).join(', ')}，包括他们的基本信息、创作流派风格等`
  }
  static generatePrompt_LyricAnalyze(song: Song, allLyrics: string[], targetLyrics: string[], targetIndex: number[]) {
    return `歌曲 ${song.name} 中的歌词为：${allLyrics.join('\n')}，请解析其中的${targetIndex.length > 0 ? `第 ${targetIndex.join(',')} 句` : ''}：${targetLyrics.join('\n')}`
  }
}