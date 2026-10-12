//
//  JointAccountsDTO.Request.SignedRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Request {
    /// Every joint-accounts request is one and the same shape: the payload a member signed and the signature itself.
    struct SignedRequest<Payload: Encodable>: Encodable {
        /// - Warning: Encoded exactly as the signer left it — see `JointAccountSignedBlob`.
        let payload: Payload
        /// `0x` followed by 130 hex characters.
        let signature: String
    }

    typealias Create = SignedRequest<JointAccountCreationPayload>
    typealias Join = SignedRequest<JointAccountJoinPayload>
    typealias Activate = SignedRequest<JointAccountActivationPayload>
}
