//
//  PolymarketPositionsValueService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

public protocol PolymarketPositionsValueService {
    func positionsValue(depositWalletAddress: String) async throws -> Decimal
}

final class CommonPolymarketPositionsValueService {
    private let provider: TangemProvider<PolymarketPositionsValueTarget>
    private let baseURL: URL

    private let decoder = JSONDecoder()

    init(provider: TangemProvider<PolymarketPositionsValueTarget>, baseURL: URL) {
        self.provider = provider
        self.baseURL = baseURL
    }
}

// MARK: - Response mapping

extension CommonPolymarketPositionsValueService {
    static func positionsValue(from response: [PolymarketDTO.PositionsValueResponse]) -> Decimal {
        response.first?.value ?? .zero
    }
}

// MARK: - PolymarketPositionsValueService protocol conformance

extension CommonPolymarketPositionsValueService: PolymarketPositionsValueService {
    func positionsValue(depositWalletAddress: String) async throws -> Decimal {
        let target = PolymarketPositionsValueTarget(baseURL: baseURL, depositWalletAddress: depositWalletAddress)

        do {
            let response = try await provider.requestPublisher(target).async()
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            let dto = try decoder.decode([PolymarketDTO.PositionsValueResponse].self, from: filtered.data)

            return Self.positionsValue(from: dto)
        } catch let error as CancellationError {
            throw error
        } catch let error as MoyaError {
            throw CommonPolymarketAPIService.mapMoyaError(error, decoder: decoder)
        } catch {
            throw PolymarketAPIError.connection(underlying: error)
        }
    }
}
