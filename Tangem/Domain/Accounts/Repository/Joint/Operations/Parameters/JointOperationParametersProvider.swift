//
//  JointOperationParametersProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// The terms the backend validates an operation's gas against; kept behind one provider because every one of them is
/// expected to move to the backend's config.
protocol JointOperationParametersProvider {
    func makeParameters(gasToken: SafeGasToken) async throws -> SafeOperationParameters
}
