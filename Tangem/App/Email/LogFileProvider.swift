//
//  LogFileProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol LogFileProvider {
    var fileName: String { get }
    var logData: Data? { get }
    func prepareLogFile() -> URL
}
