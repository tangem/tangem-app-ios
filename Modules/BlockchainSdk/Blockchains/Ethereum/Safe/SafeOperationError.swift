//
//  SafeOperationError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum SafeOperationError: Error {
    /// Anything but a transfer of the coin or of a token cannot be run through a Safe here.
    case unsupportedInnerCall
}
