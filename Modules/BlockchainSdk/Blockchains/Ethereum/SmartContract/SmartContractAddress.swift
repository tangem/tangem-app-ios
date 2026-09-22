//
//  SmartContractAddress.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Validation wrapper around raw `String` arguments, passed as addresses to smart contract calls.
public struct SmartContractAddress: Equatable {
    private let address: String

    public init(_ address: String) throws {
        let address = address.addHexPrefix()

        guard address.isEvmAddress else {
            throw Error.invalidAddress
        }

        // Fail closed: the ABI slot is built with `Data(hexString:)`, which returns empty data for any
        // non-ASCII scalar. Require the decoded form to be exactly 20 bytes so a string that passed the
        // shape check can never silently encode as the zero address.
        guard Data(hexString: address.removeHexPrefix()).count == Constants.addressLength else {
            throw Error.invalidAddress
        }

        guard !EVMAddressUtils.isBurnAddress(address) else {
            throw Error.burnAddress
        }

        self.address = address
    }

    public var encodedParameter: Data {
        Data(hexString: address.removeHexPrefix()).leadingZeroPadding(toLength: Constants.parameterLength)
    }
}

// MARK: - Auxiliary types

public extension SmartContractAddress {
    enum Error: Swift.Error, Equatable {
        case invalidAddress
        case burnAddress
    }
}

// MARK: - Constants

private extension SmartContractAddress {
    enum Constants {
        static let parameterLength = 32
        static let addressLength = 20
    }
}
