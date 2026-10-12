//
//  SafeOperationParameters.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// The terms a Safe operation is priced on: what the relayer is refunded for beyond the inner call, how far above the
/// network's price the refund is fixed, and whom it is paid to. Set by whoever runs the relayer, not by the network.
public struct SafeOperationParameters: Hashable {
    /// The gas `execTransaction` spends around the inner call: signature checks, the nonce, the refund.
    public let baseGas: BigUInt
    /// Added to `baseGas` for the first operation in a network, which deploys the Safe.
    public let deployGas: BigUInt
    public let gasPriceMarginPercent: BigUInt
    public let safeTxGasBufferPercent: BigUInt
    public let gasToken: SafeGasToken
    public let refundReceiver: String

    public init(
        baseGas: BigUInt,
        deployGas: BigUInt,
        gasPriceMarginPercent: BigUInt,
        safeTxGasBufferPercent: BigUInt,
        gasToken: SafeGasToken,
        refundReceiver: String
    ) {
        self.baseGas = baseGas
        self.deployGas = deployGas
        self.gasPriceMarginPercent = gasPriceMarginPercent
        self.safeTxGasBufferPercent = safeTxGasBufferPercent
        self.gasToken = gasToken
        self.refundReceiver = refundReceiver
    }
}
