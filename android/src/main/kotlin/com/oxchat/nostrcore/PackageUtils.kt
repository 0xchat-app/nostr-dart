package com.oxchat.nostrcore

import android.content.Context

/**
 * Title: PackageUtils
 * Description: TODO(Fill in by oneself)
 * Copyright: Copyright (c) 2022
 * Company:  0xchat Teachnology
 * CreateTime: 2023/12/4 15:17
 *
 * @author Michael
 * @since JDK1.8
 */
object PackageUtils {
    fun isPackageInstalled(context: Context, target: String): Boolean {
        return context.packageManager.getInstalledApplications(0).find { info -> info.packageName == target } != null
    }
}