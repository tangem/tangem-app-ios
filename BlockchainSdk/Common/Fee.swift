//
//  Fee.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public protocol FeeParameters {}

public struct Fee {
    public var amount: Amount
    public let parameters: FeeParameters?

    public init(_ fee: Amount, parameters: FeeParameters? = nil) {
        amount = fee
        self.parameters = parameters
    }
}

// MARK: - Hashable

extension Fee: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
    }

    public static func == (lhs: Fee, rhs: Fee) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension Fee: CustomStringConvertible {
    public var description: String {
        var string = "Fee: \(amount.description)"
        if let parameters {
            string += "\nFee parameters: \(parameters)"
        }
        return string
    }
}

public extension Fee {
    func increasingGasLimit(byPercents: BigUInt, blockchain: Blockchain, decimalValue: Decimal) -> Fee {
        guard let parameters = parameters as? EthereumFeeParameters else {
            return self
        }

        let gasLimit = parameters.gasLimit * (BigUInt(100) + byPercents) / BigUInt(100)
        let newParameters = parameters.changingGasLimit(to: gasLimit)
        let feeValue = newParameters.calculateFee(decimalValue: decimalValue)

        var amount = amount
        amount.value = feeValue

        return Fee(amount, parameters: newParameters)
    }
}
