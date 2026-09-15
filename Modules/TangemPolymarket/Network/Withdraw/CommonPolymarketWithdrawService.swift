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
        let request = PolymarketWithdrawTarget(environment: environment(), walletId: walletId, target: target)

        do {
            let response = try await provider.requestPublisher(request).async()
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            return try decoder.decode(T.self, from: filtered.data)
        } catch is CancellationError {
            throw PolymarketWithdrawError.cancelled
        } catch let error as MoyaError {
            throw PolymarketWithdrawError(apiError: CommonPolymarketAPIService.mapMoyaError(error, decoder: decoder))
        } catch let error as DecodingError {
            throw PolymarketWithdrawError(apiError: .decoding(field: String(describing: T.self), value: "\(error)"))
        } catch {
            throw PolymarketWithdrawError(apiError: .connection(underlying: error))
        }
    }
}
