//
//  CommonPolymarketBridgeService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation
import TangemNetworkUtils

final class CommonPolymarketBridgeService {
    private let provider: TangemProvider<PolymarketBridgeTarget>
    private let baseURL: URL
    private let supportedAssetsStore: PolymarketSupportedAssetsStore

    private let decoder = JSONDecoder()
    private let mapper = PolymarketMapper()

    init(
        provider: TangemProvider<PolymarketBridgeTarget>,
        baseURL: URL,
        supportedAssetsStore: PolymarketSupportedAssetsStore
    ) {
        self.provider = provider
        self.baseURL = baseURL
        self.supportedAssetsStore = supportedAssetsStore
    }
}

// MARK: - PolymarketBridgeService protocol conformance

extension CommonPolymarketBridgeService: PolymarketBridgeService {
    func supportedAssets() async throws -> [PolymarketSupportedAsset] {
        if let cached = supportedAssetsStore.cachedAssets() {
            return cached
        }

        let response: PolymarketDTO.SupportedAssetsResponse = try await request(.supportedAssets)
        let assets = mapper.mapSupportedAssets(response)

        guard !assets.isEmpty else {
            PolymarketLogger.warning("The bridge returned no assets this build can address, not caching the empty answer")
            return assets
        }

        supportedAssetsStore.store(assets)

        return assets
    }

    func fundingAddresses(
        forDepositWallet depositWalletAddress: String,
        builderCode: String
    ) async throws -> PolymarketBridgeAddresses {
        let payload = PolymarketDTO.DepositRequest(address: depositWalletAddress)

        let response: PolymarketDTO.FundingAddressesResponse = try await request(
            .fundingAddresses(payload, builderCode: builderCode)
        )

        return mapper.mapBridgeAddresses(response)
    }
}

// MARK: - Private implementation

private extension CommonPolymarketBridgeService {
    func request<T: Decodable>(_ target: PolymarketBridgeTarget.Target) async throws -> T {
        let request = PolymarketBridgeTarget(baseURL: baseURL, target: target)

        do {
            let response = try await provider.requestPublisher(request).async()
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            return try decoder.decode(T.self, from: filtered.data)
        } catch let error as CancellationError {
            throw error
        } catch let error as MoyaError {
            throw CommonPolymarketAPIService.mapMoyaError(error, decoder: decoder)
        } catch {
            throw PolymarketAPIError.connection(underlying: error)
        }
    }
}
