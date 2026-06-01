//
//  HederaFeeParams.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct HederaFeeParams: FeeParameters {
    /// UI only, this fee must be excluded when building transaction
    let additionalHBARFee: Decimal
    /// Runtime data needed to construct ERC20 transfer as ContractExecuteTransaction.
    let erc20TransferConfiguration: ERC20TransferConfiguration?

    init(additionalHBARFee: Decimal, erc20TransferConfiguration: ERC20TransferConfiguration?) {
        self.additionalHBARFee = additionalHBARFee
        self.erc20TransferConfiguration = erc20TransferConfiguration
    }
}

extension HederaFeeParams {
    struct ERC20TransferConfiguration {
        let recipientEVMAddress: String
        let gasLimit: UInt64
    }
}
