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
    typealias EVMCollection = MoralisEVMNetworkResult.EVMNFTCollection
    typealias EVMAsset = MoralisEVMNetworkResult.EVMNFTAsset
    typealias EVMResponse = MoralisEVMNetworkResult.EVMNFTResponse

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
    ) async -> (value: [T], errors: [NFTErrorDescriptor]) where T: Decodable, T: MoralisPaginableResponse {
        var results: [T] = []
        var errors: [NFTErrorDescriptor] = []
        var cursor: String? = nil

        repeat {
            let target = targetFactory(cursor)

            do {
                let response = try await networkProvider
                    .asyncRequest(target)
                    .mapAPIResponse(T.self, using: decoder)

                results.append(response)
                cursor = response.cursor
            } catch {
                errors.append(
                    NFTErrorDescriptor(
                        code: error.networkErrorCodeOrNSErrorFallback,
                        description: error.localizedDescription
                    )
                )
            }

        } while cursor != nil

        return (results, errors: errors)
    }
}

// MARK: - NFTNetworkService protocol conformance

extension MoralisEVMNFTNetworkService: NFTNetworkService {
    public func getCollections(address: String) async -> NFTPartialResult<[NFTCollection]> {
        let moralisNFTChain: MoralisEVMNetworkParams.NFTChain

        do {
            moralisNFTChain = try makeMoralisNFTChain(from: chain)
        } catch {
            return makeEmptyResultWithErrorAndLog(error: error)
        }

        let loadedResponse: (value: [EVMResponse<[EVMCollection]>], errors: [NFTErrorDescriptor]) = await paginableRequest { cursor in
            MoralisEVMAPITarget(
                version: Constants.apiVersion,
                target: .getNFTCollectionsByWallet(
                    address: address,
                    params: .init(
                        chain: moralisNFTChain,
                        limit: Constants.pageSize,
                        cursor: cursor,
                        tokenCounts: true, // Moralis doesn't return the list of assets, so this option must be turned on
                        excludeSpam: true
                    )
                )
            )
        }

        let mapper = MoralisEVMNetworkMapper(chain: chain)
        let nftCollections = mapper.map(collections: loadedResponse.value.flatMap(\.result), ownerAddress: address)

        return NFTPartialResult(value: nftCollections, errors: loadedResponse.errors)
    }

    public func getAssets(address: String, in collection: NFTCollection) async -> NFTPartialResult<[NFTAsset]> {
        let moralisNFTChain: MoralisEVMNetworkParams.NFTChain

        do {
            moralisNFTChain = try makeMoralisNFTChain(from: chain)
        } catch {
            return makeEmptyResultWithErrorAndLog(error: error)
        }

        let loadedResponse: (value: [EVMResponse<[EVMAsset]>], errors: [NFTErrorDescriptor]) = await paginableRequest { cursor in
            MoralisEVMAPITarget(
                version: Constants.apiVersion,
                target: .getNFTAssetsByWallet(
                    address: address,
                    params: .init(
                        chain: moralisNFTChain,
                        format: .decimal,
                        limit: Constants.pageSize,
                        cursor: cursor,
                        excludeSpam: true,
                        tokenAddresses: nil,
                        normalizeMetadata: true,
                        mediaItems: true,
                        includePrices: nil
                    )
                )
            )
        }

        let response = loadedResponse
            .value
            .flatMap(\.result)
            .filter { asset in
                asset.tokenAddress == collection.id.collectionIdentifier
            }
        let mapper = MoralisEVMNetworkMapper(chain: chain)

        let assets = mapper.map(
            assets: response,
            ownerAddress: address,
            fallbackDescription: collection.description
        )

        let brokenAssetsCount = collection.assetsCount - assets.count
        let brokenAssetsError = brokenAssetsCount > 0
            ? NFTErrorDescriptor(code: 1, description: "Some assets are broken, count: \(brokenAssetsCount)")
            : nil

        return NFTPartialResult(
            value: assets,
            errors: loadedResponse.errors + [brokenAssetsError].compactMap { $0 }
        )
    }

    public func getAsset(assetIdentifier: NFTAsset.ID, in collection: NFTCollection) async throws -> NFTAsset? {
        let moralisNFTChain = try makeMoralisNFTChain(from: chain)

        let token = MoralisEVMNetworkParams.NFTAssetsBody.Token(
            tokenAddress: assetIdentifier.contractAddress,
            tokenId: assetIdentifier.identifier
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
            .first { $0.tokenAddress == assetIdentifier.contractAddress && $0.tokenId == assetIdentifier.identifier }
        let mapper = MoralisEVMNetworkMapper(chain: chain)

        return mapper.map(
            asset: response,
            ownerAddress: assetIdentifier.ownerAddress,
            fallbackDescription: collection.description
        )
    }

    public func getSalePrice(assetIdentifier: NFTAsset.ID) async throws -> NFTSalePrice? {
        let moralisNFTChain = try makeMoralisNFTChain(from: chain)

        let target = MoralisEVMAPITarget(
            version: Constants.apiVersion,
            target: .getNFTSalePrice(
                collectionAddress: assetIdentifier.contractAddress,
                tokenId: assetIdentifier.identifier,
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

// MARK: - Helpers

private extension MoralisEVMNFTNetworkService {
    func makeEmptyResultWithErrorAndLog<T: Equatable>(error: any Swift.Error) -> NFTPartialResult<[T]> {
        assertionFailure("\(String(describing: Self.self)) misused: \(chain) is not supported in this context")

        NFTLogger.error(error: error)

        return NFTPartialResult(
            value: [],
            errors: [
                NFTErrorDescriptor(code: error.networkErrorCodeOrNSErrorFallback, description: error.localizedDescription),
            ]
        )
    }
}

// MARK: - Auxiliary types

public extension MoralisEVMNFTNetworkService {
    enum Error: Swift.Error, LocalizedError {
        case unsupportedNFTChain(chain: NFTChain)
        case apiError(message: String)

        public var errorDescription: String? {
            switch self {
            case .unsupportedNFTChain(let chain):
                "Unsupported NFT chain: '\(chain)'"
            case .apiError(let message):
                message
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
