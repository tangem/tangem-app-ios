//
//  NFTScanAPITarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils
import Moya

struct NFTScanAPITarget {
    let chain: NFTScanNetworkParams.NFTChain
    let target: Target

    private let encoding = URLEncoding(destination: .queryString, boolEncoding: .literal)
}

extension NFTScanAPITarget {
    enum Target {
        /// https://docs.nftscan.com/reference/solana/get-all-nfts-by-account
        case getNFTCollectionsByAddress(address: String, params: NFTScanNetworkParams.NFTCollectionsByAddress)

        /// https://docs.nftscan.com/reference/solana/get-single-nft
        case getNFTByTokenID(tokenID: String, params: NFTScanNetworkParams.NFTByTokenID)
    }
}

extension NFTScanAPITarget: TargetType {
    var baseURL: URL {
        chain.apiBasePath
    }

    var path: String {
        switch target {
        case .getNFTByTokenID(let tokenID, _):
            "assets/\(tokenID)"
        case .getNFTCollectionsByAddress(let address, _):
            "account/own/all/\(address)"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getNFTByTokenID, .getNFTCollectionsByAddress:
            .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .getNFTByTokenID(_, let params):
            .requestParameters(
                parameters: ["show_attribute": params.showAttribute],
                encoding: encoding
            )
        case .getNFTCollectionsByAddress(_, let params):
            .requestParameters(
                parameters: ["show_attribute": params.showAttribute],
                encoding: encoding
            )
        }
    }

    var headers: [String: String]? { nil }
}
