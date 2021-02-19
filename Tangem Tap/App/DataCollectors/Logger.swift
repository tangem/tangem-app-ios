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
    
    private var fileUrl: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("log.txt")
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS"
        return formatter
    }()
    
    var logFileData: Data? {
        try? Data(contentsOf: fileUrl)
    }
    
    init() {
        clearLogFile()
    }
    
    func log(_ message: String, level: Log.Level) {
        if let handle = try? FileHandle(forWritingTo: fileUrl) {
            handle.seekToEndOfFile()
            handle.write(message.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? "\(self.dateFormatter.string(from: Date())): \(message)".data(using: .utf8)?.write(to: fileUrl)
        }
    }
    
    func clearLogFile() {
        try? fileManager.removeItem(at: fileUrl)
    }
    
}
