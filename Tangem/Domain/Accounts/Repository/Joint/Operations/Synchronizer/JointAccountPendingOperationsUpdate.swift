//
//  JointAccountPendingOperationsUpdate.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum JointAccountPendingOperationsUpdate: Equatable {
    case operation(JointAccountOperation, cryptoAccountId: String)
    case operationRemoved(id: String, cryptoAccountId: String)
}
