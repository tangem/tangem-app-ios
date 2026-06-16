//
//  Timeouts.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum Timeouts {
    static let shortUIUpdate = 2.0
    static let quick = 5.0
    static let conditional = 10.0
    static let robustUIUpdate = 60.0
    static let networkRequest = 80.0
}

extension TimeInterval {
    static let shortUIUpdate: TimeInterval = Timeouts.shortUIUpdate
    static let quick: TimeInterval = Timeouts.quick
    static let conditional: TimeInterval = Timeouts.conditional
    static let robustUIUpdate: TimeInterval = Timeouts.robustUIUpdate
    static let networkRequest: TimeInterval = Timeouts.networkRequest
}
