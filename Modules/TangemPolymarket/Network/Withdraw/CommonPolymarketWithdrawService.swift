//
//  CommonPolymarketWithdrawService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

final class CommonPolymarketWithdrawService {
    private let provider: TangemProvider<PolymarketWithdrawTarget>
    private let environment: () -> PolymarketBFFEnvironment
    private let walletId: String

    private let decoder = JSONDecoder()
    private let mapper = PolymarketMapper()

    init(
        provider: TangemProvider<PolymarketWithdrawTarget>,
        environment: @escaping () -> PolymarketBFFEnvironment,
        walletId: String
    ) {
        self.provider = provider
        self.environment = environment
        self.walletId = walletId
    }
}

// MARK: - PolymarketWithdrawService protocol conformance

extension CommonPolymarketWithdrawService: PolymarketWithdrawService {
    func submit(_ batch: PolymarketRelayedBatch) async throws(PolymarketWithdrawError) -> PolymarketWithdrawRecord {
        let response: PolymarketDTO.WithdrawRecordResponse = try await request(
            .submit(PolymarketDTO.RelayedBatchRequest(batch: batch))
        )

        return mapper.mapWithdrawRecord(response)
    }

    func record(ofWithdrawal transactionId: String) async throws(PolymarketWithdrawError) -> PolymarketWithdrawRecord {
        let response: PolymarketDTO.WithdrawRecordResponse = try await request(.record(transactionId: transactionId))

        return mapper.mapWithdrawRecord(response)
    }
}

// MARK: - Private implementation

private extension CommonPolymarketWithdrawService {
    func request<T: Decodable>(_ target: PolymarketWithdrawTarget.Target) async throws(PolymarketWithdrawError) -> T {
        try await PolymarketRelayedRequest.perform(
            PolymarketWithdrawTarget(environment: environment(), walletId: walletId, target: target),
            provider: provider,
            decoder: decoder,
            failure: PolymarketWithdrawError.self
        )
    }
}
