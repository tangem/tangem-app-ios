//
//  Timeouts.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum Timeouts {
    static let conditional = 10.0
    static let robustUIUpdate = 30.0
    static let networkRequest = 60.0
}

extension TimeInterval {
    static let conditional: TimeInterval = Timeouts.conditional
    static let robustUIUpdate: TimeInterval = Timeouts.robustUIUpdate
    static let networkRequest: TimeInterval = Timeouts.networkRequest
}
