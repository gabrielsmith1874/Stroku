package com.stremio.bridge.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

@Parcelize
data class RokuDevice(
    val name: String,
    val ipAddress: String,
    val port: Int = 8060,
    val isOnline: Boolean = true
) : Parcelable {
    val displayName: String
        get() = if (name.isNotEmpty()) name else "Roku Device ($ipAddress)"
    
    val baseUrl: String
        get() = "http://$ipAddress:$port"
}
