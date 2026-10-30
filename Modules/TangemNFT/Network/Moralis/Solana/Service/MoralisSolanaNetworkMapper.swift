//
//  MoralisSolanaNetworkMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

struct MoralisSolanaNetworkMapper {
    func map(
        regularAssets: [MoralisSolanaNetworkResult.Asset],
        coreAssets: [MoralisSolanaNetworkResult.WalletNFT],
        ownerAddress: String
    ) -> [NFTCollection] {
        var collections = Dictionary(grouping: regularAssets, by: { $0.collection?.collectionAddress?.nilIfEmpty })
            .mapValues { assets in
                map(collection: assets.first?.collection, assets: assets, ownerAddress: ownerAddress)
            }

        let groupedCoreAssets = Dictionary(grouping: coreAssets, by: { $0.collection?.address?.nilIfEmpty })

        for (collectionAddress, assets) in groupedCoreAssets {
            if let regularCollection = collections[collectionAddress] {
                collections[collectionAddress] = join(coreAssets: assets, to: regularCollection, ownerAddress: ownerAddress)
            } else {
                collections[collectionAddress] = makeCollection(
                    fromCoreAssets: assets,
                    collectionAddress: collectionAddress,
                    ownerAddress: ownerAddress
                )
            }
        }

        return Array(collections.values)
    }

    private func map(
        collection: MoralisSolanaNetworkResult.Collection?,
        assets: [MoralisSolanaNetworkResult.Asset],
        ownerAddress: String
    ) -> NFTCollection {
        let domainAssets = assets.compactMap {
            map(
                asset: $0,
                ownerAddress: ownerAddress,
                // We should use collection description as an asset's description
                // when asset's description is missing. (In case of Moralis for Solana -- always)
                description: $0.collection?.description
            )
        }

        return makeCollection(
            collectionIdentifier: collection?.collectionAddress?.nilIfEmpty,
            name: collection?.name,
            description: collection?.description,
            assets: domainAssets,
            ownerAddress: ownerAddress
        )
    }

    private func join(
        coreAssets: [MoralisSolanaNetworkResult.WalletNFT],
        to collection: NFTCollection,
        ownerAddress: String
    ) -> NFTCollection {
        let coreDomainAssets = coreAssets.compactMap {
            makeAsset(fromCoreAsset: $0, ownerAddress: ownerAddress, fallbackDescription: collection.description)
        }

        let domainAssets = collection.assetsResult.value + coreDomainAssets

        return NFTCollection(
            collectionIdentifier: collection.id.collectionIdentifier,
            chain: collection.id.chain,
            contractType: collection.contractType,
            ownerAddress: collection.id.ownerAddress,
            name: collection.name,
            description: collection.description,
            media: collection.media ?? makeCollectionMedia(from: coreDomainAssets),
            assetsCount: domainAssets.count,
            assetsResult: NFTPartialResult(value: domainAssets)
        )
    }

    private func makeCollection(
        fromCoreAssets coreAssets: [MoralisSolanaNetworkResult.WalletNFT],
        collectionAddress: String?,
        ownerAddress: String
    ) -> NFTCollection {
        let domainAssets = coreAssets.compactMap {
            makeAsset(fromCoreAsset: $0, ownerAddress: ownerAddress, fallbackDescription: nil)
        }

        return makeCollection(
            collectionIdentifier: collectionAddress,
            name: coreAssets.first?.collection?.name,
            description: nil,
            assets: domainAssets,
            ownerAddress: ownerAddress
        )
    }

    private func makeCollection(
        collectionIdentifier: String?,
        name: String?,
        description: String?,
        assets: [NFTAsset],
        ownerAddress: String
    ) -> NFTCollection {
        let collectionMedia = makeCollectionMedia(from: assets)

        guard let collectionIdentifier else {
            return NFTDummyCollectionMapper.map(
                chain: .solana,
                assets: assets,
                assetsCount: assets.count,
                contractType: .unknown,
                ownerAddress: ownerAddress,
                description: description,
                media: collectionMedia
            )
        }

        return NFTCollection(
            collectionIdentifier: collectionIdentifier,
            chain: .solana,
            contractType: .unknown,
            ownerAddress: ownerAddress,
            name: name?.nilIfEmpty ?? Constants.collectionNameFallback,
            description: description,
            media: collectionMedia,
            assetsCount: assets.count,
            assetsResult: NFTPartialResult(value: assets)
        )
    }

    private func makeCollectionMedia(from assets: [NFTAsset]) -> NFTMedia? {
        // Moralis doesn't send collection image URL, so we are assigning first asset's image or animation
        assets
            .compactMap { NFTAssetMediaExtractor.extractMedia(from: $0) }
            .first
    }

