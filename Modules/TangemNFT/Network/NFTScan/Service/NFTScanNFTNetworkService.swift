//
//  NFTScanNFTNetworkService.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

public final class NFTScanNFTNetworkService {
    private let networkConfiguration: TangemProviderConfiguration
    private let provider: TangemProvider<NFTScanAPITarget>
    private let chain: NFTChain
    private let mapper: NFTScanNetworkMapper

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    public init(
        networkConfiguration: TangemProviderConfiguration,
        headers: [APIHeaderKeyInfo],
        chain: NFTChain
    ) {
        self.networkConfiguration = networkConfiguration
        let additionalPlugins: [PluginType] = [
            NetworkHeadersPlugin(networkHeaders: headers),
        ]
        provider = TangemProvider(
            configuration: networkConfiguration,
            additionalPlugins: additionalPlugins
        )
        self.chain = chain
        mapper = NFTScanNetworkMapper()
    }
}

// MARK: - NFTNetworkService protocol conformance

extension NFTScanNFTNetworkService: NFTNetworkService {
    public func getCollections(address: String) async throws -> [NFTCollection] {
        let apiTarget = NFTScanAPITarget(
            chain: chain,
            target: .getNFTCollectionsByAddress(
                address: address,
                params: NFTScanNetworkParams.NFTCollectionsByAddress(showAttribute: true)
            )
        )
        let response = try await provider.asyncRequest(apiTarget)
            .map(NFTScanNetworkResult.Response<[NFTScanNetworkResult.Collection]>.self, using: decoder)

        return try response.data?.compactMap {
            try mapper.mapCollection($0, chain: chain, ownerAddress: address)
        } ?? []
    }

    public func getAssets(address: String, collectionIdentifier: NFTCollection.ID?) async throws -> [NFTAsset] {
        try await getCollections(address: address)
            .filter {
                collectionIdentifier != nil ? $0.id.collectionIdentifier == collectionIdentifier?.collectionIdentifier : true
            }
            .flatMap(\.assets)
    }

    public func getAsset(assetIdentifier: NFTAsset.ID) async throws -> NFTAsset? {
        guard let assetDTO = try? await getAssetDTO(for: assetIdentifier) else {
            return nil
        }

        return mapper.mapAsset(assetDTO, chain: chain)
    }

    public func getSalePrice(assetIdentifier: NFTAsset.ID) async throws -> NFTSalePrice? {
        guard let asset = try? await getAssetDTO(for: assetIdentifier) else {
            return nil
        }

        return mapper.mapSalePrice(for: asset)
    }

    private func getAssetDTO(for assetIdentifier: NFTAsset.ID) async throws -> NFTScanNetworkResult.Asset? {
        let apiTarget = NFTScanAPITarget(
            chain: chain,
            target: .getNFTByTokenID(
                tokenID: assetIdentifier.assetIdentifier,
                params: NFTScanNetworkParams.NFTByTokenID(showAttribute: true)
            )
        )

        return try await provider.asyncRequest(apiTarget)
            .map(NFTScanNetworkResult.Response<NFTScanNetworkResult.Asset>.self, using: decoder)
            .data
    }
}
