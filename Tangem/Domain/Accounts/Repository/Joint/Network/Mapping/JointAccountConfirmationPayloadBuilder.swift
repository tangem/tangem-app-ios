//
//  JointAccountConfirmationPayloadBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountConfirmationPayloadBuilder: JointAccountPayloadBuilder {
    let config: JointAccountSignedConfig
    let safeAddress: String

    func makePayload(address _: String, derivationIndex _: Int) -> JointAccountConfirmationPayload {
        JointAccountConfirmationPayload(config: config, safeAddress: safeAddress)
    }
}
