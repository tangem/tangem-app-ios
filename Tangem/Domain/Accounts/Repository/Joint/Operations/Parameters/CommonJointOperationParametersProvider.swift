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
            baseGas: JointOperationFeeConstants.baseGas,
            deployGas: JointOperationFeeConstants.deployGas,
            gasPriceMarginPercent: JointOperationFeeConstants.gasPriceMarginPercent,
            safeTxGasBufferPercent: JointOperationFeeConstants.safeTxGasBufferPercent,
            gasToken: gasToken,
            refundReceiver: JointOperationFeeConstants.refundReceiver
        )
    }
}
