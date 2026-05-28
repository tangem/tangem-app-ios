//
//  TransactionHistoryNetworkService.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol TransactionHistoryNetworkService<Record>: Sendable {
    associatedtype Record: TransactionHistoryRecord

    /// - Parameter handleRecordsPage: Invoked once per fetched page — i.e. potentially many times during a single
    ///   sync — with that page's records. The returned ``TransactionHistoryNextPageAction`` decides whether
    ///   pagination continues and the cursor advances.
    func syncInitial(handleRecordsPage: @Sendable ([Record]) async -> TransactionHistoryNextPageAction) async throws

    /// - Parameter handleRecordsPage: Invoked once per fetched page — i.e. potentially many times during a single
    ///   sync — with that page's records. The returned ``TransactionHistoryNextPageAction`` decides whether
    ///   pagination continues and the cursor advances.
    func syncDelta(handleRecordsPage: @Sendable ([Record]) async -> TransactionHistoryNextPageAction) async throws
}
