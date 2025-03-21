//
//  OSLogZipFileBuilder.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import ZIPFoundation

public enum OSLogZipFileBuilder {
    private static let fileManager: FileManager = .default
    private static let logZipFileURL: URL = OSLogFileWriter.shared.logFile
        .deletingLastPathComponent()
        .appendingPathComponent(OSLogConstants.zipFileName)

    public static func zipFile() throws -> URL {
        let fileManager = OSLogZipFileBuilder.fileManager
        let zipFile = OSLogZipFileBuilder.logZipFileURL

        if fileManager.fileExists(atPath: zipFile.path) {
            try OSLogZipFileBuilder.removeFile()
        }

        try fileManager.zipItem(at: OSLogFileWriter.shared.logFile, to: zipFile)
        return zipFile
    }

    public static func removeFile() throws {
        try OSLogZipFileBuilder.fileManager.removeItem(at: OSLogZipFileBuilder.logZipFileURL)
    }
}
