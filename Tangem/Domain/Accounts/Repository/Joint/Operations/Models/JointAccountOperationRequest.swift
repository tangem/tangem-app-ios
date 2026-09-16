//
//  JointAccountOperationRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// What creating an operation is asked with: the transaction and the initiator's EIP-712 signature over it.
struct JointAccountOperationRequest: Hashable {
    let safeAddress: String
    let chainId: Int
    let safeTransaction: SafeTransaction
    /// `r ‖ s ‖ v`, 65 bytes, the form the Safe checks.
    let signature: Data
}
