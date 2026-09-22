//
//  SafeTransactionFeeParameters.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// The gas terms a Safe operation was priced with, carried inside the `Fee` that is shown so that what is signed later
/// is exactly what was displayed. The Safe refunds `(safeTxGas + baseGas) × gasPrice` to the relayer in `gasToken`, so
/// that sum is the gas limit and the fee is in the gas token, not necessarily in the coin.
public struct SafeTransactionFeeParameters: EthereumFeeParameters, Hashable {
    public let safeTxGas: BigUInt
    public let baseGas: BigUInt
    /// In the smallest units of `gasToken` per unit of gas.
    public let gasPrice: BigUInt
    public let gasToken: SafeGasToken
    public let refundReceiver: String
    /// Whether `baseGas` had the deployment folded in; a Safe deployed since makes the price stale.
    public let isDeployed: Bool
    /// The Safe's own nonce the operation was priced at, the one the backend checks against the chain. Editable by
    /// hand the way an account nonce is.
    public let nonce: Int?

    public var gasLimit: BigUInt { safeTxGas + baseGas }

    public init(
        safeTxGas: BigUInt,
        baseGas: BigUInt,
        gasPrice: BigUInt,
        gasToken: SafeGasToken,
        refundReceiver: String,
        isDeployed: Bool,
        nonce: Int? = nil
    ) {
        self.safeTxGas = safeTxGas
        self.baseGas = baseGas
        self.gasPrice = gasPrice
        self.gasToken = gasToken
        self.refundReceiver = refundReceiver
        self.isDeployed = isDeployed
        self.nonce = nonce
    }
}

// MARK: - EthereumFeeParameters

public extension SafeTransactionFeeParameters {
    var parametersType: EthereumFeeParametersType {
        .safe(self)
    }

    /// Only the inner call's share can move: `baseGas` is what the relayer is refunded for around it.
    func changingGasLimit(to value: BigUInt) -> SafeTransactionFeeParameters {
        SafeTransactionFeeParameters(
            safeTxGas: value > baseGas ? value - baseGas : 0,
            baseGas: baseGas,
            gasPrice: gasPrice,
            gasToken: gasToken,
            refundReceiver: refundReceiver,
            isDeployed: isDeployed,
            nonce: nonce
        )
    }

    func changingGasPrice(to value: BigUInt) -> SafeTransactionFeeParameters {
        SafeTransactionFeeParameters(
            safeTxGas: safeTxGas,
            baseGas: baseGas,
            gasPrice: value,
            gasToken: gasToken,
            refundReceiver: refundReceiver,
            isDeployed: isDeployed,
            nonce: nonce
        )
    }

    func changingNonce(to value: Int?) -> SafeTransactionFeeParameters {
        SafeTransactionFeeParameters(
            safeTxGas: safeTxGas,
            baseGas: baseGas,
            gasPrice: gasPrice,
            gasToken: gasToken,
            refundReceiver: refundReceiver,
            isDeployed: isDeployed,
            nonce: value
        )
    }

    /// In `gasToken`: the coin is divided by the network's `decimalValue` handed in, a token by its own.
    func calculateFee(decimalValue: Decimal) -> Decimal {
        let total = (safeTxGas + baseGas) * gasPrice
        let totalValue = total.decimal ?? Decimal(string: total.description) ?? 0

        switch gasToken {
        case .coin: return totalValue / decimalValue
        case .token(let token, _, _): return totalValue / token.decimalValue
        }
    }
}
