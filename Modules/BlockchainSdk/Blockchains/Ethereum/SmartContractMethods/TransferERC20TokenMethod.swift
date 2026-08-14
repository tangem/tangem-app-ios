//
//  TransferERC20TokenMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// https://eips.ethereum.org/EIPS/eip-20#transfer
public struct TransferERC20TokenMethod {
    let destination: SmartContractAddress
    let amount: BigUInt

    public init(destination: String, amount: BigUInt) throws {
        self.amount = amount
        self.destination = try SmartContractAddress(destination)
    }
}

// MARK: - SmartContractMethod

extension TransferERC20TokenMethod: SmartContractMethod {
    public var methodId: String { "0xa9059cbb" }

    public var data: Data {
        let prefixData = Data(hexString: methodId)
        let addressData = destination.encodedParameter
        let amountData = amount.serialize().leadingZeroPadding(toLength: 32)
        return prefixData + addressData + amountData
    }
}
