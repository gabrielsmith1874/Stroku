package com.stremio.bridge.util

import android.content.Intent
import android.net.Uri
import android.util.Log
import com.google.gson.Gson
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import com.stremio.bridge.model.StreamData
import com.stremio.bridge.model.SubtitleData
import com.stremio.bridge.model.AudioTrackData

/**
 * Utility class to parse Stremio external player intents
 * Handles various formats that Stremio might send
 */
object StremioIntentParser {
    
    private const val TAG = "StremioIntentParser"
    private val gson = Gson()
    
    /**
     * Parse Stremio intent and extract stream data
     */
    fun parseIntent(intent: Intent): StreamData? {
        Log.d(TAG, "Parsing intent: ${intent.action}")
        
        return when {
            // Handle stremio:// protocol
            intent.data?.scheme == "stremio" -> {
                val data = intent.data
                if (data != null) parseStremioProtocol(data) else null
            }
            
            // Handle direct video URLs
            intent.data?.scheme in listOf("http", "https") -> {
                val data = intent.data
                if (data != null) parseDirectUrl(data) else null
            }
            
            // Handle intent extras
            intent.hasExtra("stream_data") -> parseStreamDataExtra(intent)
            
            // Handle JSON data in extras
            intent.hasExtra("json_data") -> parseJsonData(intent.getStringExtra("json_data"))
            
            // Handle Stremio's standard extras
            intent.hasExtra("video_url") -> parseStandardExtras(intent)
            
            else -> {
                Log.w(TAG, "Unknown intent format")
                null
            }
        }
    }
    
