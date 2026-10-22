//
//  JointAccountsDTO.Request.OperationsHistory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Request {
    struct OperationsHistory: Encodable {
        let afterCursor: String?
        let limit: Int
    }

    struct OperationsHistoryDelta: Encodable {
        let beforeCursor: String?
        let limit: Int
    }
}
