//
//  MoralisSolanaAPITarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct MoralisSolanaAPITarget {
    let target: Target
}

// MARK: - Nested types

extension MoralisSolanaAPITarget {
    enum Target {
        /// https://docs.moralis.com/web3-data-api/solana/reference/get-sol-nfts?network=mainnet&address=kXB7FfzdrfZpAZEW3TZcp8a8CwQbsowa6BdfAHZ4gVs&nftMetadata=true
        case getNFTsByWallet(address: String, params: MoralisSolanaNetworkParams.NFTsByWallet)
    }
}

// MARK: - TargetType protocol conformance

extension MoralisSolanaAPITarget: TargetType {
    var baseURL: URL {
        return URL(string: "https://solana-gateway.moralis.io/")!
    }

    var path: String {
        switch target {
        case .getNFTsByWallet(let address, _):
            "account/mainnet/\(address)/nft"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getNFTsByWallet: .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .getNFTsByWallet(_, let params):
            .requestParameters(
                parameters: ["nftMetadata": params.showNFTMetadata],
                encoding: URLEncoding(destination: .queryString, boolEncoding: .literal)
            )
        }
    }

    var headers: [String: String]? { nil }
}
