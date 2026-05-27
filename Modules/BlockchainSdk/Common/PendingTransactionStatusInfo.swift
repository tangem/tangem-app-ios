//
//  PendingTransactionStatusInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemMacro

struct PendingTransactionStatusInfo {
    let provider: NetworkProviderType?
    let status: Status

    init(provider: NetworkProviderType?, transaction: EthereumTransaction?) {
        self.provider = provider

        let status: PendingTransactionStatusInfo.Status = {
            guard let transaction else { return .dropped }
            return transaction.blockNumber == nil ? .pending : .executed
        }()

        self.status = status
    }
}

extension PendingTransactionStatusInfo {
    @CaseFlagable
    public enum Status {
        case pending
        case executed
        case dropped
    }
}
