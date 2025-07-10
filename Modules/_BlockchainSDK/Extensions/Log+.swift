//
//  Log+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension Log {
    @inline(__always)
    static func log(file: StaticString = #fileID, line: UInt = #line, _ message: @autoclosure () -> String) {
        debug("\(file):\(line): \(message())")
    }
}
