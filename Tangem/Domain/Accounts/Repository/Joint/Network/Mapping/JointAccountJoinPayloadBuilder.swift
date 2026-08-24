//
//  JointAccountJoinPayloadBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Lays out what taking a slot of somebody else's joint account is asked with.
struct JointAccountJoinPayloadBuilder: JointAccountPayloadBuilder {
    let userWalletId: UserWalletId
    let inviteId: String
    let config: JointAccountSignedConfig
    let memberName: String

    func makePayload(address: String, derivationIndex: Int) -> JointAccountJoinPayload {
        return JointAccountJoinPayload(
            inviteId: inviteId,
            config: config,
            member: JointAccountSignedMember(
                walletId: userWalletId.stringValue,
                name: memberName,
                address: address,
                derivation: derivationIndex
            )
        )
    }
}
