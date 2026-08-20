//
//  CommonPolymarketRelayerService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

final class CommonPolymarketRelayerService {
    private let provider: TangemProvider<PolymarketRelayerTarget>
    private let baseURL: URL

    private let decoder = JSONDecoder()

    init(provider: TangemProvider<PolymarketRelayerTarget>, baseURL: URL) {
        self.provider = provider
        self.baseURL = baseURL
    }
}

// MARK: - PolymarketRelayerService protocol conformance

extension CommonPolymarketRelayerService: PolymarketRelayerService {
    func walletNonce(ownerAddress: String) async throws -> String {
        let target = PolymarketRelayerTarget(baseURL: baseURL, ownerAddress: ownerAddress)

        do {
            let response = try await provider.requestPublisher(target).async()
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            return try decoder.decode(PolymarketDTO.NonceResponse.self, from: filtered.data).nonce
        } catch let error as CancellationError {
            throw error
        } catch let error as MoyaError {
            throw CommonPolymarketAPIService.mapMoyaError(error, decoder: decoder)
        } catch {
            throw PolymarketAPIError.connection(underlying: error)
        }
    }
}
