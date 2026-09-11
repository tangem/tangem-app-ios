//
//  JointAccountSignedBlob.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// What every request a joint account is changed by carries.
struct JointAccountSignedBlob<Payload: Encodable> {
    /// - Warning: Sent exactly as it was signed. The endpoint canonicalises what arrives and verifies the signature
    /// against the result, so nothing here may be re-shaped on the way out — which is why this is the very object that
    /// went through the signer rather than a second description of the same fields.
    let payload: Payload
    /// - Warning: The bytes that were signed are not sent, so this side's canonical form has to match the endpoint's
    /// on its own.
    let signature: Data
}

typealias JointAccountCreationBlob = JointAccountSignedBlob<JointAccountCreationPayload>
typealias JointAccountJoinBlob = JointAccountSignedBlob<JointAccountJoinPayload>
typealias JointAccountActivationBlob = JointAccountSignedBlob<JointAccountActivationPayload>
