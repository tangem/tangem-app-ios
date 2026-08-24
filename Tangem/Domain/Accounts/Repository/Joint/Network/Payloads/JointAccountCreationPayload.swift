//
//  JointAccountCreationPayload.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// - Warning: The endpoint canonicalises this exactly as it arrives and verifies the signature over the result, so
/// neither the field names, nor the way they nest, nor the way they are encoded can change without agreeing it with
/// the backend.
struct JointAccountCreationPayload: Codable, Equatable {
    let config: JointAccountSignedConfig
    let creator: JointAccountSignedMember
}
