//
//  JointAccountsDTO.Create.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Create {
    struct Request: Encodable {
        /// - Warning: Sent exactly as the creator signed it. The endpoint canonicalises what arrives and checks the
        /// signature against the result, so nothing here may be re-shaped on the way out — which is why this is the very
        /// type that went through the signer rather than a second description of the same fields.
        let payload: JointAccountCreationPayload
        /// `0x` followed by 130 hex characters.
        let signature: String
    }

    /// The account as reading it would describe it, with the invites filled in.
    typealias Response = JointAccountsDTO.JointAccount
}
