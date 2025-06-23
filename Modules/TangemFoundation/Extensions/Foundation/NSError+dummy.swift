//
//  NSError+dummy.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public extension NSError {
    static var dummy: NSError {
        NSError(domain: "", code: -1, userInfo: nil)
    }
}
