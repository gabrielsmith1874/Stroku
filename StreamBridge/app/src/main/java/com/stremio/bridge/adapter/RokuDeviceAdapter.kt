package com.stremio.bridge.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.stremio.bridge.databinding.ItemRokuDeviceBinding
import com.stremio.bridge.model.RokuDevice

class RokuDeviceAdapter(
    private val onDeviceClick: (RokuDevice) -> Unit,
    private val onSendToDevice: (RokuDevice) -> Unit,
    private val hasPendingVideo: () -> Boolean
) : RecyclerView.Adapter<RokuDeviceAdapter.DeviceViewHolder>() {
    
    private var devices = listOf<RokuDevice>()
    
    fun updateDevices(newDevices: List<RokuDevice>) {
        devices = newDevices
        notifyDataSetChanged()
    }
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): DeviceViewHolder {
        val binding = ItemRokuDeviceBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return DeviceViewHolder(binding)
    }
    
    override fun onBindViewHolder(holder: DeviceViewHolder, position: Int) {
        holder.bind(devices[position])
    }
    
    override fun getItemCount(): Int = devices.size
    
    inner class DeviceViewHolder(
        private val binding: ItemRokuDeviceBinding
    ) : RecyclerView.ViewHolder(binding.root) {
        
        fun bind(device: RokuDevice) {
            binding.deviceName.text = device.displayName
            binding.deviceModel.text = "Roku Device"
            binding.deviceIp.text = device.ipAddress
            binding.deviceStatus.text = if (device.isOnline) "Online" else "Offline"
            
            // Show/hide send button based on whether there's a pending video
            val hasVideo = hasPendingVideo()
            binding.sendButton.visibility = if (hasVideo) android.view.View.VISIBLE else android.view.View.GONE
            
            // Set up click listeners
            binding.root.setOnClickListener {
                onDeviceClick(device)
            }
            
            binding.sendButton.setOnClickListener {
                onSendToDevice(device)
            }
        }
    }
}
