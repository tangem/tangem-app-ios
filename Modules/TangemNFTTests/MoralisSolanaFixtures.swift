//
//  MoralisSolanaFixtures.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import TangemNFT

enum MoralisSolanaFixtures {
    static func decodeResponse(_ json: String) throws -> MoralisSolanaNetworkResult.WalletNFTsResponse {
        try JSONDecoder().decode(MoralisSolanaNetworkResult.WalletNFTsResponse.self, from: Data(json.utf8))
    }

    static func decodeLegacyAssets(_ json: String) throws -> [MoralisSolanaNetworkResult.Asset] {
        try JSONDecoder().decode([MoralisSolanaNetworkResult.Asset].self, from: Data(json.utf8))
    }
}

// MARK: - Responses

extension MoralisSolanaFixtures {
    static let coreResponse = """
    {
      "meta": { "syncedAt": { "solana-mainnet": "latest" }, "unsupportedChains": [], "failedChains": [] },
      "address": "CUfZZHt9nNsSnQUv5jhGGLbRRtudpWvzoSwbJQf7T9PW",
      "addressType": "solana",
      "cursor": "next-page",
      "result": [
        {
          "chainId": "solana-mainnet",
          "tokenAddress": "CoreAsset1111111111111111111111111111111111",
          "tokenId": null,
          "tokenStandard": "MplCore",
          "amount": "1",
          "name": "Card #1",
          "symbol": "CC",
          "metadataUri": "https://example.com/1.json",
          "metadata": {
            "name": "Card #1",
            "description": "A graded card",
            "image": "https://example.com/1.png",
            "externalUrl": null,
            "animationUrl": null,
            "attributes": [{ "traitType": "Background", "value": "Purple" }]
          },
          "media": {
            "status": "success",
            "mimetype": "image/png",
            "category": "image",
            "originalMediaUrl": "https://example.com/1.png",
            "mediaCollection": {
              "low": { "width": 100, "height": 100, "url": "https://media.moralis.io/low.png" },
              "medium": { "width": 250, "height": 250, "url": "https://media.moralis.io/medium.png" },
              "high": { "width": 500, "height": 500, "url": "https://media.moralis.io/high.png" }
            }
          },
          "collection": { "address": "CoreCollection11111111111111111111111111111", "name": "Collector Crypt", "symbol": "CC", "verified": true },
          "possibleSpam": false,
          "floorPriceUsd": null,
          "lastSale": null,
          "blockNumberMinted": "189744688",
          "blockNumberReceived": null
        },
        {
          "chainId": "solana-mainnet",
          "tokenAddress": "CoreAsset2222222222222222222222222222222222",
          "tokenId": null,
          "tokenStandard": "MplCore",
          "amount": "1",
          "name": "No media",
          "symbol": null,
          "metadataUri": null,
          "metadata": {
            "name": "No media",
            "description": null,
            "image": "ipfs://QmImage/2.png",
            "externalUrl": null,
            "animationUrl": null,
            "attributes": []
          },
          "media": null,
          "collection": { "address": "CoreCollection22222222222222222222222222222", "name": "Other", "symbol": null, "verified": null },
          "possibleSpam": false,
          "floorPriceUsd": null,
          "lastSale": null,
          "blockNumberMinted": null,
          "blockNumberReceived": null
        }
      ]
    }
    """

    static let failedChainResponse = """
    {
      "meta": {
        "syncedAt": {},
        "unsupportedChains": [],
        "failedChains": [{ "chainId": "solana-mainnet", "code": "INTERNAL_SERVER_ERROR", "error": "Failed to fetch data from the chain" }]
      },
      "address": "CUfZZHt9nNsSnQUv5jhGGLbRRtudpWvzoSwbJQf7T9PW",
      "addressType": "solana",
      "cursor": null,
      "result": []
    }
    """
}

// MARK: - Mapping cases

extension MoralisSolanaFixtures {
    static let addresslessCoreResponse = """
    {
      "cursor": null,
      "result": [
        {
          "tokenAddress": "CoreAsset3333333333333333333333333333333333",
          "tokenStandard": "MplCore",
          "name": "Loose one",
          "collection": { "address": null, "name": "Off-chain name A", "symbol": null, "verified": null }
        },
        {
          "tokenAddress": "CoreAsset4444444444444444444444444444444444",
          "tokenStandard": "MplCore",
          "name": "Loose two",
          "collection": { "address": "", "name": "Off-chain name B", "symbol": null, "verified": null }
        }
      ]
    }
    """

    static let coreAssetWithoutTokenAddressResponse = """
    {
      "cursor": null,
      "result": [
        {
          "tokenAddress": null,
          "tokenStandard": "MplCore",
          "name": "Broken",
          "collection": { "address": "CoreCollection11111111111111111111111111111", "name": "Collector Crypt" }
        }
      ]
    }
    """

    static let legacyAssetsInCoreCollection = """
    [
      {
        "associatedTokenAddress": "LegacyAta1111111111111111111111111111111111",
        "mint": "LegacyMint111111111111111111111111111111111",
        "tokenStandard": 4,
        "name": "Legacy #1",
        "decimals": 0,
        "collection": {
          "collectionAddress": "CoreCollection11111111111111111111111111111",
          "name": "Collector Crypt",
          "description": "Legacy collection description"
        }
      }
    ]
    """

    static let legacyAssetsWithOtherCollectionName = """
    [
      {
        "mint": "LegacyMint333333333333333333333333333333333",
        "tokenStandard": 4,
        "name": "Legacy #3",
        "collection": { "collectionAddress": "CoreCollection11111111111111111111111111111", "name": "Other name" }
      }
    ]
    """

    static let coreSameAddressDifferentNamesResponse = """
    {
      "cursor": null,
      "result": [
        {
          "tokenAddress": "CoreAsset7777777777777777777777777777777777",
          "tokenStandard": "MplCore",
          "name": "First",
          "collection": { "address": "CoreCollection77777777777777777777777777777", "name": "Named" }
        },
        {
          "tokenAddress": "CoreAsset8888888888888888888888888888888888",
          "tokenStandard": "MplCore",
          "name": "Second",
          "collection": { "address": "CoreCollection77777777777777777777777777777", "name": null }
        }
      ]
    }
    """

    static let coreVideoResponse = """
    {
      "cursor": null,
      "result": [
        {
          "tokenAddress": "CoreAsset5555555555555555555555555555555555",
          "tokenStandard": "MplCore",
          "name": "Video one",
          "metadata": { "image": "https://example.com/preview.png", "attributes": [] },
          "media": { "mimetype": "video/mp4", "originalMediaUrl": "https://example.com/clip.mp4", "mediaCollection": null },
          "collection": { "address": "CoreCollection66666666666666666666666666666", "name": "Clips" }
        }
      ]
    }
    """

    static let legacyAssetWithoutCollection = """
    [
      {
        "mint": "LegacyMint222222222222222222222222222222222",
        "tokenStandard": 0,
        "name": "Legacy loose"
      }
    ]
    """
}