    private fun parseStremioProtocol(uri: Uri): StreamData? {
        Log.d(TAG, "Parsing stremio:// protocol: $uri")
        
        try {
            // stremio://stream/video/tt1234567:1:1:en
            // or stremio://stream/movie/tt1234567:en
            val pathSegments = uri.pathSegments
            
            if (pathSegments.size >= 3) {
                // val type = pathSegments[1] // video, movie, series
                // val id = pathSegments[2]   // content ID
                
                // For now, we'll need to get the actual stream URL from Stremio's API
                // This is a simplified version - in reality, you'd need to query Stremio
                return StreamData(
                    url = "https://example.com/stream.m3u8", // Placeholder
                    title = "Stremio Content",
                    format = "hls"
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing stremio protocol", e)
        }
        
        return null
    }
    
    private fun parseDirectUrl(uri: Uri): StreamData? {
        Log.d(TAG, "Parsing direct URL: $uri")
        
        var url = uri.toString()
        
        // Fix localhost URLs - replace 127.0.0.1 with actual network IP
        url = fixLocalhostUrl(url)
        
        val format = detectFormat(url)
        val title = extractTitleFromUrl(url)
        
        return StreamData(
            url = url,
            title = title,
            format = format
        )
    }
    
    private fun parseStreamDataExtra(intent: Intent): StreamData? {
        Log.d(TAG, "Parsing stream_data extra")
        
        val streamDataJson = intent.getStringExtra("stream_data")
        return parseJsonData(streamDataJson)
    }
    
    private fun parseJsonData(jsonString: String?): StreamData? {
        if (jsonString.isNullOrEmpty()) return null
        
        Log.d(TAG, "Parsing JSON data: $jsonString")
        
        try {
            val jsonObject = JsonParser.parseString(jsonString).asJsonObject
            
            val url = jsonObject.get("url")?.asString
            val title = jsonObject.get("title")?.asString ?: "Unknown Title"
            val format = jsonObject.get("format")?.asString ?: detectFormat(url ?: "")
            
            if (url != null) {
                val fixedUrl = fixLocalhostUrl(url)
                
                // Parse subtitles if available
                val subtitles = mutableListOf<SubtitleData>()
                jsonObject.get("subtitles")?.asJsonArray?.forEach { subtitleJson ->
                    val subtitle = subtitleJson.asJsonObject
                    val subtitleUrl = subtitle.get("url")?.asString ?: ""
                    subtitles.add(
                        SubtitleData(
                            url = fixLocalhostUrl(subtitleUrl),
                            language = subtitle.get("language")?.asString ?: "en",
                            label = subtitle.get("label")?.asString ?: "English",
                            format = subtitle.get("format")?.asString ?: "srt"
                        )
                    )
                }
                
                // Parse audio tracks if available
                val audioTracks = mutableListOf<AudioTrackData>()
                jsonObject.get("audioTracks")?.asJsonArray?.forEach { audioJson ->
                    val audio = audioJson.asJsonObject
                    audioTracks.add(
                        AudioTrackData(
                            language = audio.get("language")?.asString ?: "en",
                            label = audio.get("label")?.asString ?: "English",
                            codec = audio.get("codec")?.asString ?: "unknown",
                            channels = audio.get("channels")?.asString ?: "2.0"
                        )
                    )
                }
                
                return StreamData(
                    url = fixedUrl,
                    title = title,
                    format = format,
                    subtitles = subtitles,
                    audioTracks = audioTracks
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing JSON data", e)
        }
        
        return null
    }
    
    private fun parseStandardExtras(intent: Intent): StreamData? {
        Log.d(TAG, "Parsing standard extras")
        
        val url = intent.getStringExtra("video_url")
        val title = intent.getStringExtra("video_title") ?: "Unknown Title"
        val format = intent.getStringExtra("video_format") ?: detectFormat(url ?: "")
        
        if (url != null) {
            val fixedUrl = fixLocalhostUrl(url)
            return StreamData(
                url = fixedUrl,
                title = title,
                format = format
            )
        }
        
        return null
    }
    
    private fun detectFormat(url: String): String {
        return when {
            url.contains(".m3u8") -> "hls"
            url.contains(".mpd") -> "dash"
            url.contains(".mp4") -> "mp4"
            url.contains(".mkv") -> "mkv"
            url.contains(".avi") -> "avi"
            else -> "mp4" // Default fallback
        }
    }
    
    private fun extractTitleFromUrl(url: String): String {
        // Try to extract a meaningful title from the URL
        return try {
            val uri = Uri.parse(url)
            val pathSegments = uri.pathSegments
            val lastSegment = pathSegments.lastOrNull()
            
            if (lastSegment != null && lastSegment.contains(".")) {
                // Remove file extension
                lastSegment.substringBeforeLast(".")
                    .replace("_", " ")
                    .replace("-", " ")
                    .split(" ")
                    .joinToString(" ") { it.replaceFirstChar { char -> char.uppercase() } }
            } else {
                "Stream"
            }
        } catch (e: Exception) {
            "Stream"
        }
    }
    
    private fun fixLocalhostUrl(url: String): String {
        // For Stremio URLs, try to use the original server IP if possible
        return try {
            if (url.contains("127.0.0.1") || url.contains("localhost")) {
                // Check if this is a Stremio server URL (port 11470 is typical for Stremio)
                if (url.contains(":11470/")) {
                    // For Stremio URLs, try to find the original server IP
                    // This might be the same as our network IP, but let's be explicit
                    val networkIp = getLocalNetworkIp()
                    if (networkIp != null) {
                        val fixedUrl = url.replace("127.0.0.1", networkIp).replace("localhost", networkIp)
                        Log.d(TAG, "Fixed Stremio localhost URL: $url -> $fixedUrl")
                        Log.d(TAG, "Note: Roku will try to access Stremio server directly")
                        fixedUrl
                    } else {
                        Log.w(TAG, "Could not determine network IP, using original URL")
                        url
                    }
                } else {
                    // For other localhost URLs, use network IP
                    val networkIp = getLocalNetworkIp()
                    if (networkIp != null) {
                        val fixedUrl = url.replace("127.0.0.1", networkIp).replace("localhost", networkIp)
                        Log.d(TAG, "Fixed localhost URL: $url -> $fixedUrl")
                        fixedUrl
                    } else {
                        Log.w(TAG, "Could not determine network IP, using original URL")
                        url
                    }
                }
            } else {
                url
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error fixing localhost URL", e)
            url
        }
    }
    
    private fun getLocalNetworkIp(): String? {
        return try {
            val interfaces = java.net.NetworkInterface.getNetworkInterfaces()
            for (interface_ in interfaces) {
                if (!interface_.isLoopback && interface_.isUp) {
                    val addresses = interface_.inetAddresses
                    for (address in addresses) {
                        if (address is java.net.Inet4Address && !address.isLoopbackAddress) {
                            val ip = address.hostAddress
                            Log.d(TAG, "Found network IP: $ip")
                            return ip
                        }
                    }
                }
            }
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error getting network IP", e)
            null
        }
    }
}
