//
//  CommonPolymarketRedeemService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

final class CommonPolymarketRedeemService {
    private let provider: TangemProvider<PolymarketRedeemTarget>
    private let environment: () -> PolymarketBFFEnvironment
    private let walletId: String

    private let decoder = JSONDecoder()
    private let mapper = PolymarketMapper()

    init(
        provider: TangemProvider<PolymarketRedeemTarget>,
        environment: @escaping () -> PolymarketBFFEnvironment,
        walletId: String
    ) {
        self.provider = provider
        self.environment = environment
        self.walletId = walletId
    }
}

// MARK: - PolymarketRedeemService protocol conformance

extension CommonPolymarketRedeemService: PolymarketRedeemService {
    func calls(for request: PolymarketRedeemCallRequest) async throws(PolymarketRedeemError) -> [PolymarketRelayedBatch.Call] {
        let response: PolymarketDTO.RedeemCallResponse

        do {
            response = try await self.request(.call(conditionId: request.conditionId, isNegRisk: request.isNegRisk))
        } catch {
            throw PolymarketRedeemError.forRedeemCall(error)
        }

        return try mapper.mapRedeemCalls(response, request: request)
    }

    func submit(_ batch: PolymarketRelayedBatch) async throws(PolymarketRedeemError) -> PolymarketRedeemRecord {
        let response: PolymarketDTO.RedeemRecordResponse = try await request(
            .submit(PolymarketDTO.RelayedBatchRequest(batch: batch))
        )

        return mapper.mapRedeemRecord(response)
    }

    func record(ofClaim transactionId: String) async throws(PolymarketRedeemError) -> PolymarketRedeemRecord {
        let response: PolymarketDTO.RedeemRecordResponse = try await request(.record(transactionId: transactionId))

        return mapper.mapRedeemRecord(response)
    }
}

// MARK: - Private implementation

private extension CommonPolymarketRedeemService {
    func request<T: Decodable>(_ target: PolymarketRedeemTarget.Target) async throws(PolymarketRedeemError) -> T {
        try await PolymarketRelayedRequest.perform(
            PolymarketRedeemTarget(environment: environment(), walletId: walletId, target: target),
            provider: provider,
            decoder: decoder,
            failure: PolymarketRedeemError.self
        )
    }
}
