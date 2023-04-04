//
//  CommonSwappingLogger.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct CommonSwappingLogger: SwappingLogger {
    func error(_ error: Error) {
        print(error)
    }

    func debug<T>(_ message: @autoclosure () -> T) {
        print(message())
    }
}
