//
//  JointAccountConfirmationPayload.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountConfirmationPayload: Codable, Equatable {
    let name: String
    let icon: String
    let iconColor: String
    let membersCount: Int
    let threshold: Int
    let safeAddress: String
}

extension JointAccountConfirmationPayload {
    init(config: JointAccountSignedConfig, safeAddress: String) {
        self.init(
            name: config.name,
            icon: config.icon,
            iconColor: config.iconColor,
            membersCount: config.membersCount,
            threshold: config.threshold,
            safeAddress: safeAddress.lowercased()
        )
    }
}
