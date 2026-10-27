//
//  JointAccountsDTO.Response.OperationsHistory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension JointAccountsDTO.Response {
    struct OperationsHistory: Decodable {
        struct Pagination: Decodable {
            let endCursor: String?
            let startDeltaCursor: String?
            let hasMore: Bool
        }

        @LossyArray private(set) var items: [JointAccountsDTO.Response.HistoryOperation]
        let pagination: Pagination
    }

    struct OperationsHistoryDelta: Decodable {
        struct Pagination: Decodable {
            let startCursor: String?
            let hasMore: Bool
        }

        @LossyArray private(set) var items: [JointAccountsDTO.Response.HistoryOperation]
        let pagination: Pagination
    }
}
