//
//  MoralisSolanaNetworkMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MoralisSolanaNetworkMapper {
    let mediaMapper: NFTMediaKindMapper

    func map(
        collection: MoralisSolanaNetworkResult.Collection?,
        assets: [MoralisSolanaNetworkResult.Asset],
        ownerAddress: String
    ) -> NFTCollection {
        func mapAssets(collectionId: String?) -> [NFTAsset] {
            assets.compactMap {
                map(asset: $0, ownerAddress: ownerAddress, collectionId: collectionId)
            }
        }

        let domainAssets = mapAssets(collectionId: nil)

        // In Solana collection's id is its name
        guard let collection, let collectionId = collection.name else {
            return NFTDummyCollectionMapper.map(
                chain: .solana,
                assets: domainAssets,
                assetsCount: domainAssets.count,
                contractType: .unknown,
                ownerAdddress: ownerAddress
            )
        }

        return NFTCollection(
            collectionIdentifier: collectionId,
            chain: .solana,
            contractType: .unknown,
            ownerAddress: ownerAddress,
            name: collectionId,
            description: collection.description,
            // Moralis doesnt send collection URL, so we assigning first asset's image as discussed
            // [REDACTED_INFO]
            logoURL: domainAssets.first?.media?.url,
            assetsCount: domainAssets.count,
            assets: domainAssets
        )
    }

    private func map(
        asset: MoralisSolanaNetworkResult.Asset,
        ownerAddress: String,
        collectionId: String?
    ) -> NFTAsset? {
        guard
            let name = asset.name,
            let identifier = asset.mint
        else {
            NFTLogger.warning(
                String(
                    format: "Asset missing required fields: name %@, identifier %@",
                    String(describing: asset.name),
                    String(describing: asset.mint)
                )
            )
            return nil
        }

        let rarity = mapToRarity(attributes: asset.attributes)
        let media = mapToMedia(properties: asset.properties)
        let traits = mapToTraits(attributes: asset.attributes)

        return NFTAsset(
            assetIdentifier: identifier,
            collectionIdentifier: collectionId,
            chain: .solana,
            contractType: .unknown,
            ownerAddress: ownerAddress,
            name: name,
            description: nil, // Moralis doesnt send description for Solana
            media: media,
            rarity: rarity,
            traits: traits
        )
    }

    private func mapToRarity(attributes: [MoralisSolanaNetworkResult.Attribute]?) -> NFTAsset.Rarity? {
        guard
            let rarityAttribute = attributes?.first(where: { $0.type == Constants.rarityRankTitle }),
            let rank = rarityAttribute.value as? Int
        else {
            return nil
        }

        return NFTAsset.Rarity(
            label: nil,
            percentage: nil,
            rank: rank
        )
    }

    private func mapToMedia(properties: MoralisSolanaNetworkResult.Properties?) -> NFTAsset.Media? {
        guard
            let firstFile = properties?.files?.first,
            let uri = firstFile.uri,
            let url = URL(string: uri)
        else {
            return nil
        }

        return NFTAsset.Media(kind: mediaMapper.map(mimetype: firstFile.type), url: url)
    }

    private func mapToTraits(attributes: [MoralisSolanaNetworkResult.Attribute]?) -> [NFTAsset.Trait] {
        attributes?.compactMap {
            guard
                let name = $0.type,
                let value = $0.value as? String,
                name != Constants.rarityRankTitle
            else {
                return nil
            }

            return NFTAsset.Trait(name: name, value: value)
        } ?? []
    }
}

private extension MoralisSolanaNetworkMapper {
    enum Constants {
        static let rarityRankTitle = "Rarity Rank"
    }
}
