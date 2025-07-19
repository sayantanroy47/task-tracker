package com.tasktracker.data.repository

/**
 * Exception thrown when there are issues with task storage operations.
 * This includes database errors, storage full conditions, and data corruption.
 */
open class TaskStorageException(
    message: String,
    cause: Throwable? = null
) : RuntimeException(message, cause)

/**
 * Exception thrown when the device storage is full or nearly full.
 */
class StorageFullException(
    message: String = "Device storage is full. Please free up space to continue.",
    cause: Throwable? = null
) : TaskStorageException(message, cause)

/**
 * Exception thrown when task data is corrupted or cannot be read.
 */
class DataCorruptionException(
    message: String = "Task data is corrupted. Attempting recovery...",
    cause: Throwable? = null
) : TaskStorageException(message, cause)