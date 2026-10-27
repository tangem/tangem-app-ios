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

    static func decodeRegularAssets(_ json: String) throws -> [MoralisSolanaNetworkResult.Asset] {
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

    static let regularAssetsInCoreCollection = """
    [
      {
        "associatedTokenAddress": "RegularAta1111111111111111111111111111111111",
        "mint": "RegularMint111111111111111111111111111111111",
        "tokenStandard": 4,
        "name": "Regular #1",
        "decimals": 0,
        "collection": {
          "collectionAddress": "CoreCollection11111111111111111111111111111",
          "name": "Collector Crypt",
          "description": "Regular collection description"
        }
      }
    ]
    """

    static let regularAssetsWithOtherCollectionName = """
    [
      {
        "mint": "RegularMint333333333333333333333333333333333",
        "tokenStandard": 4,
        "name": "Regular #3",
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

    static let regularAssetInNamedCollectionWithoutAddress = """
    [
      {
        "mint": "RegularMint444444444444444444444444444444444",
        "tokenStandard": 4,
        "name": "Regular named loose",
        "collection": { "collectionAddress": null, "name": "Named without address", "description": "Named description" }
      }
    ]
    """

    static let regularAssetWithEmptyCollectionAddress = """
    [
      {
        "mint": "RegularMint555555555555555555555555555555555",
        "tokenStandard": 4,
        "name": "Regular empty address",
        "collection": { "collectionAddress": "", "name": "Empty address" }
      }
    ]
    """

    static let regularAssetsOfOneAddressWithVariousNames = """
    [
      {
        "mint": "RegularMint666666666666666666666666666666666",
        "tokenStandard": 4,
        "name": "Named regular",
        "collection": { "collectionAddress": "CoreCollection77777777777777777777777777777", "name": "Regular name" }
      },
      {
        "mint": "RegularMint777777777777777777777777777777777",
        "tokenStandard": 4,
        "name": "Empty-named regular",
        "collection": { "collectionAddress": "CoreCollection77777777777777777777777777777", "name": "" }
      },
      {
        "mint": "RegularMint888888888888888888888888888888888",
        "tokenStandard": 4,
        "name": "Unnamed regular",
        "collection": { "collectionAddress": "CoreCollection77777777777777777777777777777", "name": null }
      }
    ]
    """

    static let regularAssetWithoutCollection = """
    [
      {
        "mint": "RegularMint222222222222222222222222222222222",
        "tokenStandard": 0,
        "name": "Regular loose"
      }
    ]
    """
}

// MARK: - Paging

extension MoralisSolanaFixtures {
    static let firstPageResponse = """
    {
      "meta": { "syncedAt": { "solana-mainnet": "latest" }, "unsupportedChains": [], "failedChains": [] },
      "address": "CUfZZHt9nNsSnQUv5jhGGLbRRtudpWvzoSwbJQf7T9PW",
      "addressType": "solana",
      "cursor": "page-2",
      "result": [
        { "chainId": "solana-mainnet", "tokenAddress": "CorePage1Asset1", "tokenStandard": "MplCore", "name": "One" },
        { "chainId": "solana-mainnet", "tokenAddress": "CorePage1Asset2", "tokenStandard": "MplCore", "name": "Two" }
      ]
    }
    """

    static let secondPageResponse = """
    {
      "meta": { "syncedAt": { "solana-mainnet": "latest" }, "unsupportedChains": [], "failedChains": [] },
      "address": "CUfZZHt9nNsSnQUv5jhGGLbRRtudpWvzoSwbJQf7T9PW",
      "addressType": "solana",
      "cursor": "page-3",
      "result": [
        { "chainId": "solana-mainnet", "tokenAddress": "CorePage2Asset1", "tokenStandard": "MplCore", "name": "Three" }
      ]
    }
    """

    static let lastPageResponse = """
    {
      "meta": { "syncedAt": { "solana-mainnet": "latest" }, "unsupportedChains": [], "failedChains": [] },
      "address": "CUfZZHt9nNsSnQUv5jhGGLbRRtudpWvzoSwbJQf7T9PW",
      "addressType": "solana",
      "cursor": null,
      "result": [
        { "chainId": "solana-mainnet", "tokenAddress": "CorePage3Asset1", "tokenStandard": "MplCore", "name": "Four" }
      ]
    }
    """

    static let pageWithoutCursorResponse = """
    {
      "meta": { "syncedAt": { "solana-mainnet": "latest" }, "unsupportedChains": [], "failedChains": [] },
      "address": "CUfZZHt9nNsSnQUv5jhGGLbRRtudpWvzoSwbJQf7T9PW",
      "addressType": "solana",
      "result": [
        { "chainId": "solana-mainnet", "tokenAddress": "CoreOnlyAsset", "tokenStandard": "MplCore", "name": "Only" }
      ]
    }
    """
}
