//
//  JointOperationFetchResult.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum JointOperationFetchResult: Hashable {
    case modified(JointOperationHistoryItem, eTag: String?)
    case notModified
}
