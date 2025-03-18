//
//  OSLogZipFileParser.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import ZIPFoundation

public class OSLogZipFileParser {
    private static let fileManager: FileManager = .default
    private static let logZipFileURL: URL = OSLogFileWriter.shared.logFile
        .deletingLastPathComponent()
        .appendingPathComponent(OSLogConstants.zipFileName)

    private init() {}

    public static func zipFile() throws -> URL {
        let fileManager = OSLogZipFileParser.fileManager
        let zipFile = OSLogZipFileParser.logZipFileURL

        if fileManager.fileExists(atPath: zipFile.path) {
            try OSLogZipFileParser.removeFile()
        }

        try fileManager.zipItem(at: OSLogFileWriter.shared.logFile, to: zipFile)
        return zipFile
    }

    public static func removeFile() throws {
        try OSLogZipFileParser.fileManager.removeItem(at: OSLogZipFileParser.logZipFileURL)
    }
}
