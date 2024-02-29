//
//  ExpressTransactionStatus.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressTransactionStatus: String, Codable {
    case new
    case waiting
    case confirming
    case exchanging
    case sending
    case finished
    case failed
    case refunded
    case verifying
    case expired
}
