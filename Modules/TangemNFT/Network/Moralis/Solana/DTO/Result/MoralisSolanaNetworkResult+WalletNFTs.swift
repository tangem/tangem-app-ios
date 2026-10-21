//
//  MoralisSolanaNetworkResult+WalletNFTs.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension MoralisSolanaNetworkResult {
    struct WalletNFTsResponse: Decodable {
        let meta: WalletNFTsMeta?
        let cursor: String?
        let result: [WalletNFT]?
    }

    struct WalletNFTsMeta: Decodable {
        let failedChains: [WalletNFTsChainFailure]?
    }

    struct WalletNFTsChainFailure: Decodable {
        let chainId: String?
        let code: String?
        let error: String?
    }

    struct WalletNFT: Decodable {
        let tokenAddress: String?
        let tokenStandard: String?
        let name: String?
        let metadata: Metadata?
        let media: Media?
        let collection: WalletNFTCollection?
    }

    struct WalletNFTCollection: Decodable {
        let address: String?
        let name: String?
    }
}

extension MoralisSolanaNetworkResult.WalletNFT {
    struct Metadata: Decodable {
        let name: String?
        let description: String?
        let image: String?
        let animationUrl: String?
        let attributes: [MoralisSolanaNetworkResult.Attribute]?
    }

    struct Media: Decodable {
        let mimetype: String?
        let originalMediaUrl: String?
        let mediaCollection: MediaCollection?
    }

    struct MediaCollection: Decodable {
        let low: MediaSize?
        let medium: MediaSize?
        let high: MediaSize?
    }

    struct MediaSize: Decodable {
        let url: String?
    }
}
