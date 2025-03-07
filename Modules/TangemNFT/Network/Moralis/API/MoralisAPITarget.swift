//
//  MoralisAPITarget.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct MoralisAPITarget {
    let version: Version
    let target: Target
}

// MARK: - Nested types

extension MoralisAPITarget {
    enum Target {
        /// https://docs.moralis.com/web3-data-api/evm/reference/get-wallet-nft-collections
        case getNFTCollectionsByWallet(address: String, params: MoralisNetworkParams.NFTCollectionsByWallet)

        /// https://docs.moralis.com/web3-data-api/evm/reference/get-wallet-nfts
        case getNFTAssetsByWallet(address: String, params: MoralisNetworkParams.NFTAssetsByWallet)

        /// https://docs.moralis.com/web3-data-api/evm/reference/get-multiple-nfts
        case getNFTAssets(queryParams: MoralisNetworkParams.NFTAssetsQuery?, bodyParams: MoralisNetworkParams.NFTAssetsBody)

        /// https://docs.moralis.com/web3-data-api/evm/reference/get-nft-sale-prices
        case getNFTSalePrice(address: String, tokenId: String, params: MoralisNetworkParams.NFTSalePrice)
    }

    enum Version {
        case v2_2

        fileprivate var asPathComponent: String {
            switch self {
            case .v2_2:
                return "v2.2"
            }
        }
    }
}

// MARK: - TargetType protocol conformance

extension MoralisAPITarget: TargetType {
    var baseURL: URL {
        return URL(string: "https://deep-index.moralis.io/api/\(version.asPathComponent)/")!
    }

    var path: String {
        switch target {
        case .getNFTCollectionsByWallet(let address, _):
            return "\(address)/nft/collections"
        case .getNFTAssetsByWallet(let address, _):
            return "\(address)/nft"
        case .getNFTAssets:
            return "nft/getMultipleNFTs"
        case .getNFTSalePrice(let address, let tokenId, _):
            return "nft/\(address)/\(tokenId)/price"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getNFTCollectionsByWallet,
             .getNFTAssetsByWallet,
             .getNFTSalePrice:
            return .get
        case .getNFTAssets:
            return .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .getNFTCollectionsByWallet(_, let params):
            return .requestParameters(params)
        case .getNFTAssetsByWallet(_, let params):
            return .requestParameters(params)
        case .getNFTAssets(let queryParams, let bodyParams):
            return .requestCompositeParameters(body: bodyParams, urlParameters: queryParams)
        case .getNFTSalePrice(_, _, let params):
            return .requestParameters(params)
        }
    }

    var headers: [String: String]? { nil }
}
