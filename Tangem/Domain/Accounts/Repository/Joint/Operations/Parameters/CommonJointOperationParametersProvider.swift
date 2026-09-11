//
//  CommonJointOperationParametersProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk

struct CommonJointOperationParametersProvider {
    @Injected(\.gaslessTransactionsNetworkManager) private var gaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager
}

// MARK: - JointOperationParametersProvider

extension CommonJointOperationParametersProvider: JointOperationParametersProvider {
    func makeParameters(gasToken: SafeGasToken) async throws -> SafeOperationParameters {
        // The treasury the gasless relayer is refunded to, until the joint accounts contract names its own
        guard let refundReceiver = await gaslessTransactionsNetworkManager.feeRecipientAddress else {
            throw TokenFeeLoaderError.missingFeeRecipientAddress
        }

        return SafeOperationParameters(
            baseGas: Constants.baseGas,
            deployGas: Constants.deployGas,
            gasPriceMarginPercent: Constants.gasPriceMarginPercent,
            safeTxGasBufferPercent: Constants.safeTxGasBufferPercent,
            gasToken: gasToken,
            refundReceiver: refundReceiver
        )
    }
}

// MARK: - Constants

private extension CommonJointOperationParametersProvider {
    /// The figures the backend agreed on for the first release; it compares `baseGas` exactly and refuses a
    /// `gasPrice` below its own estimate with a 70% margin, so the price is doubled on this side. To be revisited
    /// on real operations, since a fee this generous shows large.
    enum Constants {
        static let baseGas = BigUInt(110_000)
        static let deployGas = BigUInt(300_000)
        static let gasPriceMarginPercent = BigUInt(100)
        static let safeTxGasBufferPercent = BigUInt(50)
    }
}
