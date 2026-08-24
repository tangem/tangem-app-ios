//
//  JointAccountActivationPayloadBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Lays out what confirming a joint account's composition is asked with.
struct JointAccountActivationPayloadBuilder: JointAccountPayloadBuilder {
    let userWalletId: UserWalletId
    let cryptoAccountId: String
    let config: JointAccountSignedConfig
    let safeAddress: String

    func makePayload(address _: String, derivationIndex _: Int) -> JointAccountActivationPayload {
        JointAccountActivationPayload(
            walletId: userWalletId.stringValue,
            cryptoAccountId: cryptoAccountId,
            config: JointAccountActivationPayload.Config(config: config, safeAddress: safeAddress)
        )
    }
}
