//
//  LogsComposer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLogger

class LogsComposer {
    private let infoProvider: LogFileProvider
    private let includeZipLogs: Bool

    init(infoProvider: LogFileProvider, includeZipLogs: Bool = true) {
        self.infoProvider = infoProvider
        self.includeZipLogs = includeZipLogs
    }

    /// Tokens list info
    func getInfoData() -> Data? {
        infoProvider.logData
    }

    func getZipLogsData() -> (data: Data, file: URL)? {
        guard includeZipLogs else {
            return nil
        }

        do {
            let file = try OSLogZipFileBuilder.zipFile()
            let data = try Data(contentsOf: file)

            return (data: data, file: file)
        } catch {
            AppLogger.error("LogsComposer zip file preparing", error: error)
            return nil
        }
    }
}
