//
//  NFTNetworkService.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
public protocol NFTNetworkService {
    func getCollections(address: String) async throws -> [NFTCollection]
    func getAssets(address: String, collectionIdentifier: NFTCollection.ID?) async throws -> [NFTAsset]
    func getAsset(assetIdentifier: NFTAsset.ID) async throws -> NFTAsset?
    func getSalePrice(assetIdentifier: NFTAsset.ID, collectionIdentifier: NFTCollection.ID?) async throws -> NFTSalePrice?
}
