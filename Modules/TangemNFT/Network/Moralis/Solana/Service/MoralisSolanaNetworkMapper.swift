//
//  MoralisSolanaNetworkMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MoralisSolanaNetworkMapper {
    func map(
        collection: MoralisSolanaNetworkResult.Collection?,
        assets: [MoralisSolanaNetworkResult.Asset],
        ownerAddress: String
    ) -> NFTCollection {
        let domainAssets = assets.compactMap { map(asset: $0, ownerAddress: ownerAddress) }

        guard let collection, let collectionId = collection.collectionAddress else {
            return NFTDummyCollectionMapper.map(
                chain: .solana,
                assets: domainAssets,
                assetsCount: domainAssets.count,
                contractType: .unknown,
                ownerAddress: ownerAddress
            )
        }

        return NFTCollection(
            collectionIdentifier: collectionId,
            chain: .solana,
            contractType: .unknown,
            ownerAddress: ownerAddress,
            name: collectionId,
            description: collection.description,
            // Moralis doesn't send collection URL, so we assigning first asset's image as discussed
            // [REDACTED_INFO]
            media: domainAssets.first?.media,
            assetsCount: domainAssets.count,
            assets: domainAssets
        )
    }

    private func map(
        asset: MoralisSolanaNetworkResult.Asset,
        ownerAddress: String
    ) -> NFTAsset? {
        guard
            let name = asset.name,
            let contractAddress = asset.mint // `mint` field is the actual contract address for Solana NFTs
        else {
            NFTLogger.warning(
                String(
                    format: "Asset missing required fields: name %@, mint %@",
                    String(describing: asset.name),
                    String(describing: asset.mint)
                )
            )
            return nil
        }

        let rarity = mapToRarity(attributes: asset.attributes)
        let media = mapToMedia(properties: asset.properties)
        let traits = mapToTraits(attributes: asset.attributes)
        let decimalCount = asset.decimals ?? Constants.decimalCountFallback

        return NFTAsset(
            assetIdentifier: Constants.dummyAssetIdentifier,
            assetContractAddress: contractAddress,
            chain: .solana,
            contractType: .unknown,
            decimalCount: decimalCount,
            ownerAddress: ownerAddress,
            name: name,
            description: nil, // Moralis doesn't send description for Solana
            media: media,
            rarity: rarity,
            traits: traits
        )
    }

    private func mapToRarity(attributes: [MoralisSolanaNetworkResult.Attribute]?) -> NFTAsset.Rarity? {
        guard let rarityAttribute = attributes?.first(where: { $0.type == Constants.rarityRankTitle }) else {
            return nil
        }

        guard let rank = rarityAttribute.value as? Int else {
            NFTLogger.warning(
                String(
                    format: "Rarity missing required fields: value %@",
                    String(describing: rarityAttribute.value)
                )
            )
            return nil
        }

        return NFTAsset.Rarity(
            label: nil,
            percentage: nil,
            rank: rank
        )
    }

    private func mapToMedia(properties: MoralisSolanaNetworkResult.Properties?) -> NFTMedia? {
        guard let firstFile = properties?.files?.first else {
            return nil
        }

        guard
            let uri = firstFile.uri?.nilIfEmpty,
            let url = URL(string: uri)
        else {
            NFTLogger.warning(
                String(
                    format: "Media missing required fields: uri %@",
                    String(describing: firstFile.uri)
                )
            )
            return nil
        }

        return NFTMedia(
            kind: NFTMediaKindMapper.map(mimetype: firstFile.type, defaultKind: .image),
            url: NFTIPFSURLConverter.convert(url)
        )
    }

    private func mapToTraits(attributes: [MoralisSolanaNetworkResult.Attribute]?) -> [NFTAsset.Trait] {
        attributes?.compactMap { attribute in
            guard attribute.type != Constants.rarityRankTitle else {
                return nil
            }

            guard
                let name = attribute.type,
                let value = attribute.value as? String
            else {
                NFTLogger.warning(
                    String(
                        format: "Attribute missing required fields: type %@, value %@",
                        String(describing: attribute.type),
                        String(describing: attribute.value)
                    )
                )
                return nil
            }

            return NFTAsset.Trait(name: name, value: value)
        } ?? []
    }
}

private extension MoralisSolanaNetworkMapper {
    enum Constants {
        /// Solana NFTs don't have a unique Token ID in the form of a UInt256 number like EVM NFTs do,
        /// so we're using this default value instead.
        static let dummyAssetIdentifier = ""
        /// Moralis provides descriptions for Solana NFT collections, so this value is used only as a fallback.
        static let decimalCountFallback = 0
        static let rarityRankTitle = "Rarity Rank"
    }
}
