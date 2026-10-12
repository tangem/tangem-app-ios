//
//  SafeInnerCallType.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// What a Safe inner call is. A transfer for now; other kinds take their place beside it as the operations that need
/// them arrive.
public enum SafeInnerCallType: Hashable {
    case transfer(SafeInnerCallTypeTransfer)
}

public enum SafeInnerCallTypeTransfer: Hashable {
    /// The Safe calls the recipient with the value and no data.
    case coin(destination: String, value: BigUInt)
    /// The Safe calls the token's contract with `transfer(recipient, amount)` and no value.
    case token(contractAddress: String, destination: String, value: BigUInt)
}

public extension SafeInnerCallType {
    /// Who receives the coin or the token.
    var destination: String {
        switch self {
        case .transfer(.coin(let destination, _)), .transfer(.token(_, let destination, _)):
            return destination
        }
    }

    /// In the smallest unit of the coin or the token.
    var value: BigUInt {
        switch self {
        case .transfer(.coin(_, let value)), .transfer(.token(_, _, let value)):
            return value
        }
    }
}
