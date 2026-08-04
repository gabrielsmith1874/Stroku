package com.stremio.bridge.service

import android.app.Service
import android.content.Intent
import android.os.IBinder
import com.stremio.bridge.model.RokuDevice
import kotlinx.coroutines.*
import java.net.*
import java.util.concurrent.ConcurrentHashMap

class RokuDiscoveryService : Service() {
    
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val discoveredDevices = ConcurrentHashMap<String, RokuDevice>()
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_DISCOVER_ROKU -> startDiscovery()
            ACTION_STOP_DISCOVERY -> stopDiscovery()
        }
        return START_STICKY
    }
    
    private fun startDiscovery() {
        serviceScope.launch {
            try {
                // Send SSDP discovery request
                val socket = DatagramSocket()
                socket.broadcast = true
                
                val discoveryMessage = """
                    M-SEARCH * HTTP/1.1
                    HOST: 239.255.255.250:1900
                    MAN: "ssdp:discover"
                    ST: roku:ecp
                    MX: 3
                    
                """.trimIndent()
                
                val data = discoveryMessage.toByteArray()
                val address = InetAddress.getByName("239.255.255.250")
                val packet = DatagramPacket(data, data.size, address, 1900)
                
                socket.send(packet)
                
                // Listen for responses
                val buffer = ByteArray(1024)
                val responsePacket = DatagramPacket(buffer, buffer.size)
                
                socket.soTimeout = 3000 // 3 second timeout
                
                try {
                    while (true) {
                        socket.receive(responsePacket)
                        val response = String(responsePacket.data, 0, responsePacket.length)
                        parseRokuResponse(response, responsePacket.address.hostAddress)
                    }
                } catch (e: SocketTimeoutException) {
                    // Discovery timeout - this is expected
                }
                
                socket.close()
                
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    private fun parseRokuResponse(response: String, ipAddress: String?) {
        if (ipAddress == null) return
        
        val lines = response.split("\n")
        var deviceName = "Roku Device"
        
        for (line in lines) {
            if (line.startsWith("USN:", ignoreCase = true)) {
                // Extract device name from USN header
                val usn = line.substringAfter("USN: ").trim()
                deviceName = usn.substringBefore("::").substringAfter("uuid:")
            }
        }
        
        val device = RokuDevice(
            name = deviceName,
            ipAddress = ipAddress
        )
        
        discoveredDevices[ipAddress] = device
        
        // Broadcast device found
        val intent = Intent(ACTION_ROKU_DEVICE_FOUND)
        intent.putExtra(EXTRA_DEVICE, device)
        sendBroadcast(intent)
    }
    
    private fun stopDiscovery() {
        serviceScope.cancel()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
    }
    
    companion object {
        const val ACTION_DISCOVER_ROKU = "com.stremio.bridge.DISCOVER_ROKU"
        const val ACTION_STOP_DISCOVERY = "com.stremio.bridge.STOP_DISCOVERY"
        const val ACTION_ROKU_DEVICE_FOUND = "com.stremio.bridge.ROKU_DEVICE_FOUND"
        const val EXTRA_DEVICE = "extra_device"
    }
}