    private func makeAsset(
        fromCoreAsset coreAsset: MoralisSolanaNetworkResult.WalletNFT,
        ownerAddress: String,
        fallbackDescription: String?
    ) -> NFTAsset? {
        guard let contractAddress = coreAsset.tokenAddress?.nilIfEmpty else {
            NFTLogger.warning(
                String(
                    format: "Core asset missing required fields: tokenAddress %@",
                    String(describing: coreAsset.tokenAddress)
                )
            )
            return nil
        }

        let metadata = coreAsset.metadata

        return NFTAsset(
            assetIdentifier: Constants.dummyAssetIdentifier,
            assetContractAddress: contractAddress,
            chain: .solana,
            contractType: NFTContractTypeMapper.map(contractType: coreAsset.tokenStandard?.nilIfEmpty),
            decimalCount: Constants.decimalCountFallback,
            ownerAddress: ownerAddress,
            name: coreAsset.name?.nilIfEmpty ?? metadata?.name?.nilIfEmpty ?? Constants.assetNameFallback,
            description: metadata?.description?.nilIfEmpty ?? fallbackDescription,
            salePrice: nil,
            mediaFiles: mapToMediaFiles(coreAsset: coreAsset),
            rarity: mapToRarity(attributes: metadata?.attributes),
            traits: mapToTraits(attributes: metadata?.attributes)
        )
    }

    private func mapToMediaFiles(coreAsset: MoralisSolanaNetworkResult.WalletNFT) -> [NFTMedia] {
        let media = coreAsset.media
        let mediaCollection = media?.mediaCollection

        let indexedMedia = MoralisMediaURLMapper.map(
            high: mediaCollection?.high?.url,
            medium: mediaCollection?.medium?.url,
            low: mediaCollection?.low?.url,
            original: media?.originalMediaUrl
        ).map { url in
            NFTMedia(kind: NFTMediaKindMapper.map(mimetype: media?.mimetype, defaultKind: .image), url: url)
        }

        let metadataImage = MoralisMediaURLMapper.map(coreAsset.metadata?.image).map { url in
            NFTMedia(kind: NFTMediaKindMapper.map(url, defaultKind: .image), url: url)
        }

        let mediaFiles = [indexedMedia, metadataImage].compactMap { $0 }.unique()

        if mediaFiles.isEmpty {
            NFTLogger.warning(
                String(
                    format: "Core asset has no media: tokenAddress %@",
                    String(describing: coreAsset.tokenAddress)
                )
            )
        }

        return mediaFiles
    }

    private func map(
        asset: MoralisSolanaNetworkResult.Asset,
        ownerAddress: String,
        description: String?
    ) -> NFTAsset? {
        // `mint` field is the actual contract address for Solana NFTs
        guard let contractAddress = asset.mint else {
            NFTLogger.warning(
                String(
                    format: "Asset missing required fields: mint %@",
                    String(describing: asset.mint)
                )
            )
            return nil
        }

        let rarity = mapToRarity(attributes: asset.attributes)
        let mediaFiles = mapToMediaFiles(properties: asset.properties)
        let traits = mapToTraits(attributes: asset.attributes)
        let decimalCount = asset.decimals ?? Constants.decimalCountFallback
        let standard = NFTContractTypeMapper.map(
            contractType: asset.tokenStandard.flatMap(String.init),
            isAnalyticsOnly: true
        )

        return NFTAsset(
            assetIdentifier: Constants.dummyAssetIdentifier,
            assetContractAddress: contractAddress,
            chain: .solana,
            contractType: standard,
            decimalCount: decimalCount,
            ownerAddress: ownerAddress,
            name: asset.name?.nilIfEmpty ?? Constants.assetNameFallback,
            description: description,
            salePrice: nil,
            mediaFiles: mediaFiles,
            rarity: rarity,
            traits: traits
        )
    }

    private func mapToRarity(attributes: [MoralisSolanaNetworkResult.Attribute]?) -> NFTAsset.Rarity? {
        guard let rarityAttribute = attributes?.first(where: { $0.traitType == Constants.rarityRankTitle }) else {
            return nil
        }

        guard let rank = rarityAttribute.value?.value as? Int else {
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

    private func mapToMediaFiles(properties: MoralisSolanaNetworkResult.Properties?) -> [NFTMedia] {
        return properties?
            .files?
            .compactMap { file -> NFTMedia? in
                guard
                    let uri = file.uri?.nilIfEmpty,
                    let rawURL = URL(string: uri)
                else {
                    NFTLogger.warning(
                        String(
                            format: "Media missing required fields: uri %@",
                            String(describing: file.uri)
                        )
                    )
                    return nil
                }

                let kind = NFTMediaKindMapper.map(mimetype: file.type, defaultKind: .image)
                let url = NFTIPFSURLConverter.convert(rawURL)

                return NFTMedia(kind: kind, url: url)
            } ?? []
    }

    private func mapToTraits(attributes: [MoralisSolanaNetworkResult.Attribute]?) -> [NFTAsset.Trait] {
        attributes?.compactMap { attribute in
            guard attribute.traitType != Constants.rarityRankTitle else {
                return nil
            }

            guard
                let name = attribute.traitType,
                let value = attribute.value?.value as? String
            else {
                NFTLogger.warning(
                    String(
                        format: "Attribute missing required fields: traitType %@, value %@",
                        String(describing: attribute.traitType),
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
        static var collectionNameFallback: String { Localization.nftUntitledCollection }
        static var assetNameFallback: String { .enDashSign }
    }
}
