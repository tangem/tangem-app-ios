//
//  JointOperationCancelReason.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum JointOperationCancelReason: String, Hashable, Codable {
    case initiator
    case threshold
}
