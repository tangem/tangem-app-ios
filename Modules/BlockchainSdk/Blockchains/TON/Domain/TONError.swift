//
//  TONError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum TONError: Error {
    /// Base state error
    case empty

    /// Base exception
    case exception(String)
}
