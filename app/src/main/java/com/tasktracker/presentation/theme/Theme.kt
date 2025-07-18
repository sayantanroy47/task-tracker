package com.tasktracker.presentation.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = TaskBlueDark,
    onPrimary = Color.Black,
    primaryContainer = TaskBlueVariantDark,
    onPrimaryContainer = Color.Black,
    secondary = TaskGreenDark,
    onSecondary = Color.Black,
    secondaryContainer = TaskGreenVariantDark,
    onSecondaryContainer = Color.Black,
    tertiary = TaskOrangeDark,
    onTertiary = Color.Black,
    background = BackgroundDark,
    onBackground = Color.White,
    surface = SurfaceDark,
    onSurface = Color.White,
    surfaceVariant = SurfaceVariantDark,
    onSurfaceVariant = TaskGrayDark,
    error = ErrorDark,
    onError = OnErrorDark,
    errorContainer = TaskRedDark,
    onErrorContainer = Color.Black,
    outline = TaskGrayDark,
    outlineVariant = TaskDarkGrayDark
)

private val LightColorScheme = lightColorScheme(
    primary = TaskBlue,
    onPrimary = Color.White,
    primaryContainer = TaskBlueVariant,
    onPrimaryContainer = Color.White,
    secondary = TaskGreen,
    onSecondary = Color.White,
    secondaryContainer = TaskGreenVariant,
    onSecondaryContainer = Color.White,
    tertiary = TaskOrange,
    onTertiary = Color.White,
    background = BackgroundLight,
    onBackground = Color.Black,
    surface = SurfaceLight,
    onSurface = Color.Black,
    surfaceVariant = SurfaceVariantLight,
    onSurfaceVariant = TaskGray,
    error = ErrorLight,
    onError = OnErrorLight,
    errorContainer = TaskRed,
    onErrorContainer = Color.White,
    outline = TaskGray,
    outlineVariant = TaskLightGray
)

@Composable
fun TaskTrackerTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }

        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}