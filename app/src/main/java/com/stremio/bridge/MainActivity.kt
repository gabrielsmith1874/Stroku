package com.stremio.bridge

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.ViewModelProvider
import androidx.recyclerview.widget.LinearLayoutManager
import com.stremio.bridge.adapter.RokuDeviceAdapter
import com.stremio.bridge.databinding.ActivityMainBinding
import com.stremio.bridge.model.RokuDevice
import com.stremio.bridge.service.RokuDiscoveryService
import com.stremio.bridge.service.SendVideoResult
import com.stremio.bridge.viewmodel.MainViewModel
import com.stremio.bridge.util.StremioIntentParser
import com.stremio.bridge.model.StreamData
import android.text.InputType
import android.view.View
import android.widget.EditText
import android.widget.TextView

class MainActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMainBinding
    private lateinit var viewModel: MainViewModel
    private lateinit var deviceAdapter: RokuDeviceAdapter
    private var pendingStreamData: StreamData? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupViewModel()
        setupRecyclerView()
        setupClickListeners()
        startRokuDiscovery()
        
        // Handle Stremio intent if this activity was launched with one
        handleStremioIntent(intent)
    }
    
    private fun setupViewModel() {
        viewModel = ViewModelProvider(this)[MainViewModel::class.java]
        
        
        // Observe Roku devices
        viewModel.rokuDevices.observe(this) { devices ->
            deviceAdapter.updateDevices(devices)
            updateEmptyState(devices.isEmpty())
            
            // Show dialog if no devices found and we just finished searching
            if (devices.isEmpty() && viewModel.connectionStatus.value?.contains("No Roku devices found") == true) {
                showNoRokuDevicesDialog()
            }
            
            // Update status based on devices found
            when {
                devices.isEmpty() -> updateStatus("No devices found - Tap Refresh to search again", isSearching = false)
                devices.size == 1 -> updateStatus("Found 1 Roku device", isOnline = true)
                else -> updateStatus("Found ${devices.size} Roku devices", isOnline = true)
            }
        }
        
        // Observe connection status
        viewModel.connectionStatus.observe(this) { status ->
            if (status.contains("Ready", ignoreCase = true)) {
                updateStatus(status, isOnline = true)
            } else {
                binding.statusText.text = status
            }
        }
    }
    
    private fun setupRecyclerView() {
        deviceAdapter = RokuDeviceAdapter(
            onDeviceClick = { device ->
                onDeviceSelected(device)
            },
            onSendToDevice = { device ->
                sendPendingVideoToDevice(device)
            },
            hasPendingVideo = { pendingStreamData != null }
        )
        
        binding.devicesRecyclerView.apply {
            layoutManager = LinearLayoutManager(this@MainActivity)
            adapter = deviceAdapter
        }
    }
    
    private fun setupClickListeners() {
        binding.refreshButton.setOnClickListener {
            startRokuDiscovery()
        }
        
        binding.manualIpButton.setOnClickListener {
            showManualIpDialog()
        }
        
        binding.testButton.setOnClickListener {
            testStremioIntegration()
        }
        
    }
    
    private fun startRokuDiscovery() {
        updateStatus("Discovering Roku devices...", isSearching = true)
        viewModel.startRokuDiscovery()
    }
    
    private fun showManualIpDialog() {
        val input = EditText(this).apply {
            inputType = InputType.TYPE_CLASS_PHONE
            hint = "192.168.1.100"
            setText("192.168.1.")
        }
        
        AlertDialog.Builder(this)
            .setTitle("Enter Roku IP Address")
            .setMessage("Enter the IP address of your Roku device:")
            .setView(input)
            .setPositiveButton("Connect") { _, _ ->
                val ipAddress = input.text.toString().trim()
                if (isValidIpAddress(ipAddress)) {
                    connectToManualIp(ipAddress)
                } else {
                    Toast.makeText(this, "Please enter a valid IP address", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }
    
    private fun isValidIpAddress(ip: String): Boolean {
        val parts = ip.split(".")
        if (parts.size != 4) return false
        
        return parts.all { part ->
            try {
                val num = part.toInt()
                num in 0..255
            } catch (e: NumberFormatException) {
                false
            }
        }
    }
    
    private fun connectToManualIp(ipAddress: String) {
        updateStatus("Connecting to $ipAddress...", isSearching = true)
        
        
        // Create a manual Roku device
        val manualDevice = RokuDevice(
            name = "Manual Roku ($ipAddress)",
            ipAddress = ipAddress
        )
        
        // Add it to the device list via ViewModel
        viewModel.addManualDevice(manualDevice)
        
        // Save it as the last selected device
        saveLastSelectedDevice(manualDevice)
        
        updateStatus("Connected to $ipAddress", isOnline = true)
        Toast.makeText(this, "Connected to Roku at $ipAddress", Toast.LENGTH_SHORT).show()
    }
    
    private fun onDeviceSelected(device: RokuDevice) {
        viewModel.selectRokuDevice(device)
        saveLastSelectedDevice(device)
        Toast.makeText(this, "Selected: ${device.name}", Toast.LENGTH_SHORT).show()
    }
    
    private fun saveLastSelectedDevice(device: RokuDevice) {
        try {
            val prefs = getSharedPreferences("stremio_roku_bridge", MODE_PRIVATE)
            val deviceJson = com.google.gson.Gson().toJson(device)
            prefs.edit().putString("last_selected_device", deviceJson).apply()
        } catch (e: Exception) {
            Log.e("MainActivity", "Error saving last selected device", e)
        }
    }
    
    private fun testStremioIntegration() {
        // Test with a sample video URL
        val testUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        val testTitle = "Big Buck Bunny (Test)"
        val testFormat = "mp4"
        
        // Check if we have a selected device, if not, try to use the first available device
        val selectedDevice = viewModel.selectedDevice.value
        if (selectedDevice == null) {
            val availableDevices = viewModel.rokuDevices.value
            if (availableDevices.isNullOrEmpty()) {
                Toast.makeText(this, "No Roku devices found. Please add a device first.", Toast.LENGTH_SHORT).show()
                return
            }
            // Auto-select the first device for testing
            viewModel.selectRokuDevice(availableDevices.first())
        }
        
        // Show a more informative message
        Toast.makeText(this, "Testing connection to ${selectedDevice?.name ?: "Roku device"}...", Toast.LENGTH_SHORT).show()
        
        
        viewModel.sendVideoToRoku(testUrl, testTitle, testFormat) { result ->
            runOnUiThread {
                when (result) {
                    is SendVideoResult.Success -> {
                        Toast.makeText(this, "Test video sent to Roku!", Toast.LENGTH_SHORT).show()
                    }
                    is SendVideoResult.AppNotFound -> {
                        showRokuAppMissingDialog(selectedDevice?.name ?: "Roku device")
                    }
                    is SendVideoResult.Failure -> {
                        Toast.makeText(this, "Failed to send test video: ${result.reason}", Toast.LENGTH_LONG).show()
                    }
                }
            }
        }
    }
    
    private fun updateEmptyState(isEmpty: Boolean) {
        binding.emptyStateLayout.visibility = if (isEmpty) {
            binding.devicesRecyclerView.visibility = android.view.View.GONE
            android.view.View.VISIBLE
        } else {
            binding.devicesRecyclerView.visibility = android.view.View.VISIBLE
            android.view.View.GONE
        }
    }
    
    
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        // Handle Stremio external player intents
        intent?.let { handleStremioIntent(it) }
    }
    
    private fun handleStremioIntent(intent: Intent) {
        try {
            
            // Parse the Stremio intent using the same parser as StremioPlayerActivity
            val streamData = StremioIntentParser.parseIntent(intent)
            
            if (streamData != null) {
                // Save the stream data instead of immediately sending
                pendingStreamData = streamData
                
                // Show success message and update UI
                Toast.makeText(this, "Video ready! Select a Roku device to send: ${streamData.title}", Toast.LENGTH_LONG).show()
                
                // Refresh the device list to show send buttons
                deviceAdapter.notifyDataSetChanged()
                
                // Update status
                updateStatus("Video ready: ${streamData.title}", isOnline = true)
                
            } else {
                Toast.makeText(this, "Failed to parse Stremio data", Toast.LENGTH_SHORT).show()
            }
            
        } catch (e: Exception) {
            Log.e("MainActivity", "Error handling Stremio intent", e)
            Toast.makeText(this, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun sendPendingVideoToDevice(device: RokuDevice) {
        val streamData = pendingStreamData
        if (streamData == null) {
            Toast.makeText(this, "No video ready to send", Toast.LENGTH_SHORT).show()
            return
        }
        
        // Temporarily select this device for sending
        viewModel.selectRokuDevice(device)
        
        viewModel.sendVideoToRoku(streamData.url, streamData.title, streamData.format) { result ->
            runOnUiThread {
                when (result) {
                    is SendVideoResult.Success -> {
                        Toast.makeText(this, "Stream sent to ${device.name}: ${streamData.title}", Toast.LENGTH_LONG).show()
                        
                        // Clear the pending video after successful send
                        pendingStreamData = null
                        updateStatus("Video sent successfully!", isOnline = true)
                        deviceAdapter.notifyDataSetChanged()
                    }
                    is SendVideoResult.AppNotFound -> {
                        showRokuAppMissingDialog(device.name)
                    }
                    is SendVideoResult.Failure -> {
                        Toast.makeText(this, "Failed to send stream to ${device.name}. Please try again.", Toast.LENGTH_LONG).show()
                    }
                }
            }
        }
    }
    
    private fun sendStreamToRoku(streamData: StreamData) {
        val selectedDevice = viewModel.selectedDevice.value
        if (selectedDevice == null) {
            Toast.makeText(this, "No Roku device selected", Toast.LENGTH_SHORT).show()
            return
        }
        
        viewModel.sendVideoToRoku(streamData.url, streamData.title, streamData.format) { result ->
            runOnUiThread {
                when (result) {
                    is SendVideoResult.Success -> {
                        Toast.makeText(this, "Stream sent to Roku: ${streamData.title}", Toast.LENGTH_LONG).show()
                    }
                    is SendVideoResult.AppNotFound -> {
                        showRokuAppMissingDialog(selectedDevice.name)
                    }
                    is SendVideoResult.Failure -> {
                        Toast.makeText(this, "Failed to send stream to Roku. Please try again.", Toast.LENGTH_LONG).show()
                    }
                }
            }
        }
    }
    
    private fun updateStatus(message: String, isOnline: Boolean = false, isSearching: Boolean = false) {
        binding.statusText.text = message
        
        val statusIndicator = findViewById<View>(R.id.statusIndicator)
        when {
            isSearching -> {
                statusIndicator?.setBackgroundResource(R.drawable.status_indicator_offline)
                // You could add a rotation animation here if desired
            }
            isOnline -> {
                statusIndicator?.setBackgroundResource(R.drawable.status_indicator_online)
            }
            else -> {
                statusIndicator?.setBackgroundResource(R.drawable.status_indicator_offline)
            }
        }
    }
    
    /**
     * Show dialog when no Roku devices are found
     */
    private fun showNoRokuDevicesDialog() {
        val dialog = androidx.appcompat.app.AlertDialog.Builder(this)
            .setTitle("No Roku Devices Found")
            .setMessage("No Roku devices were detected on your network. Please check:\n\n" +
                    "• Both devices are on the same Wi-Fi network\n" +
                    "• Roku 'Control by mobile apps' is enabled\n" +
                    "• Router doesn't have client isolation enabled\n\n" +
                    "Would you like to see setup instructions?")
            .setPositiveButton("Setup Guide") { _, _ ->
                showRokuSetupGuide()
            }
            .setNegativeButton("Manual IP") { _, _ ->
                showManualIpDialog()
            }
            .setNeutralButton("Retry") { _, _ ->
                // Retry discovery
                startRokuDiscovery()
            }
            .create()
        
        dialog.show()
    }
    
    /**
     * Show Roku setup guide
     */
    private fun showRokuSetupGuide() {
        val dialog = androidx.appcompat.app.AlertDialog.Builder(this)
            .setTitle("Roku Setup Guide")
            .setMessage("To enable your Roku device for control:\n\n" +
                    "1. Press HOME on Roku remote\n" +
                    "2. Go to Settings > System\n" +
                    "3. Select 'Advanced system settings'\n" +
                    "4. Choose 'Control by mobile apps'\n" +
                    "5. Set Network access to 'Default'\n\n" +
                    "Make sure both devices are on the same Wi-Fi network.")
            .setPositiveButton("Got it", null)
            .create()
        
        dialog.show()
    }

    /**
     * Show dialog when Roku app is not installed
     */
    private fun showRokuAppMissingDialog(deviceName: String) {
        val dialog = androidx.appcompat.app.AlertDialog.Builder(this)
            .setTitle("Roku App Not Found")
            .setMessage("The 'Stroku Receiver' app is not installed on your Roku device '$deviceName'. Please install it from the Roku Channel Store to stream content.")
            .setPositiveButton("Open Roku Store") { _, _ ->
                // Open the Roku Channel Store
                openRokuChannelStore()
            }
            .setNegativeButton("Cancel", null)
            .setNeutralButton("Retry") { _, _ ->
                // Retry sending the video
                pendingStreamData?.let { _ ->
                    sendPendingVideoToDevice(viewModel.selectedDevice.value!!)
                }
            }
            .create()
        
        dialog.show()
    }
    
    /**
     * Open Roku Channel Store to install the app
     */
    private fun openRokuChannelStore() {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("https://channelstore.roku.com/details/821678/stroku-receiver")
        try {
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback: show a toast with the URL
            Toast.makeText(this, "Please visit: https://channelstore.roku.com/details/821678/stroku-receiver", Toast.LENGTH_LONG).show()
        }
    }
}
