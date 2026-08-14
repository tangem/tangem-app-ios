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
struct JointAccountCreationPayloadBuilder: JointAccountPayloadBuilder {
    let userWalletId: UserWalletId
    let creationContext: JointAccountCreationContext

    func makePayload(address: String, derivationIndex: Int) -> JointAccountCreationPayload {
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
                derivation: derivationIndex
            )
        )
    }
}
