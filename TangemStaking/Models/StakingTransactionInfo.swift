//
//  StakingTransactionInfo.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public protocol StakingTransactionMetadata {
    var id: String { get }
}

public struct StakingTransactionInfo {
    public let network: String
    public let unsignedTransactionData: UnsignedTransactionData
    public let fee: Decimal
    public let metadata: StakingTransactionMetadata?

    public init(
        network: String,
        unsignedTransactionData: UnsignedTransactionData,
        fee: Decimal,
        metadata: StakingTransactionMetadata? = nil
    ) {
        self.network = network
        self.unsignedTransactionData = unsignedTransactionData
        self.fee = fee
        self.metadata = metadata
    }
}

extension StakingTransactionInfo: Hashable {
    public static func == (lhs: StakingTransactionInfo, rhs: StakingTransactionInfo) -> Bool {
        lhs.unsignedTransactionData == rhs.unsignedTransactionData && lhs.fee == rhs.fee
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(unsignedTransactionData)
        hasher.combine(fee)
    }
}
