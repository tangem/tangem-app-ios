//
//  JointAccountActivationPayload.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// - Warning: Canonicalised and verified the same way `JointAccountCreationPayload` is.
struct JointAccountActivationPayload: Codable, Equatable {
    /// What the creator confirms: the settings the account was made with, plus the address they add up to. The address
    /// does not exist until the last slot is taken, which is why it has no place in the settings themselves.
    struct Config: Codable, Equatable {
        let name: String
        let icon: String
        let iconColor: String
        let membersCount: Int
        let threshold: Int
        let safeAddress: String
    }

    let walletId: String
    /// Which of this wallet's accounts is being activated.
    let cryptoAccountId: String
    let config: Config
}

// MARK: - Convenience

extension JointAccountActivationPayload.Config {
    init(config: JointAccountSignedConfig, safeAddress: String) {
        self.init(
            name: config.name,
            icon: config.icon,
            iconColor: config.iconColor,
            membersCount: config.membersCount,
            threshold: config.threshold,
            safeAddress: safeAddress
        )
    }
}
