//
//  JointAccountCreationPayloadBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Lays out what creating a joint account is asked with.
struct JointAccountCreationPayloadBuilder {
    let userWalletId: UserWalletId
    let config: JointAccountCreationConfig

    /// - Parameter address: Only exists once the creator's key is derived, which is why it arrives apart from
    /// everything else the payload is made of.
    func makePayload(address: String) -> JointAccountCreationPayload {
        let creationContext = config.creationContext

        return JointAccountCreationPayload(
            config: JointAccountCreationPayload.Config(
                name: creationContext.name,
                icon: creationContext.icon.name.rawValue,
                iconColor: creationContext.icon.color.rawValue,
                membersCount: creationContext.membersCount,
                threshold: creationContext.signersCount
            ),
            creator: JointAccountCreationPayload.Creator(
                walletId: userWalletId.stringValue,
                name: creationContext.creatorName,
                address: address,
                derivation: config.derivationIndex
            )
        )
    }
}
