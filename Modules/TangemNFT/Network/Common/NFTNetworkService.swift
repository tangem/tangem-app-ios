//
//  NFTNetworkService.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol NFTNetworkService {
    func getCollections(address: String) async -> NFTPartialResult<[NFTCollection]>
    func getAssets(address: String, in collection: NFTCollection) async -> NFTPartialResult<[NFTAsset]>
    func getAsset(assetIdentifier: NFTAsset.ID, in collection: NFTCollection) async throws -> NFTAsset?
    func getSalePrice(assetIdentifier: NFTAsset.ID) async throws -> NFTSalePrice?
}
