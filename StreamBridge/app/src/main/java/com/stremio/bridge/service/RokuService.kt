package com.stremio.bridge.service

import android.util.Log
import com.stremio.bridge.model.RokuDevice
import com.stremio.bridge.util.LogCallback
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.MediaType.Companion.toMediaType
import java.net.InetAddress
import java.net.NetworkInterface
import java.util.concurrent.TimeUnit

/**
 * Result of launching the Stremio Bridge app
 */
sealed class LaunchResult {
    object Success : LaunchResult()
    data class Failure(val reason: String) : LaunchResult()
}

/**
 * Result of sending video to Roku
 */
sealed class SendVideoResult {
    object Success : SendVideoResult()
    object AppNotFound : SendVideoResult()
    data class Failure(val reason: String) : SendVideoResult()
}

/**
 * Service for communicating with Roku devices via ECP (External Control Protocol)
 */
class RokuService {
    
    val httpClient = OkHttpClient.Builder()
        .connectTimeout(5, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .writeTimeout(10, TimeUnit.SECONDS)
        .build()
    
    private var logCallback: LogCallback? = null
    
    fun setLogCallback(callback: LogCallback?) {
        this.logCallback = callback
    }
    
    private fun log(message: String) {
        Log.d(TAG, message)
        logCallback?.log(message)
    }
    
    companion object {
        private const val TAG = "RokuService"
        private const val ROKU_ECP_PORT = 8060
        private const val ROKU_APP_NAME = "Stroku Receiver" // App name to search for
        private const val ROKU_MEDIA_PLAYER_ID = "11" // Built-in Roku Media Player
    }
    
    // Cache the detected app ID to avoid repeated lookups
    private var cachedAppId: String? = null
    
    /**
     * Clear the cached app ID (useful when switching between dev and published versions)
     */
    fun clearAppIdCache() {
        cachedAppId = null
        log("🔄 Cleared app ID cache")
    }
    
    /**
     * Detect the Stremio Bridge app ID dynamically
     * This works for both development ("dev") and published app IDs
     */
    private suspend fun detectStremioBridgeAppId(rokuIp: String): String? = withContext(Dispatchers.IO) {
        // Return cached ID if available
        cachedAppId?.let { return@withContext it }
        
        try {
            log("🔍 Detecting Stremio Bridge app ID...")
            
            val appsRequest = Request.Builder()
                .url("http://$rokuIp:$ROKU_ECP_PORT/query/apps")
                .get()
                .build()
            
            val appsResponse = httpClient.newCall(appsRequest).execute()
            if (!appsResponse.isSuccessful) {
                log("❌ Failed to get apps list: ${appsResponse.code}")
                return@withContext null
            }
            
            val appsBody = appsResponse.body?.string()
            log("Available apps: $appsBody")
            
            // Parse the apps list to find our app
            if (appsBody != null) {
                log("Parsing apps list...")
                
                // Check if response is XML format (which it is based on the logs)
                if (appsBody.contains("<apps>")) {
                    log("Detected XML format, parsing XML...")
                    
                    // Parse XML format: <app id="821678" type="appl" version="1.0.3">Stroku Receiver</app>
                    val appXmlRegex = "<app\\s+id=\"([^\"]+)\"[^>]*>([^<]+)</app>".toRegex()
                    val matches = appXmlRegex.findAll(appsBody)
                    
                    for (match in matches) {
                        val appId = match.groupValues[1]
                        val appName = match.groupValues[2].trim()
                        
                        log("Found app: ID=$appId, Name='$appName'")
                        
                        // Check if this is our app (case-insensitive, also check for variations)
                        if (appName.equals(ROKU_APP_NAME, ignoreCase = true) ||
                            appName.equals("Stremio Bridge", ignoreCase = true) ||
                            appName.contains("Stremio", ignoreCase = true) ||
                            appName.contains("Stroku", ignoreCase = true)) {
                            log("✅ Found Stremio Bridge app with ID: $appId (Name: '$appName')")
                            cachedAppId = appId
                            return@withContext appId
                        }
                    }
                    
                    // Fallback: check for "dev" ID only if production app not found
                    if (appsBody.contains("id=\"dev\"")) {
                        log("⚠️ Found development app with ID: dev (production app not found)")
                        cachedAppId = "dev"
                        return@withContext "dev"
                    }
                } else {
                    // Fallback to JSON parsing if needed
                    log("Detected JSON format, parsing JSON...")
                    
                    // Look for the app by name "Stroku Receiver"
                    val appIdRegex = "\"id\":\"([^\"]+)\".*?\"name\":\"([^\"]+)\"".toRegex()
                    val matches = appIdRegex.findAll(appsBody)
                    
                    for (match in matches) {
                        val appId = match.groupValues[1]
                        val appName = match.groupValues[2]
                        
                        log("Found app: ID=$appId, Name='$appName'")
                        
                        // Check if this is our app (case-insensitive, also check for variations)
                        if (appName.equals(ROKU_APP_NAME, ignoreCase = true) ||
                            appName.equals("Stremio Bridge", ignoreCase = true) ||
                            appName.contains("Stremio", ignoreCase = true) ||
                            appName.contains("Stroku", ignoreCase = true)) {
                            log("✅ Found Stremio Bridge app with ID: $appId (Name: '$appName')")
                            cachedAppId = appId
                            return@withContext appId
                        }
                    }
                    
                    // Fallback: check for "dev" ID only if production app not found
                    if (appsBody.contains("\"id\":\"dev\"")) {
                        log("⚠️ Found development app with ID: dev (production app not found)")
                        cachedAppId = "dev"
                        return@withContext "dev"
                    }
                }
            }
            
            log("❌ Stremio Bridge app not found in available apps")
            return@withContext null
            
        } catch (e: Exception) {
            log("❌ Error detecting app ID: ${e.message}")
            return@withContext null
        }
    }
    
    /**
     * Discover Roku devices on the local network
     */
    suspend fun discoverRokuDevices(): List<RokuDevice> = withContext(Dispatchers.IO) {
        val devices = mutableListOf<RokuDevice>()
        val localNetwork = getLocalNetworkPrefix()
        
        Log.d(TAG, "Discovering Roku devices on network: $localNetwork")
        
        // Try SSDP discovery first (more reliable)
        try {
            val ssdpDevices = discoverViaSSDP()
            devices.addAll(ssdpDevices)
            Log.d(TAG, "SSDP discovery found ${ssdpDevices.size} devices")
        } catch (e: Exception) {
            Log.e(TAG, "SSDP discovery failed", e)
        }
        
        // If no devices found via SSDP, try IP scanning
        if (devices.isEmpty()) {
            Log.d(TAG, "No devices found via SSDP, trying IP scan")
            
            // Scan common IP ranges
            val ipRanges = listOf(
                "$localNetwork.1-254", // Most common home networks
                "192.168.1.1-254",     // Common router default
                "192.168.0.1-254"      // Common router default
            )
        
        for (ipRange in ipRanges) {
            val startIp = ipRange.substringBefore("-")
            val endIp = ipRange.substringAfter("-")
            
            val startParts = startIp.split(".")
            val endParts = endIp.split(".")
            
            if (startParts.size == 4 && endParts.size == 4) {
                val baseIp = startParts.take(3).joinToString(".")
                val startLast = startParts[3].toIntOrNull() ?: 1
                val endLast = endParts[3].toIntOrNull() ?: 254
                
                for (i in startLast..endLast) {
                    val ip = "$baseIp.$i"
                    val device = checkRokuDevice(ip)
                    if (device != null) {
                        devices.add(device)
                        Log.d(TAG, "Found Roku device: ${device.name} at $ip")
                    }
                }
            }
        }
        
        }
        
        Log.d(TAG, "Discovery complete. Found ${devices.size} Roku devices")
        devices
    }
    
    /**
     * Discover Roku devices using SSDP (Simple Service Discovery Protocol)
     */
    private suspend fun discoverViaSSDP(): List<RokuDevice> = withContext(Dispatchers.IO) {
        val devices = mutableListOf<RokuDevice>()
        
        try {
            val socket = java.net.DatagramSocket()
            socket.broadcast = true
            socket.soTimeout = 3000
            
            // Send SSDP discovery request
            val discoveryMessage = """
                M-SEARCH * HTTP/1.1
                HOST: 239.255.255.250:1900
                MAN: "ssdp:discover"
                ST: roku:ecp
                MX: 3
                
            """.trimIndent()
            
            val data = discoveryMessage.toByteArray()
            val address = java.net.InetAddress.getByName("239.255.255.250")
            val packet = java.net.DatagramPacket(data, data.size, address, 1900)
            
            socket.send(packet)
            
            // Listen for responses
            val buffer = ByteArray(1024)
            val responsePacket = java.net.DatagramPacket(buffer, buffer.size)
            
            try {
                while (true) {
                    socket.receive(responsePacket)
                    val response = String(responsePacket.data, 0, responsePacket.length)
                    val device = parseSSDPResponse(response, responsePacket.address.hostAddress)
                    if (device != null) {
                        devices.add(device)
                        Log.d(TAG, "Found Roku via SSDP: ${device.name} at ${device.ipAddress}")
                    }
                }
            } catch (e: java.net.SocketTimeoutException) {
                // Discovery timeout - this is expected
            }
            
            socket.close()
        } catch (e: Exception) {
            Log.e(TAG, "SSDP discovery error", e)
        }
        
        devices
    }
    
    /**
     * Parse SSDP response to extract Roku device info
     */
    private fun parseSSDPResponse(response: String, ipAddress: String?): RokuDevice? {
        if (ipAddress == null) return null
        
        val lines = response.split("\n")
        var deviceName = "Roku Device"
        
        for (line in lines) {
            if (line.startsWith("USN:", ignoreCase = true)) {
                // Extract device name from USN header
                val usn = line.substringAfter("USN: ").trim()
                deviceName = usn.substringBefore("::").substringAfter("uuid:")
            }
        }
        
        return RokuDevice(
            name = deviceName,
            ipAddress = ipAddress
        )
    }
    
    /**
     * Check if a specific IP address hosts a Roku device
     */
    private suspend fun checkRokuDevice(ip: String): RokuDevice? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("http://$ip:$ROKU_ECP_PORT/query/device-info")
                .get()
                .build()
            
            val response = httpClient.newCall(request).execute()
            
            if (response.isSuccessful) {
                val responseBody = response.body?.string()
                Log.d(TAG, "Roku response from $ip: $responseBody")
                
                // Parse device info from XML response
                val deviceInfo = parseDeviceInfo(responseBody ?: "")
                if (deviceInfo.isNotEmpty()) {
                    return@withContext RokuDevice(
                        name = deviceInfo["friendly-device-name"] ?: "Roku Device",
                        ipAddress = ip,
                        port = ROKU_ECP_PORT,
                        isOnline = true
                    )
                }
            }
        } catch (e: Exception) {
            // Not a Roku device or not reachable
        }
        
