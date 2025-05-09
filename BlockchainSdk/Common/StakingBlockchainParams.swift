//
//  StakingBlockchainParams.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct StakingBlockchainParams {
    private let blockchain: Blockchain

    public init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    public var isStakingAmountEditable: Bool {
        switch blockchain {
        case .cardano: false
        default: true
        }
    }

    public var stakingDeposit: UInt64 {
        switch blockchain {
        case .cardano: 2
        default: .zero
        }
    }

    public var stakingDepositAmount: UInt64 {
        stakingDeposit * blockchain.decimalValue.uint64Value
    }

    public var reservedFee: Decimal {
        switch blockchain {
        case .ton: Decimal(stringValue: "0.2")!
        default: .zero
        }
    }
}
