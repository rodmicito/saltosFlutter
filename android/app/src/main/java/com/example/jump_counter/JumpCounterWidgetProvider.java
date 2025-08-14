package com.example.jump_counter;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;

public class JumpCounterWidgetProvider extends AppWidgetProvider {

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId);
        }
    }

    static void updateAppWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        // Construir el layout del widget
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.jump_counter_widget);

        // Obtener datos guardados
        SharedPreferences prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
        
        int jumpCount = prefs.getInt("flutter.jump_count", 0);
        String lastUpdate = prefs.getString("flutter.last_update", "--:--");
        String status = prefs.getString("flutter.status", "PAUSADO");

        // Actualizar las vistas
        views.setTextViewText(R.id.widget_jump_count, String.valueOf(jumpCount));
        views.setTextViewText(R.id.widget_time, lastUpdate);
        views.setTextViewText(R.id.widget_status, status);

        // Cambiar color según el estado
        if ("ACTIVO".equals(status)) {
            views.setTextColor(R.id.widget_status, 0xFF4CAF50); // Verde
        } else {
            views.setTextColor(R.id.widget_status, 0xFFFFA726); // Naranja
        }

        // Instruir al AppWidgetManager para que realice una actualización en el widget
        appWidgetManager.updateAppWidget(appWidgetId, views);
    }
}