        null
    }
    
    /**
     * Send video stream to Roku device
     */
    suspend fun sendVideoToRoku(
        device: RokuDevice,
        videoUrl: String,
        title: String,
        format: String
    ): SendVideoResult = withContext(Dispatchers.IO) {
        try {
            log("Sending video to Roku: $title")
            log("Video URL: $videoUrl")
            log("Format: $format")
            
            // Try input method first (may work without "Control by mobile apps")
            log("🔄 Trying /input method first...")
            val inputResult = sendVideoViaInput(device.ipAddress, videoUrl, title, format)
            if (inputResult is SendVideoResult.Success) {
                log("✅ Successfully sent video via /input method")
                return@withContext inputResult
            }
            
            log("⚠️ /input method failed, trying /launch method...")
            
            // Fallback to launch method
            val launchResult = launchStremioBridgeApp(device.ipAddress)
            if (launchResult is LaunchResult.Failure) {
                log("❌ Failed to launch Stremio Bridge app: ${launchResult.reason}")
                
                // Check if it's because the app is not installed
                if (launchResult.reason == "APP_NOT_FOUND") {
                    return@withContext SendVideoResult.AppNotFound
                }
                
                // Try fallback method for other failures
                val fallbackSuccess = sendVideoToRokuMediaPlayer(device.ipAddress, videoUrl, title, format)
                return@withContext if (fallbackSuccess) SendVideoResult.Success else SendVideoResult.Failure("All methods failed")
            }
            
            // Wait a moment for the app to launch
            kotlinx.coroutines.delay(2000)
            
            // Send video data via launch parameters
            val success = sendVideoData(device.ipAddress, videoUrl, title, format)
            
            if (success) {
                log("✅ Successfully sent video to Roku via /launch")
                return@withContext SendVideoResult.Success
            } else {
                log("❌ Failed to send video data to Roku")
                return@withContext SendVideoResult.Failure("Failed to send video data")
            }
        } catch (e: Exception) {
            log("❌ Error sending video to Roku: ${e.message}")
            return@withContext SendVideoResult.Failure("Exception: ${e.message}")
        }
    }
    
    /**
     * Send video via /input endpoint (may work without "Control by mobile apps")
     */
    private suspend fun sendVideoViaInput(
        rokuIp: String,
        videoUrl: String,
        title: String,
        format: String
    ): SendVideoResult = withContext(Dispatchers.IO) {
        try {
            log("🎯 Attempting to send video via /input endpoint")
            
            // For /input method, try to use the published app ID first, fallback to dev
            // This avoids the 403 error when "Control by mobile apps" is disabled
            // Production app ID (821678) is prioritized over development
            val appId = tryDetectAppIdWithoutQuery(rokuIp) ?: "dev"
            log("Using app ID for /input method: $appId")
            
            // Launch the app first
            val launchUrl = "http://$rokuIp:$ROKU_ECP_PORT/launch/$appId"
            val launchRequest = Request.Builder()
                .url(launchUrl)
                .post("".toRequestBody("application/x-www-form-urlencoded".toMediaType()))
                .build()
            
            val launchResponse = httpClient.newCall(launchRequest).execute()
            if (!launchResponse.isSuccessful) {
                log("❌ Failed to launch app for /input method: ${launchResponse.code}")
                return@withContext SendVideoResult.Failure("Failed to launch app")
            }
            
            log("✅ App launched successfully, waiting for startup...")
            kotlinx.coroutines.delay(2000) // Wait for app to fully start
            
            // URL encode the parameters
            val encodedUrl = java.net.URLEncoder.encode(videoUrl, "UTF-8")
            val encodedTitle = java.net.URLEncoder.encode(title, "UTF-8")
            val encodedFormat = java.net.URLEncoder.encode(format, "UTF-8")
            
            // Use /input endpoint with contentid as the video URL
            val inputUrl = "http://$rokuIp:$ROKU_ECP_PORT/input?contentid=$encodedUrl&mediatype=video&title=$encodedTitle&format=$encodedFormat"
            
            log("Input URL: $inputUrl")
            
            val request = Request.Builder()
                .url(inputUrl)
                .post("".toRequestBody("application/x-www-form-urlencoded".toMediaType()))
                .build()
            
            val response = httpClient.newCall(request).execute()
            val success = response.isSuccessful
            
            log("Input response: ${response.code} - $success")
            
            if (success) {
                log("✅ Video sent successfully via /input endpoint")
                return@withContext SendVideoResult.Success
            } else {
                val errorBody = response.body?.string()
                log("❌ /input failed: ${response.code} - $errorBody")
                return@withContext SendVideoResult.Failure("Input method failed: ${response.code}")
            }
        } catch (e: Exception) {
            log("❌ Error with /input method: ${e.message}")
            return@withContext SendVideoResult.Failure("Input exception: ${e.message}")
        }
    }
    
    /**
     * Try to detect app ID without using /query/apps (to avoid 403 errors)
     */
    private suspend fun tryDetectAppIdWithoutQuery(rokuIp: String): String? = withContext(Dispatchers.IO) {
        try {
            // First try the published app ID (821678) - prioritized over dev
            val publishedAppId = "821678"
            val testUrl = "http://$rokuIp:$ROKU_ECP_PORT/launch/$publishedAppId"
            val testRequest = Request.Builder()
                .url(testUrl)
                .post("".toRequestBody("application/x-www-form-urlencoded".toMediaType()))
                .build()
            
            val testResponse = httpClient.newCall(testRequest).execute()
            if (testResponse.isSuccessful) {
                log("✅ Published app ID $publishedAppId works")
                return@withContext publishedAppId
            } else {
                log("❌ Published app ID $publishedAppId failed: ${testResponse.code}")
            }
            
            // If published ID fails, try dev ID (fallback only)
            val devAppId = "dev"
            val devTestUrl = "http://$rokuIp:$ROKU_ECP_PORT/launch/$devAppId"
            val devTestRequest = Request.Builder()
                .url(devTestUrl)
                .post("".toRequestBody("application/x-www-form-urlencoded".toMediaType()))
                .build()
            
            val devTestResponse = httpClient.newCall(devTestRequest).execute()
            if (devTestResponse.isSuccessful) {
                log("✅ Dev app ID $devAppId works (fallback)")
                return@withContext devAppId
            } else {
                log("❌ Dev app ID $devAppId failed: ${devTestResponse.code}")
            }
            
            log("❌ No working app ID found")
            return@withContext null
        } catch (e: Exception) {
            log("❌ Error testing app IDs: ${e.message}")
            return@withContext null
        }
    }
    
    /**
     * Launch the Stremio Bridge app on Roku
     */
    private suspend fun launchStremioBridgeApp(rokuIp: String): LaunchResult = withContext(Dispatchers.IO) {
        try {
            // First detect the app ID dynamically
            val appId = detectStremioBridgeAppId(rokuIp)
            if (appId == null) {
                log("❌ Could not detect Stremio Bridge app ID - app not found")
                return@withContext LaunchResult.Failure("APP_NOT_FOUND")
            }
            
            log("Using app ID: $appId")
            
            // Check if the app is already running
            try {
                val activeAppRequest = Request.Builder()
                    .url("http://$rokuIp:$ROKU_ECP_PORT/query/active-app")
                    .get()
                    .build()
                
                val activeAppResponse = httpClient.newCall(activeAppRequest).execute()
                if (activeAppResponse.isSuccessful) {
                    val responseBody = activeAppResponse.body?.string()
                    log("Active app response: $responseBody")
                    
                    // Check if our app is already active
                    if (responseBody?.contains("\"id\":\"$appId\"") == true) {
                        log("✅ Stremio Bridge app is already active")
                        return@withContext LaunchResult.Success
                    }
                }
            } catch (e: Exception) {
                log("⚠️ Could not check active app status: ${e.message}")
            }
            
            // Launch the app
            log("🚀 Launching Stremio Bridge app with ID: $appId")
            val request = Request.Builder()
                .url("http://$rokuIp:$ROKU_ECP_PORT/launch/$appId")
                .post("".toRequestBody("application/x-www-form-urlencoded".toMediaType()))
                .build()
            
            val response = httpClient.newCall(request).execute()
            val success = response.isSuccessful
            
            log("Launch app response: ${response.code} - $success")
            if (!success) {
                log("❌ Launch app response body: ${response.body?.string()}")
                return@withContext LaunchResult.Failure("LAUNCH_FAILED")
            }
            
            return@withContext LaunchResult.Success
        } catch (e: Exception) {
            Log.e(TAG, "Error launching Stremio Bridge app", e)
            return@withContext LaunchResult.Failure("EXCEPTION: ${e.message}")
        }
    }
    
    /**
     * Send video data to Roku using launch parameters
     */
    private suspend fun sendVideoData(
        rokuIp: String,
        videoUrl: String,
        title: String,
        format: String
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            // Get the app ID dynamically
            val appId = detectStremioBridgeAppId(rokuIp)
            if (appId == null) {
                log("❌ Could not detect Stremio Bridge app ID for sending video")
                return@withContext false
            }
            
            // URL encode the parameters (matching PowerShell script approach)
            val encodedUrl = java.net.URLEncoder.encode(videoUrl, "UTF-8")
            val encodedTitle = java.net.URLEncoder.encode(title, "UTF-8")
            val encodedFormat = java.net.URLEncoder.encode(format, "UTF-8")
            
            // Use the detected app ID
            val launchUrl = "http://$rokuIp:$ROKU_ECP_PORT/launch/$appId?contentId=test_video&url=$encodedUrl&title=$encodedTitle&format=$encodedFormat"
            
            log("📤 Sending video data to Roku...")
            log("App ID: $appId")
            log("Video URL: $videoUrl")
            log("Title: $title")
            log("Format: $format")
            log("Launch URL: $launchUrl")
            
            // Check if this is a local server URL
            if (videoUrl.contains("127.0.0.1") || videoUrl.contains("localhost") || videoUrl.contains(":11470")) {
                log("⚠️ WARNING: This is a local server URL")
                log("⚠️ Roku may not be able to access this URL directly")
                log("⚠️ Make sure the server is accessible from the Roku's network")
            }
            
            // Check for MKV format
            if (videoUrl.contains(".mkv") || format.lowercase() == "mkv") {
                log("⚠️ WARNING: MKV format detected")
                log("⚠️ Roku may not support MKV format directly")
                log("⚠️ Consider converting to MP4 or using a different format")
            }
            
            val request = Request.Builder()
                .url(launchUrl)
                .post("".toRequestBody("application/x-www-form-urlencoded".toMediaType()))
                .build()
            
            val response = httpClient.newCall(request).execute()
            val success = response.isSuccessful
            
            log("Send video data response: ${response.code} - $success")
            if (!success) {
                log("❌ Response body: ${response.body?.string()}")
            }
            success
        } catch (e: Exception) {
            Log.e(TAG, "Error sending video data", e)
            false
        }
    }
    
    /**
     * Fallback method: Send video to built-in Roku Media Player
     */
    private suspend fun sendVideoToRokuMediaPlayer(
        rokuIp: String,
        videoUrl: String,
        @Suppress("UNUSED_PARAMETER") title: String,
        @Suppress("UNUSED_PARAMETER") format: String
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Trying fallback: Roku Media Player")
            
            // Launch the built-in Roku Media Player
            val launchRequest = Request.Builder()
                .url("http://$rokuIp:$ROKU_ECP_PORT/launch/$ROKU_MEDIA_PLAYER_ID")
                .post("".toRequestBody("application/x-www-form-urlencoded".toMediaType()))
                .build()
            
            val launchResponse = httpClient.newCall(launchRequest).execute()
            if (!launchResponse.isSuccessful) {
                Log.e(TAG, "Failed to launch Roku Media Player: ${launchResponse.code}")
                return@withContext false
            }
            
            Log.d(TAG, "Roku Media Player launched successfully")
            
            // Wait for the app to launch
            kotlinx.coroutines.delay(3000)
            
            // Try to send the video URL directly to the media player
            // This is a simplified approach - the media player might not accept direct URLs
            val mediaRequest = Request.Builder()
                .url("http://$rokuIp:$ROKU_ECP_PORT/input?$videoUrl")
                .post("".toRequestBody("application/x-www-form-urlencoded".toMediaType()))
                .build()
            
            val mediaResponse = httpClient.newCall(mediaRequest).execute()
            val success = mediaResponse.isSuccessful
            
            Log.d(TAG, "Media player response: ${mediaResponse.code} - $success")
            
            if (success) {
                Log.d(TAG, "Video sent to Roku Media Player successfully")
            } else {
                Log.e(TAG, "Failed to send video to Roku Media Player")
            }
            
            success
        } catch (e: Exception) {
            Log.e(TAG, "Error with Roku Media Player fallback", e)
            false
        }
    }
    
    /**
     * Get the local network prefix (e.g., "192.168.1")
     */
    private fun getLocalNetworkPrefix(): String {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            for (interface_ in interfaces) {
                if (!interface_.isLoopback && interface_.isUp) {
                    val addresses = interface_.inetAddresses
                    for (address in addresses) {
                        if (address is InetAddress && !address.isLoopbackAddress) {
                            val hostAddress = address.hostAddress
                            if (hostAddress != null && hostAddress.contains(".")) {
                                val parts = hostAddress.split(".")
                                if (parts.size == 4) {
                                    return parts.take(3).joinToString(".")
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting local network", e)
        }
        
        return "192.168.1" // Fallback
    }
    
    /**
     * Parse device info from Roku's XML response
     */
    private fun parseDeviceInfo(xmlResponse: String): Map<String, String> {
        val deviceInfo = mutableMapOf<String, String>()
        
        try {
            // Simple XML parsing for device info
            val lines = xmlResponse.split("\n")
            for (line in lines) {
                val trimmed = line.trim()
                if (trimmed.startsWith("<") && trimmed.contains(">")) {
                    val tagName = trimmed.substringAfter("<").substringBefore(">")
                    val content = trimmed.substringAfter(">").substringBefore("</")
                    
                    if (content.isNotEmpty()) {
                        deviceInfo[tagName] = content
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing device info", e)
        }
        
        return deviceInfo
    }
}

