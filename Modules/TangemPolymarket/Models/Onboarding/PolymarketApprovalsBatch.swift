//
//  PolymarketApprovalsBatch.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketApprovalsBatch: Hashable, Sendable {
    public let ownerAddress: String
    public let depositWalletAddress: String
    public let nonce: String
    public let deadline: String
    public let calls: [Call]
    public let signature: String

    public init(
        ownerAddress: String,
        depositWalletAddress: String,
        nonce: String,
        deadline: String,
        calls: [Call],
        signature: String
    ) {
        self.ownerAddress = ownerAddress
        self.depositWalletAddress = depositWalletAddress
        self.nonce = nonce
        self.deadline = deadline
        self.calls = calls
        self.signature = signature
    }
}

public extension PolymarketApprovalsBatch {
    struct Call: Hashable, Sendable {
        public let target: String
        public let data: String
        public let value = "0"

        public init(target: String, data: String) {
            self.target = target
            self.data = data
        }
    }
}
