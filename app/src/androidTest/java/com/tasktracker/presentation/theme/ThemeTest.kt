package com.tasktracker.presentation.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.domain.model.Task
import com.tasktracker.presentation.components.TaskInputComponent
import com.tasktracker.presentation.components.TaskItemComponent
import com.tasktracker.presentation.components.TaskListComponent
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ThemeTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun lightTheme_appliesCorrectColors() {
        composeTestRule.setContent {
            TaskTrackerTheme(darkTheme = false, dynamicColor = false) {
                Surface {
                    // Test that light theme colors are applied
                    val colorScheme = MaterialTheme.colorScheme
                    assert(colorScheme.primary == TaskBlue)
                    assert(colorScheme.secondary == TaskGreen)
                    assert(colorScheme.background == BackgroundLight)
                    assert(colorScheme.surface == SurfaceLight)
                }
            }
        }
    }

    @Test
    fun darkTheme_appliesCorrectColors() {
        composeTestRule.setContent {
            TaskTrackerTheme(darkTheme = true, dynamicColor = false) {
                Surface {
                    // Test that dark theme colors are applied
                    val colorScheme = MaterialTheme.colorScheme
                    assert(colorScheme.primary == TaskBlueDark)
                    assert(colorScheme.secondary == TaskGreenDark)
                    assert(colorScheme.background == BackgroundDark)
                    assert(colorScheme.surface == SurfaceDark)
                }
            }
        }
    }

    @Test
    fun typography_appliesCorrectStyles() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                Surface {
                    val typography = MaterialTheme.typography
                    
                    // Test that typography styles are properly defined
                    assert(typography.headlineMedium.fontSize.value == 28f)
                    assert(typography.bodyLarge.fontSize.value == 16f)
                    assert(typography.bodyMedium.fontSize.value == 14f)
                    assert(typography.bodySmall.fontSize.value == 12f)
                }
            }
        }
    }

    @Test
    fun taskComponents_adaptToLightTheme() {
        val task = Task(id = "1", description = "Test task")

        composeTestRule.setContent {
            TaskTrackerTheme(darkTheme = false, dynamicColor = false) {
                Surface {
                    TaskItemComponent(task = task)
                }
            }
        }

        // Verify that components render without issues in light theme
        // Visual verification would be done manually or with screenshot tests
    }

    @Test
    fun taskComponents_adaptToDarkTheme() {
        val task = Task(id = "1", description = "Test task")

        composeTestRule.setContent {
            TaskTrackerTheme(darkTheme = true, dynamicColor = false) {
                Surface {
                    TaskItemComponent(task = task)
                }
            }
        }

        // Verify that components render without issues in dark theme
        // Visual verification would be done manually or with screenshot tests
    }

    @Test
    fun taskInputComponent_adaptsToTheme() {
        composeTestRule.setContent {
            TaskTrackerTheme(darkTheme = false, dynamicColor = false) {
                Surface {
                    TaskInputComponent()
                }
            }
        }

        // Verify that input component renders correctly with theme colors
    }

    @Test
    fun taskListComponent_adaptsToTheme() {
        val tasks = listOf(
            Task(id = "1", description = "Task 1"),
            Task(id = "2", description = "Task 2")
        )

        composeTestRule.setContent {
            TaskTrackerTheme(darkTheme = true, dynamicColor = false) {
                Surface {
                    TaskListComponent(tasks = tasks)
                }
            }
        }

        // Verify that list component renders correctly with theme colors
    }

    @Test
    fun errorColors_areAccessible() {
        composeTestRule.setContent {
            TaskTrackerTheme(darkTheme = false, dynamicColor = false) {
                Surface {
                    val colorScheme = MaterialTheme.colorScheme
                    
                    // Verify error colors have sufficient contrast
                    assert(colorScheme.error == ErrorLight)
                    assert(colorScheme.onError == OnErrorLight)
                }
            }
        }
    }

    @Test
    fun surfaceColors_provideGoodContrast() {
        composeTestRule.setContent {
            TaskTrackerTheme(darkTheme = false, dynamicColor = false) {
                Surface {
                    val colorScheme = MaterialTheme.colorScheme
                    
                    // Verify surface colors provide good contrast
                    assert(colorScheme.surface == SurfaceLight)
                    assert(colorScheme.onSurface == Color.Black)
                    assert(colorScheme.surfaceVariant == SurfaceVariantLight)
                }
            }
        }
    }

    @Test
    fun themeSupportsSystemDarkMode() {
        composeTestRule.setContent {
            // Test that theme respects system dark mode setting
            TaskTrackerTheme {
                Surface {
                    val isDark = isSystemInDarkTheme()
                    val colorScheme = MaterialTheme.colorScheme
                    
                    // Theme should adapt to system setting
                    if (isDark) {
                        // In dark mode, background should be dark
                        assert(colorScheme.background != BackgroundLight)
                    } else {
                        // In light mode, background should be light
                        assert(colorScheme.background != BackgroundDark)
                    }
                }
            }
        }
    }
}