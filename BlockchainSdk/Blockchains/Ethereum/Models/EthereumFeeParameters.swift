//
//  EthereumFeeParameters.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

// MARK: - EthereumFeeParameters

public protocol EthereumFeeParameters where Self: FeeParameters {
    var parametersType: EthereumFeeParametersType { get }

    /// Custom nonce value entered by the user on the send screen.
    /// Overrides the default nonce fetched from the network.
    var nonce: Int? { get }

    func changingGasLimit(to value: BigUInt) -> Self
    func calculateFee(decimalValue: Decimal) -> Decimal
}

public enum EthereumFeeParametersConstants {
    public static var defaultGasLimitIncreasePercent = BigUInt(12)
    public static var yieldModuleGasLimitIncreasePercent = BigUInt(20)
    public static var gaslessMinTokenAmount = BigUInt(10_000)
    public static var gaslessBaseGasBuffer = BigUInt(100_000)
    public static var gaslessMaxFeePerGasMultiplier = BigUInt(2)
}

public extension EthereumFeeParameters {
    var maximumFeePerGas: BigUInt? {
        switch parametersType {
        case .eip1559(let params):
            return params.maxFeePerGas
        case .legacy:
            return nil
        case .gasless(let params):
            return params.maxFeePerGas
        }
    }

    var gasLimit: BigUInt {
        switch parametersType {
        case .eip1559(let params):
            return params.gasLimit
        case .legacy(let params):
            return params.gasLimit
        case .gasless(let params):
            return params.gasLimit
        }
    }

    var nonce: Int? {
        switch parametersType {
        case .legacy(let params):
            return params.nonce
        case .eip1559(let params):
            return params.nonce
        case .gasless(let params):
            return params.nonce
        }
    }
}

// MARK: - EthereumFeeParametersType

public enum EthereumFeeParametersType {
    case legacy(EthereumLegacyFeeParameters)
    case eip1559(EthereumEIP1559FeeParameters)
    case gasless(EthereumGaslessTransactionFeeParameters)
}

// MARK: - EthereumLegacyFeeParameters

public struct EthereumLegacyFeeParameters: FeeParameters {
    public let gasLimit: BigUInt
    public let gasPrice: BigUInt
    public let nonce: Int?

    public init(gasLimit: BigUInt, gasPrice: BigUInt, nonce: Int? = nil) {
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
        self.nonce = nonce
    }
}

extension EthereumLegacyFeeParameters: EthereumFeeParameters {
    public var parametersType: EthereumFeeParametersType {
        .legacy(self)
    }

    public func calculateFee(decimalValue: Decimal) -> Decimal {
        let feeWEI = gasLimit * gasPrice
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
        // [REDACTED_INFO]
        let feeValue = feeWEI.decimal ?? Decimal(UInt64(feeWEI))
        return feeValue / decimalValue
    }

    public func changingGasLimit(to value: BigUInt) -> EthereumLegacyFeeParameters {
        let feeParameters = EthereumLegacyFeeParameters(
            gasLimit: value,
            gasPrice: gasPrice,
            nonce: nonce
        )

        return feeParameters
    }
}

// MARK: - EthereumEIP1559FeeParameters

public struct EthereumEIP1559FeeParameters: FeeParameters {
    public let gasLimit: BigUInt
    /// Maximum fee which will be spend. Should include `priorityFee` in itself
    public let maxFeePerGas: BigUInt
    /// The part of `maxFeePerGas` which will be sent a mainer like a tips
    public let priorityFee: BigUInt
    /// Custom nonce property for resend transaction state
    public let nonce: Int?

    public init(gasLimit: BigUInt, baseFee: BigUInt, priorityFee: BigUInt, nonce: Int? = nil) {
        self.gasLimit = gasLimit
        maxFeePerGas = baseFee + priorityFee
        self.priorityFee = priorityFee
        self.nonce = nonce
    }

    public init(gasLimit: BigUInt, maxFeePerGas: BigUInt, priorityFee: BigUInt, nonce: Int? = nil) {
        self.gasLimit = gasLimit
        self.maxFeePerGas = maxFeePerGas
        self.priorityFee = priorityFee
        self.nonce = nonce
    }
}

