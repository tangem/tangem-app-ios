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
    public func getCollections(address: String) async throws -> NFTPartialResult<[NFTCollection]> {
        let apiTarget = MoralisSolanaAPITarget(
            target: .getNFTsByWallet(
                address: address,
                params: MoralisSolanaNetworkParams.NFTsByWallet(showNFTMetadata: true)
            )
        )

        let assets = try await provider.asyncRequest(apiTarget)
            .map([MoralisSolanaNetworkResult.Asset].self)

        let groupedAssets = Dictionary(grouping: assets, by: \.collection?.collectionAddress)
        let keys = assets.map(\.collection?.collectionAddress).unique()

        let collections = keys.map { key in
            let assets = groupedAssets[key, default: []]
            return mapper.map(collection: assets.first?.collection, assets: assets, ownerAddress: address)
        }

        return NFTPartialResult(value: collections, hasErrors: false)
    }

    public func getAssets(address: String, collectionIdentifier: NFTCollection.ID?) async throws -> NFTPartialResult<[NFTAsset]> {
        let loadedResponse = try await getCollections(address: address)

        let assets = if let collectionIdentifier {
            loadedResponse
                .value
                .first { $0.id == collectionIdentifier }?
                .assets ?? []
        } else {
            loadedResponse.value.flatMap(\.assets)
        }

        return NFTPartialResult(value: assets, hasErrors: false)
    }

    public func getAsset(assetIdentifier: NFTAsset.ID) async throws -> NFTAsset? {
        throw MoralisSolanaServiceError.unsupportedMethod("This method is not supported in Moralis' Solana API")
    }

    public func getSalePrice(assetIdentifier: NFTAsset.ID) async throws -> NFTSalePrice? {
        throw MoralisSolanaServiceError.unsupportedMethod("This method is not supported in Moralis' Solana API")
    }
}
