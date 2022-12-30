//
//  FileLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class FileLogger: TangemSdkLogger {
    var logData: Data? {
        try? Data(contentsOf: scanLogsFileUrl)
    }

    private let loggerSerialQueue = DispatchQueue(label: "com.tangem.filelogger.queue")

    private var scanLogsFileUrl: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("scanLogs.txt")
    }

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS"
        return formatter
    }()

    public func log(_ message: String, level: Log.Level) {
        guard Log.filter(level) else { return }

        loggerSerialQueue.async {
            let formattedMessage = "\(level.emoji) \(self.dateFormatter.string(from: Date())):\(level.prefix) \(message)"
            let messageData = formattedMessage.data(using: .utf8)!

            if let handler = try? FileHandle(forWritingTo: self.scanLogsFileUrl) {
                handler.seekToEndOfFile()
                handler.write(messageData)
                handler.closeFile()
            } else {
                try? messageData.write(to: self.scanLogsFileUrl)
            }
        }
    }
}
