package com.nexus.nexus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class NexusWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.nexus_widget).apply {
                val imageName = widgetData.getString("nexus_widget_image", null)
                if (imageName != null) {
                    setImageViewUri(R.id.widget_image, Uri.parse(imageName))
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
