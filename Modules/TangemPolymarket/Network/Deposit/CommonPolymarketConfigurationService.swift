//
//  CommonPolymarketConfigurationService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

final class CommonPolymarketConfigurationService {
    private let provider: TangemProvider<PolymarketConfigurationTarget>
    private let environment: () -> PolymarketBFFEnvironment
    private let walletId: String
    private let store: PolymarketBuilderCodeStore

    private let decoder = JSONDecoder()

    init(
        provider: TangemProvider<PolymarketConfigurationTarget>,
        environment: @escaping () -> PolymarketBFFEnvironment,
        walletId: String,
        store: PolymarketBuilderCodeStore
    ) {
        self.provider = provider
        self.environment = environment
        self.walletId = walletId
        self.store = store
    }
}

// MARK: - PolymarketConfigurationService protocol conformance

extension CommonPolymarketConfigurationService: PolymarketConfigurationService {
    func builderCode() async throws -> String {
        let environment = environment()

        if let cached = store.code(forHost: environment.baseURL) {
            return cached
        }

        let response = try await requestConfiguration(in: environment)

        guard PolymarketBuilderCode.isWellFormed(response.builderCode) else {
            throw PolymarketAPIError.decoding(field: PolymarketBuilderCode.field, value: response.builderCode)
        }

        store.store(response.builderCode, forHost: environment.baseURL)

        return response.builderCode
    }
}

// MARK: - Private implementation

private extension CommonPolymarketConfigurationService {
    func requestConfiguration(
        in environment: PolymarketBFFEnvironment
    ) async throws -> PolymarketDTO.ConfigurationResponse {
        let target = PolymarketConfigurationTarget(environment: environment, walletId: walletId)

        do {
            let response = try await provider.requestPublisher(target).async()
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            return try decoder.decode(PolymarketDTO.ConfigurationResponse.self, from: filtered.data)
        } catch let error as CancellationError {
            throw error
        } catch let error as MoyaError {
            throw CommonPolymarketAPIService.mapMoyaError(error, decoder: decoder)
        } catch {
            throw PolymarketAPIError.connection(underlying: error)
        }
    }
}
