//
//  MoralisNFTNetworkService.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

public final class MoralisEVMNFTNetworkService {
    private let networkConfiguration: TangemProviderConfiguration
    private let chain: NFTChain
    private let networkProvider: TangemProvider<MoralisEVMAPITarget>

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
        self.chain = chain

        let additionalPlugins: [PluginType] = [
            NetworkHeadersPlugin(networkHeaders: headers),
        ]
        networkProvider = TangemProvider(configuration: networkConfiguration, additionalPlugins: additionalPlugins)
    }

    private func makeMoralisNFTChain(from nftChain: NFTChain) throws -> MoralisEVMNetworkParams.NFTChain {
        switch nftChain {
        case .ethereum(let isTestnet):
            return isTestnet ? .sepolia : .eth
        case .polygon(let isTestnet):
            return .polygon(isAmoy: isTestnet)
        case .bsc(let isTestnet):
            return .bsc(isTestnet: isTestnet)
        case .avalanche:
            return .avalanche
        case .fantom:
            return .fantom
        case .cronos:
            return .cronos
        case .arbitrum:
            return .arbitrum
        case .gnosis(let isTestnet):
            return .gnosis(isTestnet: isTestnet)
        case .chiliz(let isTestnet):
            return .chiliz(isTestnet: isTestnet)
        case .base(let isTestnet):
            return .base(isSepolia: isTestnet)
        case .optimism:
            return .optimism
        case .moonbeam(let isTestnet):
            return isTestnet ? .moonbase : .moonbeam
        case .moonriver:
            return .moonriver
        case .solana,
             .linea,
             .flow,
             .ronin,
             .lisk,
             .btc,
             .aptos,
             .ton:
            throw Error.unsupportedNFTChain(chain: nftChain)
        }
    }

    private func paginableRequest<T>(
        targetFactory: MoralisPaginableResponse.TargetFactory
    ) async throws -> [T] where T: Decodable, T: MoralisPaginableResponse {
        func executeRequest(targetFactory: MoralisPaginableResponse.TargetFactory, cursor: String?) async throws -> [T] {
            let target = targetFactory(cursor)
            let response = try await networkProvider
                .asyncRequest(target)
                .mapAPIResponse(T.self, using: decoder)

            guard let nextCursor = response.cursor else {
                return [response]
            }

            let nextResponse: [T] = try await executeRequest(targetFactory: targetFactory, cursor: nextCursor)

            return [response] + nextResponse
        }

        return try await executeRequest(targetFactory: targetFactory, cursor: nil)
    }
}

// MARK: - NFTNetworkService protocol conformance

extension MoralisEVMNFTNetworkService: NFTNetworkService {
    public func getCollections(address: String) async throws -> [NFTCollection] {
        let moralisNFTChain = try makeMoralisNFTChain(from: chain)

        let paginatedResponse: [MoralisEVMNetworkResult.EVMNFTResponse<[MoralisEVMNetworkResult.EVMNFTCollection]>] = try await paginableRequest { cursor in
            return MoralisEVMAPITarget(
                version: Constants.apiVersion,
                target: .getNFTCollectionsByWallet(
                    address: address,
                    params: .init(
                        chain: moralisNFTChain,
                        limit: Constants.pageSize,
                        cursor: cursor,
                        tokenCounts: true, // Moralis doesn't return the list of assets, so this option must be turned on
                        excludeSpam: nil
                    )
                )
            )
        }

        let response = paginatedResponse.flatMap(\.result)
        let mapper = MoralisEVMNetworkMapper(chain: chain)

        return mapper.map(collections: response, ownerAddress: address)
    }

