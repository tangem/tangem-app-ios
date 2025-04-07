//
//  MoralisNFTNetworkService.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

// [REDACTED_TODO_COMMENT]
public final class MoralisNFTNetworkService {
    private let networkConfiguration: TangemProviderConfiguration
    private let headers: NetworkHeaders
    private let chain: NFTChain

    public init(
        networkConfiguration: TangemProviderConfiguration,
        headers: NetworkHeaders,
        chain: NFTChain
    ) {
        self.networkConfiguration = networkConfiguration
        self.headers = headers
        self.chain = chain
    }
}

// MARK: - NFTNetworkService protocol conformance

extension MoralisNFTNetworkService: NFTNetworkService {
    public func getCollections(address: String) async throws -> [NFTCollection] {
        fatalError("\(#function) not implemented")
    }

    public func getAssets(address: String, collectionIdentifier: NFTCollection.ID?) async throws -> [NFTAsset] {
        fatalError("\(#function) not implemented")
    }

    public func getAsset(assetIdentifier: NFTAsset.ID) async throws -> NFTAsset? {
        fatalError("\(#function) not implemented")
    }

    public func getSalePrice(assetIdentifier: NFTAsset.ID, collectionIdentifier: NFTCollection.ID?) async throws -> NFTSalePrice? {
        fatalError("\(#function) not implemented")
    }
}
