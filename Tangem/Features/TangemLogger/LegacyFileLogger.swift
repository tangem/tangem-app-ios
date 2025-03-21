//
//  LegacyFileLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct LegacyFileLogger {
    /// Remove the legacy log file
    func remove() {
        do {
            let fileManager = FileManager.default
            let temporaryFiles = try fileManager.contentsOfDirectory(
                at: fileManager.temporaryDirectory,
                includingPropertiesForKeys: nil
            )
            let cachesFiles = try fileManager.contentsOfDirectory(
                at: fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0],
                includingPropertiesForKeys: nil
            )

            let files = (temporaryFiles + cachesFiles)
            for file in files {
                if file.pathExtension == "txt" {
                    try fileManager.removeItem(at: file)
                }

                if file.pathExtension == "zip" {
                    try fileManager.removeItem(at: file)
                }
            }
        } catch {
            AppLogger.error(error: error)
        }
    }
}
