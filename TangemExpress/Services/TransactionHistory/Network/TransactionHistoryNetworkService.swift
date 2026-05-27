//
//  TransactionHistoryNetworkService.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol TransactionHistoryNetworkService: Sendable {
    func syncInitial() async throws
    func syncDelta() async throws
}
