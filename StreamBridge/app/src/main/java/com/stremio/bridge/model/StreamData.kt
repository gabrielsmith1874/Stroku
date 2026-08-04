package com.stremio.bridge.model

/**
 * Data class representing stream information from Stremio
 */
data class StreamData(
    val url: String,
    val title: String,
    val format: String,
    val subtitles: List<SubtitleData> = emptyList(),
    val audioTracks: List<AudioTrackData> = emptyList()
)

/**
 * Data class representing subtitle information
 */
data class SubtitleData(
    val url: String,
    val language: String,
    val label: String,
    val format: String
)

/**
 * Data class representing audio track information
 */
data class AudioTrackData(
    val language: String,
    val label: String,
    val codec: String,
    val channels: String
)
