//
//  Logger.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class Logger: TangemSdkLogger {
    
    let fileManager = FileManager.default
    
    var scanLogFileData: Data? {
        try? Data(contentsOf: scanLogsFileUrl)
    }
    
    private var scanLogsFileUrl: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("scanLogs.txt")
    }
    
    private var txLogsFileUrl: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("txLogs.txt")
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS"
        return formatter
    }()
    
    private var hashesToSign: [Data]?
    private var txHex: String?
    
    init() {
        clearLogFile()
    }
    
    func log(_ message: String, level: Log.Level) {
        if let handle = try? FileHandle(forWritingTo: scanLogsFileUrl) {
            handle.seekToEndOfFile()
            handle.write(message.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? "\(self.dateFormatter.string(from: Date())): \(message)".data(using: .utf8)?.write(to: scanLogsFileUrl)
        }
    }
    
    func clearLogFile() {
        try? fileManager.removeItem(at: scanLogsFileUrl)
    }
    
}
