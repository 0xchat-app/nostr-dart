package com.oxchat.nostrcore

import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import fr.acinq.secp256k1.Secp256k1

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.collections.HashMap


/** ChatcorePlugin */
class ChatcorePlugin : FlutterPlugin, MethodCallHandler, ActivityAware, ActivityResultListener {
    companion object {
        private const val OX_CORE_CHANNEL = "com.oxchat.nostrcore"
    }

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var mContext: Context
    private lateinit var mActivity: Activity
    private var mMethodChannelResultMap: HashMap<Int, Result?> = HashMap<Int, Result?>()
    private var mSignatureRequestCodeList: MutableSet<Int> = mutableSetOf()
    private val mSignerPackageName: String = "com.greenart7c3.nostrsigner"
    private val secp256k1 = Secp256k1.get()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        mContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, OX_CORE_CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        mActivity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivity() {}

    override fun onMethodCall(call: MethodCall, result: Result) {
        var paramsMap: HashMap<*, *>? = null
        if (call.arguments != null && call.arguments is HashMap<*, *>) {
            paramsMap = call.arguments as HashMap<*, *>
        }
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
                return
            }
            "verifySignature" -> {
                if (paramsMap != null) verifySignature(call, result)
                return
            }
            "signSchnorr" -> {
                if (paramsMap != null) signSchnorr(call, result)
                return
            }
            "isAppInstalled" -> {
                paramsMap?.let { map ->
                    val packageName: String? = map["packageName"] as? String
                    if (packageName != null) {
                        val isInstalled: Boolean = PackageUtils.isPackageInstalled(mContext, packageName)
                        result.success(isInstalled)
                    }
                }
                return
            }
            "nostrsigner" -> {
                if (paramsMap != null) nostrsigner(paramsMap, result)
                return
            }
            else -> {
                result.notImplemented()
                return
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, result: Intent?): Boolean {
        if (mSignatureRequestCodeList.contains(requestCode)) {
            if (resultCode == Activity.RESULT_OK && result != null) {
                val dataMap: HashMap<String, String?> = HashMap()

                if (result.extras != null){
                    Log.e("Michael", "${result.extras!!.keySet()}")
                }
                if (result.hasExtra("signature")) {
                    val signature = result.getStringExtra("signature")
                    dataMap["signature"] = signature
                }
                if (result.hasExtra("id")) {
                    val id = result.getStringExtra("id")
                    dataMap["id"] = id
                }
                if (result.hasExtra("event")) {
                    val event = result.getStringExtra("event")
                    dataMap["event"] = event
                }
                mMethodChannelResultMap[requestCode]?.success(dataMap)
            }
            mMethodChannelResultMap.remove(requestCode)
            return true
        }
        return false
    }

    private fun nostrsigner (paramsMap: HashMap<*, *>, result: Result){

        val resultFromCR: HashMap<String, String?>? = getDataContentResolver(paramsMap)
        if (!resultFromCR.isNullOrEmpty()) {
            result.success(resultFromCR)
            return
        }
        val requestCode = result.hashCode()
        mSignatureRequestCodeList.add(requestCode)
        mMethodChannelResultMap[requestCode] = result
        var extendParse: String? = paramsMap["extendParse"] as? String
        val intent = Intent(
            Intent.ACTION_VIEW, Uri.parse(
                "nostrsigner:$extendParse"
            )
        )
        intent.`package` = mSignerPackageName
        paramsMap["permissions"]?.let { permissions ->
            if (permissions is String) intent.putExtra("permissions", permissions)
        }

        var type: String? = paramsMap["type"] as? String ?: "get_public_key"
        intent.putExtra("type", type)

        paramsMap["id"]?.let { id ->
            if (id is String) intent.putExtra("id", id)
        }
        paramsMap["current_user"]?.let { currentUser ->
            if (currentUser is String) intent.putExtra("current_user", currentUser)
        }
        paramsMap["pubKey"]?.let { pubKey ->
            if (pubKey is String) intent.putExtra("pubKey", pubKey)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        try {
            mActivity.startActivityForResult(intent, requestCode)
        } catch (e: Exception) {
            mMethodChannelResultMap.remove(requestCode)
            mSignatureRequestCodeList.remove(requestCode)
            result.error("ActivityStartError", "Failed to start amber sign", null)
        }
    }

    fun getDataContentResolver(paramsMap: HashMap<*, *>): HashMap<String, String?>? {
        var type: String = paramsMap["type"] as? String ?: "get_public_key"
        var extendParse: String = paramsMap["extendParse"] as? String ?: ""
        var data = arrayOf(extendParse)
        paramsMap["pubKey"]?.let { pubKey ->
            if (pubKey is String) data += pubKey
        }
        paramsMap["current_user"]?.let { currentUser ->
            if (currentUser is String) data += currentUser
        }
        return getDataFromResolver(type, data, mContext.contentResolver);
    }

    fun getDataFromResolver(
        signerType: String, data: Array<out String>, contentResolver: ContentResolver
    ): HashMap<String, String?>? {
        try {
            contentResolver.query(
                Uri.parse("content://${mSignerPackageName}.${signerType.uppercase()}"),
                data,
                null,
                null,
                null
            ).use {
                if (it == null) {
                    return null
                }
                if (it.moveToFirst()) {
                    val dataMap: HashMap<String, String?> = HashMap()
                    val index = it.getColumnIndex("signature")
                    if (index < 0) {
                        Log.d("getDataFromResolver", "column 'signature' not found")
                    } else {
                        val signature = it.getString(index)
                        dataMap["signature"] = signature
                    }
                    val indexJson = it.getColumnIndex("event")
                    if (indexJson < 0) {
                        Log.d("getDataFromResolver", "column 'event' not found")
                    } else {
                        val eventJson = it.getString(indexJson)
                        dataMap["event"] = eventJson
                    }
                    return dataMap;
                }
            }
        } catch (e: Exception) {
            Log.e("ExternalSignerLauncher", "Failed to query the Signer app in the background")
            return null
        }

        return null
    }

    fun verifySignature(call: MethodCall, result: Result) {
        val sig: ByteArray? = call.argument<ByteArray>("signature");
        val hash: ByteArray? = call.argument<ByteArray>("hash");
        val pubKey: ByteArray? = call.argument<ByteArray>("pubKey");

        if (sig != null && hash != null && pubKey != null) {
            result.success(secp256k1.verifySchnorr(sig, hash, pubKey))
        } else {
            // Handle the case where any of the arguments is null
            result.success(false)
        }
    }

    fun signSchnorr(call: MethodCall, result: Result) {
        val data: ByteArray? = call.argument<ByteArray>("data");
        val privKey: ByteArray? = call.argument<ByteArray>("privKey");

        if (data != null && privKey != null) {
            result.success(secp256k1.signSchnorr(data, privKey, null))
        } else {
            // Handle the case where any of the arguments is null
            result.success(false)
        }
    }

}