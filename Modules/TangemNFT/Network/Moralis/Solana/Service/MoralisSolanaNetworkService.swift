//
//  MoralisSolanaNetworkService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

public final class MoralisSolanaNetworkService {
    private let networkConfiguration: TangemProviderConfiguration
    private let provider: TangemProvider<MoralisSolanaAPITarget>
    private let mapper: MoralisSolanaNetworkMapper
    private let isCoreAssetsLoadingEnabled: Bool
    private let decoder = JSONDecoder()

    public init(
        networkConfiguration: TangemProviderConfiguration,
        headers: [APIHeaderKeyInfo],
        isCoreAssetsLoadingEnabled: Bool
    ) {
        self.networkConfiguration = networkConfiguration
        self.isCoreAssetsLoadingEnabled = isCoreAssetsLoadingEnabled
        provider = TangemProvider(
            configuration: networkConfiguration,
            additionalPlugins: [
                NetworkHeadersPlugin(networkHeaders: headers),
            ]
        )
        mapper = MoralisSolanaNetworkMapper()
    }
}

// MARK: - NFTNetworkService protocol conformance

extension MoralisSolanaNetworkService: NFTNetworkService {
    public func getCollections(address: String) async -> NFTPartialResult<[NFTCollection]> {
        async let regularAssetsResult = loadRegularAssets(address: address)
        async let coreAssetsResult = loadCoreAssets(address: address)

        let regularAssets = await regularAssetsResult
        let coreAssets = await coreAssetsResult

        let collections = mapper.map(
            regularAssets: regularAssets.assets,
            coreAssets: coreAssets.assets,
            ownerAddress: address
        )

        return NFTPartialResult(value: collections, errors: regularAssets.errors + coreAssets.errors)
    }

    public func getAssets(address: String, in collection: NFTCollection) async -> NFTPartialResult<[NFTAsset]> {
        let loadedResponse = await getCollections(address: address)

        return loadedResponse
            .value
            .first { $0.id == collection.id }?
            .assetsResult ?? []
    }

    public func getAsset(assetIdentifier: NFTAsset.ID, in collection: NFTCollection) async throws -> NFTAsset? {
        throw MoralisSolanaServiceError.unsupportedMethod("This method is not supported in Moralis' Solana API")
    }

    public func getSalePrice(assetIdentifier: NFTAsset.ID) async throws -> NFTSalePrice? {
        throw MoralisSolanaServiceError.unsupportedMethod("This method is not supported in Moralis' Solana API")
    }
}

// MARK: - Private implementation

private extension MoralisSolanaNetworkService {
    func loadRegularAssets(address: String) async -> LoadedAssets<MoralisSolanaNetworkResult.Asset> {
        let apiTarget = MoralisSolanaAPITarget(
            target: .getNFTsByWallet(
                address: address,
                params: MoralisSolanaNetworkParams.NFTsByWallet(
                    nftMetadata: true,
                    mediaItems: nil,
                    excludeSpam: true
                )
            )
        )

        do {
            let assets = try await provider.asyncRequest(apiTarget)
                .map([MoralisSolanaNetworkResult.Asset].self)
            return LoadedAssets(assets: assets, errors: [])
        } catch {
            return LoadedAssets(assets: [], errors: [makeErrorDescriptor(from: error)])
        }
    }

    func loadCoreAssets(address: String) async -> LoadedAssets<MoralisSolanaNetworkResult.WalletNFT> {
        guard isCoreAssetsLoadingEnabled else {
            return LoadedAssets(assets: [], errors: [])
        }

        let pages = await MoralisCursorPaginator.loadAllPages { cursor in
            let apiTarget = MoralisSolanaAPITarget(
                target: .getNFTsByWalletEarlyAccess(
                    address: address,
                    params: MoralisSolanaNetworkParams.NFTsByWalletEarlyAccess(
                        chains: NFTChain.solana.id,
                        tokenStandards: Constants.coreTokenStandard,
                        limit: MoralisCursorPaginator.pageSize,
                        cursor: cursor,
                        excludeSpam: true,
                        includeMetadata: true,
                        includeMedia: true
                    )
                )
            )

            return try await provider.asyncRequest(apiTarget)
                .mapAPIResponse(MoralisSolanaNetworkResult.WalletNFTsResponse.self, using: decoder)
        }

        let chainErrors = pages.value
            .flatMap { $0.meta?.failedChains ?? [] }
            .map { makeErrorDescriptor(from: MoralisSolanaServiceError.chainFailed(code: $0.code, message: $0.error)) }

        let coreAssets = pages.value
            .flatMap { $0.result ?? [] }
            .filter { $0.tokenStandard == Constants.coreTokenStandard }

        return LoadedAssets(assets: coreAssets, errors: pages.errors + chainErrors)
    }

    func makeErrorDescriptor(from error: any Error) -> NFTErrorDescriptor {
        NFTErrorDescriptor(
            code: error.networkErrorCodeOrNSErrorFallback,
            description: error.localizedDescription
        )
    }
}

// MARK: - Auxiliary types

private extension MoralisSolanaNetworkService {
    struct LoadedAssets<Asset> {
        let assets: [Asset]
        let errors: [NFTErrorDescriptor]
    }
}

// MARK: - Constants

private extension MoralisSolanaNetworkService {
    enum Constants {
        static let coreTokenStandard = "MplCore"
    }
}
