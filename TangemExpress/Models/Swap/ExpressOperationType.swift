//
//  ExpressOperationType.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressOperationType: String, Codable, Hashable {
    case swap
    case swapAndSend = "swap-and-send"
    case onramp
}
