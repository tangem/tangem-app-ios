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
    init(infoProvider: LogFileProvider) {
        self.infoProvider = infoProvider
    }

    /// Tokens list info
    func getInfoData() -> Data? {
        infoProvider.logData
    }

    func getZipLogsData() -> (data: Data, file: URL)? {
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
