//
//  AppDatabaseDropUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAppDatabase

enum AppDatabaseDropUtil {
    static func scheduleDrop() {
        #if INTERNAL || DEBUG
        FeatureStorage.instance.isAppDatabaseDropScheduled = true
        AppLogger.info("Scheduled the app database to be dropped on the next launch")
        #endif // INTERNAL || DEBUG
    }

    static func dropIfScheduled() {
        #if INTERNAL || DEBUG
        guard FeatureStorage.instance.isAppDatabaseDropScheduled else {
            return
        }

        do {
            let directoryURL = try AppDatabase.databaseDirectoryURL
            let fileManager = FileManager.default

            if fileManager.fileExists(atPath: directoryURL.path(percentEncoded: false)) {
                try fileManager.removeItem(at: directoryURL)
            }

            FeatureStorage.instance.isAppDatabaseDropScheduled = false
            AppLogger.info("Dropped the app database")
        } catch {
            // The `isAppDatabaseDropScheduled` flag is left set on failure, so the drop is retried on the next launch
            AppLogger.error("Failed to drop the app database", error: error)
        }
        #endif // INTERNAL || DEBUG
    }
}
