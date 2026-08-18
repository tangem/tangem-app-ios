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
struct SmartContractAddress {
    private let address: String

    init(_ address: String) throws {
        let address = address.addHexPrefix()

        guard address.isEvmAddress else {
            throw Error.invalidAddress
        }

        guard !EVMAddressUtils.isBurnAddress(address) else {
            throw Error.burnAddress
        }

        self.address = address
    }

    var encodedParameter: Data {
        Data(hexString: address.removeHexPrefix()).leadingZeroPadding(toLength: Constants.parameterLength)
    }
}

// MARK: - Auxiliary types

extension SmartContractAddress {
    enum Error: Swift.Error, Equatable {
        case invalidAddress
        case burnAddress
    }
}

// MARK: - Constants

private extension SmartContractAddress {
    enum Constants {
        static let parameterLength = 32
    }
}
