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
        try? Data(contentsOf: scanLogsFileURL)
    }
    
    var scanLogsFileURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("scanLogs.txt")
    }

    private let loggerSerialQueue = DispatchQueue(label: "com.tangem.filelogger.queue")
    private let numberOfDaysUntilExpiration = 7

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        return formatter
    }()

    public func log(_ message: String, level: Log.Level) {
        guard Log.filter(level) else { return }

        let formattedMessage = "\(level.emoji) \(dateFormatter.string(from: Date())):\(level.prefix) \(message)\n"
        appendToLog(formattedMessage)
    }

    public func logAppLaunch(_ currentLaunch: Int) {
        let dashSeparator = String(repeating: "-", count: 25)
        let launchNumberMessage = "\(dashSeparator) New session. Current launch number: \(currentLaunch) \(dashSeparator)"
        let deviceInfoMessage = "\(dashSeparator) \(DeviceInfoProvider.Subject.allCases.map { $0.description }.joined(separator: ", ")) \(dashSeparator)"
        appendToLog("\n\(launchNumberMessage)\n\(deviceInfoMessage)\n\n")
    }

    func removeLogFileIfNeeded() {
        let fileManager = FileManager.default
        let calendar = Calendar.current

        guard
            let fileAttributes = try? fileManager.attributesOfItem(atPath: scanLogsFileURL.relativePath),
            let creationDate = fileAttributes[.creationDate] as? Date,
            let expirationDate = calendar.date(byAdding: .day, value: numberOfDaysUntilExpiration, to: creationDate),
            expirationDate < Date()
        else {
            return
        }

        do {
            try fileManager.removeItem(at: scanLogsFileURL)
        } catch {
            AppLog.shared.debug("Failed to delete log file. Error: \(error)")
        }
    }

    private func appendToLog(_ message: String) {
        loggerSerialQueue.async {
            let messageData = message.data(using: .utf8)!

            if let handler = try? FileHandle(forWritingTo: self.scanLogsFileURL) {
                handler.seekToEndOfFile()
                handler.write(messageData)
                handler.closeFile()
            } else {
                try? messageData.write(to: self.scanLogsFileURL)
            }
        }
    }
}