extension EthereumEIP1559FeeParameters: EthereumFeeParameters {
    public var parametersType: EthereumFeeParametersType {
        .eip1559(self)
    }

    public func calculateFee(decimalValue: Decimal) -> Decimal {
        let feeWEI = gasLimit * maxFeePerGas
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
        // [REDACTED_INFO]
        let feeValue = feeWEI.decimal ?? Decimal(UInt64(feeWEI))
        return feeValue / decimalValue
    }

    public func changingGasLimit(to value: BigUInt) -> EthereumEIP1559FeeParameters {
        let feeParameters = EthereumEIP1559FeeParameters(
            gasLimit: value,
            maxFeePerGas: maxFeePerGas,
            priorityFee: priorityFee,
            nonce: nonce
        )

        return feeParameters
    }
}

public struct EthereumGaslessTransactionFeeParameters: FeeParameters {
    public let gasLimit: BigUInt
    /// Maximum fee which will be spend. Should include `priorityFee` in itself
    public let maxFeePerGas: BigUInt
    /// The part of `maxFeePerGas` which will be sent a mainer like a tips
    public let priorityFee: BigUInt
    /// Custom nonce property for resend transaction state
    public let nonce: Int?
    /// Conversion rate from native coin to token.
    /// Represents how many token units correspond to 1 unit of native coin
    /// (e.g. 1 ETH = 1500 USDC → coinToTokenRate = 1500).
    public let nativeToFeeTokenRate: Decimal

    public init(gasLimit: BigUInt, baseFee: BigUInt, priorityFee: BigUInt, nonce: Int? = nil, nativeToFeeTokenRate: Decimal) {
        self.gasLimit = gasLimit
        maxFeePerGas = baseFee + priorityFee
        self.priorityFee = priorityFee
        self.nonce = nonce
        self.nativeToFeeTokenRate = nativeToFeeTokenRate
    }

    public init(gasLimit: BigUInt, maxFeePerGas: BigUInt, priorityFee: BigUInt, nonce: Int? = nil, nativeToFeeTokenRate: Decimal) {
        self.gasLimit = gasLimit
        self.maxFeePerGas = maxFeePerGas
        self.priorityFee = priorityFee
        self.nonce = nonce
        self.nativeToFeeTokenRate = nativeToFeeTokenRate
    }
}

extension EthereumGaslessTransactionFeeParameters: EthereumFeeParameters {
    public var parametersType: EthereumFeeParametersType {
        .gasless(self)
    }

    /// Calculates the transaction fee expressed in the selected token.
    ///
    /// Calculation steps:
    /// 1. Computes the fee in native coin smallest units (wei):
    ///    feeWEI = gasLimit × maxFeePerGas
    /// 2. Converts the fee from wei to native coin using `decimalValue` (e.g. 1e18 for ETH):
    ///    feeInCoin = feeWEI / decimalValue
    /// 3. Converts the fee from native coin to token using `nativeToFeeTokenRate`:
    ///    feeInToken = feeInCoin × coinToTokenRate
    ///
    /// Example:
    /// - gasLimit = 21_000
    /// - maxFeePerGas = 30 gwei = 30_000_000_000
    /// - feeWEI = 630_000_000_000_000
    /// - decimalValue = 1e18 (ETH decimals)
    /// - feeInCoin = 0.00063 ETH
    /// - coinToTokenRate = 1500 (1 ETH = 1500 USDC)
    /// - feeInToken = 0.945 USDC
    public func calculateFee(decimalValue: Decimal) -> Decimal {
        let feeWEI = gasLimit * maxFeePerGas
        let feeValue = feeWEI.decimal ?? Decimal(UInt64(feeWEI))
        let feeInCoin = feeValue / decimalValue
        let feeInToken = feeInCoin * nativeToFeeTokenRate
        return feeInToken
    }

    public func changingGasLimit(to value: BigUInt) -> EthereumGaslessTransactionFeeParameters {
        EthereumGaslessTransactionFeeParameters(
            gasLimit: value,
            maxFeePerGas: maxFeePerGas,
            priorityFee: priorityFee,
            nonce: nonce,
            nativeToFeeTokenRate: nativeToFeeTokenRate
        )
    }
}
