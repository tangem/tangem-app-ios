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
    private static let shared = OSLogZipFileParser()

    private lazy var fileManager: FileManager = .default
    private lazy var logZipFileURL: URL = OSLogFileWriter.shared.logFile
        .deletingLastPathComponent()
        .appendingPathComponent(OSLogConstants.zipFileName)

    private init() {}

    public static func zipFile() throws -> URL {
        try OSLogZipFileParser.shared.fileManager.zipItem(at: OSLogFileWriter.shared.logFile, to: OSLogZipFileParser.shared.logZipFileURL)
        return OSLogZipFileParser.shared.logZipFileURL
    }

    public static func removeFile() throws {
        try OSLogZipFileParser.shared.fileManager.removeItem(at: OSLogZipFileParser.shared.logZipFileURL)
    }
}
