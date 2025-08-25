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

    public init(
        networkConfiguration: TangemProviderConfiguration,
        headers: [APIHeaderKeyInfo]
    ) {
        self.networkConfiguration = networkConfiguration
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

        var resultCollections = [NFTCollection]()
        var requestError: NFTErrorDescriptor?

        do {
            let assets = try await provider.asyncRequest(apiTarget)
                .map([MoralisSolanaNetworkResult.Asset].self)

            let groupedAssets = Dictionary(
                grouping: assets,
                by: { makeAssetsGroupingKeys(from: $0.collection) }
            )

            let keys = assets
                .map { makeAssetsGroupingKeys(from: $0.collection) }
                .unique()

            let collections = keys.map { key in
                let assets = groupedAssets[key, default: []]
                return mapper.map(collection: assets.first?.collection, assets: assets, ownerAddress: address)
            }

            resultCollections.append(contentsOf: collections)
        } catch {
            requestError = NFTErrorDescriptor(
                code: error.networkErrorCodeOrNSErrorFallback,
                description: error.localizedDescription
            )
        }

        return NFTPartialResult(value: resultCollections, errors: [requestError].compactMap { $0 })
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
    func makeAssetsGroupingKeys(from collection: MoralisSolanaNetworkResult.Collection?) -> AssetsGroupingKey {
        AssetsGroupingKey(
            collectionAddress: collection?.collectionAddress,
            collectionName: collection?.name
        )
    }
}

// MARK: - Helpers

private extension MoralisSolanaNetworkService {
    struct AssetsGroupingKey: Hashable {
        let collectionAddress: String?
        let collectionName: String?
    }
}
