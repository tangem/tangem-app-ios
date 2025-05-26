//
//  NFTCachedModels.V1.Asset.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension NFTCachedModels.V1 {
    struct Asset: Codable, Hashable, Identifiable, Sendable {
        // From NFTAssetId
        let id: String // Combination of identifier and other fields to ensure uniqueness
        let identifier: String
        let contractAddress: String
        let ownerAddress: String
        let chainName: String // String representation of NFTChain
        let isTestnet: Bool // Whether the chain is testnet
        let contractTypeIdentifier: String // String representation of NFTContractType

        // From main NFTAsset
        let decimalCount: Int
        let name: String
        let description: String?

        // From NFTSalePrice
        let lastPriceValue: Decimal?
        let lowestPriceValue: Decimal?
        let highestPriceValue: Decimal?

        // From NFTMedia
        let mediaURL: URL?
        let mediaKindName: String?

        // From Rarity
        let rarityLabel: String?
        let rarityPercentage: Double?
        let rarityRank: Int?

        // Traits flattened to arrays
        let traitNames: [String]
        let traitValues: [String]
    }
}

extension NFTCachedModels.V1.Asset {
    init(from asset: NFTAsset) {
        // From NFTAssetId
        identifier = asset.id.identifier
        contractAddress = asset.id.contractAddress
        ownerAddress = asset.id.ownerAddress

        // Extract chain info using shared utility
        let (chainNameValue, isTestnetValue) = NFTCachedModels.ChainUtils.serialize(asset.id.chain)
        chainName = chainNameValue
        isTestnet = isTestnetValue

        // Create unique ID by combining key fields
        id = "\(chainName)\(isTestnet ? "-testnet" : "")_\(contractAddress)_\(identifier)_\(ownerAddress)"

        // From NFTContractType using shared utility
        contractTypeIdentifier = NFTCachedModels.ContractTypeUtils.serialize(asset.id.contractType)

        // From main NFTAsset
        decimalCount = asset.decimalCount
        name = asset.name
        description = asset.description

        // From NFTSalePrice
        lastPriceValue = asset.salePrice?.last.value
        lowestPriceValue = asset.salePrice?.lowest?.value
        highestPriceValue = asset.salePrice?.highest?.value

        // From NFTMedia
        mediaURL = asset.media?.url
        mediaKindName = NFTCachedModels.MediaUtils.serialize(asset.media?.kind)

        // From Rarity
        rarityLabel = asset.rarity?.label
        rarityPercentage = asset.rarity?.percentage
        rarityRank = asset.rarity?.rank

        // Traits flattened to arrays
        traitNames = asset.traits.map { $0.name }
        traitValues = asset.traits.map { $0.value }
    }

    func toNFTAsset() throws -> NFTAsset {
        // Reconstruct chain using shared utility
        let chain = try NFTCachedModels.ChainUtils.deserialize(chainName: chainName, isTestnet: isTestnet)

        // Reconstruct contract type using shared utility
        let contractType = NFTCachedModels.ContractTypeUtils.deserialize(contractTypeIdentifier: contractTypeIdentifier)

        // Reconstruct media using shared utility
        let media = NFTCachedModels.MediaUtils.createMedia(url: mediaURL, kindName: mediaKindName)

        // Reconstruct sale price - only create if at least one price exists
        var salePrice: NFTSalePrice?
        if let lastPrice = lastPriceValue {
            let last = NFTSalePrice.Price(value: lastPrice)
            let lowest = lowestPriceValue.map { NFTSalePrice.Price(value: $0) }
            let highest = highestPriceValue.map { NFTSalePrice.Price(value: $0) }
            salePrice = NFTSalePrice(last: last, lowest: lowest, highest: highest)
        }

        // Reconstruct rarity
        let rarity: NFTAsset.Rarity?
        if rarityLabel != nil || rarityPercentage != nil || rarityRank != nil {
            rarity = NFTAsset.Rarity(
                label: rarityLabel,
                percentage: rarityPercentage,
                rank: rarityRank
            )
        } else {
            rarity = nil
        }

        // Recreate traits from parallel arrays
        var traits: [NFTAsset.Trait] = []
        if traitNames.count == traitValues.count {
            traits = zip(traitNames, traitValues).map {
                NFTAsset.Trait(name: $0.0, value: $0.1)
            }
        }

        // Create the NFTAsset with all reconstructed components
        return NFTAsset(
            assetIdentifier: identifier,
            assetContractAddress: contractAddress,
            chain: chain,
            contractType: contractType,
            decimalCount: decimalCount,
            ownerAddress: ownerAddress,
            name: name,
            description: description,
            salePrice: salePrice,
            media: media,
            rarity: rarity,
            traits: traits
        )
    }
}
