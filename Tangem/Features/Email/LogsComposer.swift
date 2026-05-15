//
//  LogsComposer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLogger

final class LogsComposer {
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

    func getZipLogsData(completion: @escaping ((data: Data, file: URL)?) -> Void) {
        guard includeZipLogs else {
            completion(nil)
            return
        }

        OSLogFileWriter.shared.zipLogFile(infoData: getInfoData()) { result in
            switch result {
            case .success(let file):
                do {
                    let data = try Data(contentsOf: file)
                    completion((data: data, file: file))
                } catch {
                    AppLogger.error("LogsComposer zip file reading", error: error)
                    completion(nil)
                }
            case .failure(let error):
                AppLogger.error("LogsComposer zip file preparing", error: error)
                completion(nil)
            }
        }
    }
}
