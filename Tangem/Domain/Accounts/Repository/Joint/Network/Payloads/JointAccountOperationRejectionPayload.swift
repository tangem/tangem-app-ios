//
//  JointAccountOperationRejectionPayload.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// - Warning: Canonicalised and verified the same way `JointAccountCreationPayload` is. The wire type itself, unlike
/// the account payloads: what is signed has to be worded exactly as the endpoint holds it.
typealias JointAccountOperationRejectionPayload = JointAccountsDTO.Request.RejectOperationPayload
