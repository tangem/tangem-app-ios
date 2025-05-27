//
//  NFTCachedModels.V1.Asset.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension NFTCachedModels.V1 {
    struct Asset: Codable {
        // MARK: - NFTAssetId

        let identifier: String
        let contractAddress: String
        let ownerAddress: String
        let chainName: String
        let isTestnet: Bool
        let contractTypeIdentifier: String

        // MARK: - NFTAsset

        let decimalCount: Int
        let name: String
        let description: String?

        // MARK: - NFTSalePrice

        let lastPriceValue: Decimal?
        let lowestPriceValue: Decimal?
        let highestPriceValue: Decimal?

        // MARK: - NFTMedia

        let mediaURL: URL?
        let mediaKindName: String?

        // MARK: - Rarity

        let rarityLabel: String?
        let rarityPercentage: Double?
        let rarityRank: Int?

        // MARK: - Traits (flattened to arrays)

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

        // Reconstruct rarity - only create if at least one field exists
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
        let traits = zip(traitNames, traitValues).map {
            NFTAsset.Trait(name: $0.0, value: $0.1)
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
