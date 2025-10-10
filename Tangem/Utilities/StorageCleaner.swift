//
//  StorageCleaner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Utility class for cleaning storage files during UI tests
enum StorageCleaner {
    /// Clears all cached files for UI tests
    static func clearCachedFiles() {
        AppLogger.info("Clearing cached files for UI tests")

        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]

        let cacheFiles = [
            "cached_balances.json",
            "cached_quotes.json",
            "cached_express_availability.json",
        ]

        for cacheFile in cacheFiles {
            let fileURL = cachesDirectory.appendingPathComponent(cacheFile)
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    AppLogger.info("Cleared cache file: \(cacheFile)")
                } catch {
                    AppLogger.error(error: "Failed to clear cache file \(cacheFile): \(error)")
                }
            }
        }

        AppLogger.info("Cached files cleared for UI tests")
    }
}