    public func getAssets(address: String, collectionIdentifier: NFTCollection.ID?) async throws -> [NFTAsset] {
        let moralisNFTChain = try makeMoralisNFTChain(from: chain)

        let paginatedResponse: [MoralisEVMNetworkResult.EVMNFTResponse<[MoralisEVMNetworkResult.EVMNFTAsset]>] = try await paginableRequest { cursor in
            return MoralisEVMAPITarget(
                version: Constants.apiVersion,
                target: .getNFTAssetsByWallet(
                    address: address,
                    params: .init(
                        chain: moralisNFTChain,
                        format: .decimal,
                        limit: Constants.pageSize,
                        cursor: cursor,
                        excludeSpam: nil,
                        tokenAddresses: nil,
                        normalizeMetadata: true,
                        mediaItems: true,
                        includePrices: nil
                    )
                )
            )
        }

        let response = paginatedResponse
            .flatMap(\.result)
            .filter { asset in
                guard let collectionIdentifier else {
                    return true
                }
                return asset.tokenAddress == collectionIdentifier.collectionIdentifier
            }
        let mapper = MoralisEVMNetworkMapper(chain: chain)

        return mapper.map(assets: response, ownerAddress: address)
    }

    public func getAsset(assetIdentifier: NFTAsset.ID) async throws -> NFTAsset? {
        guard let collectionAddress = assetIdentifier.collectionIdentifier else {
            throw Error.missingCollectionAddress(assetId: assetIdentifier)
        }

        let moralisNFTChain = try makeMoralisNFTChain(from: chain)

        let token = MoralisEVMNetworkParams.NFTAssetsBody.Token(
            tokenAddress: collectionAddress,
            tokenId: assetIdentifier.assetIdentifier
        )

        let target = MoralisEVMAPITarget(
            version: Constants.apiVersion,
            target: .getNFTAssets(
                queryParams: .init(chain: moralisNFTChain),
                bodyParams: .init(
                    tokens: [token],
                    normalizeMetadata: true,
                    mediaItems: true
                )
            )
        )

        let response = try await networkProvider
            .asyncRequest(target)
            .mapAPIResponse([MoralisEVMNetworkResult.EVMNFTAsset].self, using: decoder)
            .first { $0.tokenAddress == assetIdentifier.collectionIdentifier && $0.tokenId == assetIdentifier.assetIdentifier }
        let mapper = MoralisEVMNetworkMapper(chain: chain)

        return mapper.map(asset: response, ownerAddress: assetIdentifier.ownerAddress)
    }

    public func getSalePrice(assetIdentifier: NFTAsset.ID) async throws -> NFTSalePrice? {
        guard let collectionAddress = assetIdentifier.collectionIdentifier else {
            throw Error.missingCollectionAddress(assetId: assetIdentifier)
        }

        let moralisNFTChain = try makeMoralisNFTChain(from: chain)

        let target = MoralisEVMAPITarget(
            version: Constants.apiVersion,
            target: .getNFTSalePrice(
                collectionAddress: collectionAddress,
                tokenId: assetIdentifier.assetIdentifier,
                params: .init(
                    chain: moralisNFTChain,
                    days: Constants.salePriceHistoryDuration
                )
            )
        )

        let response = try await networkProvider
            .asyncRequest(target)
            .mapAPIResponse(MoralisEVMNetworkResult.EVMNFTPrices.self, using: decoder)
        let mapper = MoralisEVMNetworkMapper(chain: chain)

        return mapper.map(prices: response)
    }
}

// MARK: - Auxiliary types

public extension MoralisEVMNFTNetworkService {
    enum Error: Swift.Error, LocalizedError {
        case unsupportedNFTChain(chain: NFTChain)
        case apiError(message: String)
        case missingCollectionAddress(assetId: NFTAsset.ID)

        public var errorDescription: String? {
            switch self {
            case .unsupportedNFTChain(let chain):
                return "Unsupported NFT chain: '\(chain)'"
            case .apiError(let message):
                return message
            case .missingCollectionAddress(let assetId):
                return "Missing collectionId for \(assetId)"
            }
        }
    }
}

// MARK: - Constants

private extension MoralisEVMNFTNetworkService {
    enum Constants {
        static let apiVersion: MoralisEVMAPITarget.Version = .v2_2
        static let pageSize = 100
        /// In days.
        static let salePriceHistoryDuration = 365
    }
}
