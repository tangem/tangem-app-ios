//
//  JointAccountModelDelegate.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A joint account is built on a crypto account, so whoever answers for the one answers for the other as well.
protocol JointAccountModelDelegate: CommonCryptoAccountModelDelegate {
    func activateJointAccount(with config: JointAccountActivationConfig) async throws(AccountEditError)
}
