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

struct CommonJointOperationParametersProvider {}

// MARK: - JointOperationParametersProvider

extension CommonJointOperationParametersProvider: JointOperationParametersProvider {
    func makeParameters(gasToken: SafeGasToken) async throws -> SafeOperationParameters {
        SafeOperationParameters(
            baseGas: Constants.baseGas,
            deployGas: Constants.deployGas,
            gasPriceMarginPercent: Constants.gasPriceMarginPercent,
            safeTxGasBufferPercent: Constants.safeTxGasBufferPercent,
            gasToken: gasToken,
            refundReceiver: refundReceiver
        )
    }

    private var refundReceiver: String {
        switch FeatureStorage.instance.tangemAPIType {
        case .prod:
            return Constants.prodRefundReceiver
        case .dev, .stage, .mock:
            return Constants.devRefundReceiver
        }
    }
}

// MARK: - Constants

private extension CommonJointOperationParametersProvider {
    /// The figures the backend agreed on for the first release; it compares `baseGas` exactly and refuses a
    /// `gasPrice` below its own estimate with a 70% margin, so the price is doubled on this side. To be revisited
    /// on real operations, since a fee this generous shows large.
    enum Constants {
        /// The joint relayer's treasury, which the endpoint compares the field against exactly. It is not the one the
        /// gasless relayer is refunded to — the two are different services with different wallets.
        static let prodRefundReceiver = "0x2fD66Abd3BFeffA81851A9C61c10E979369A031c"
        static let devRefundReceiver = "0x5F2C435DF8D00D0cF842a52Dd166B1Dcd69734C2"
        static let baseGas = BigUInt(110_000)
        static let deployGas = BigUInt(300_000)
        static let gasPriceMarginPercent = BigUInt(100)
        static let safeTxGasBufferPercent = BigUInt(50)
    }
}
