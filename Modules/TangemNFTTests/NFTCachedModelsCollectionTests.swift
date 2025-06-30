//
//  NFTCachedModelsCollectionTests.swift
//  TangemNFTTests
//
//  Created on 25.05.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemNFT

@Suite("NFTCachedModels.V1.Collection")
struct NFTCachedModelsCollectionTests {
    // MARK: - Tests

    @Test("Collection serialization and deserialization for all chains")
    func testCollectionSerializationAndDeserialization() throws {
        // Test serialization and deserialization for all possible chain types
        for chain in NFTChain.allCases(isTestnet: false) {
            try testCollectionSerializationAndDeserialization(for: chain)
        }

        // Also test for testnet versions
        for chain in NFTChain.allCases(isTestnet: true) {
            try testCollectionSerializationAndDeserialization(for: chain)
        }
    }

    @Test("Collection serialization and deserialization with empty optionals")
    func testCollectionSerializationAndDeserializationWithEmptyOptionals() throws {
        // Create a collection with minimal data (all optionals set to nil)
        let collectionId = NFTCollection.NFTCollectionId(
            collectionIdentifier: "coll123",
            ownerAddress: "0xowner",
            chain: .ethereum(isTestnet: false)
        )

        let originalCollection = NFTCollection(
            collectionIdentifier: collectionId.collectionIdentifier,
            chain: collectionId.chain,
            contractType: .erc721,
            ownerAddress: collectionId.ownerAddress,
            name: "Minimal Collection",
            description: nil,
            media: nil,
            assetsCount: 0,
            assetsResult: []
        )

        // Test serialization and deserialization
        let storableModel = NFTCachedModels.V1.Collection(from: originalCollection)
        let restoredCollection = try storableModel.toNFTCollection()

        // Verify that the restored asset matches the original using full equality
        #expect(restoredCollection == originalCollection, "Restored collection should be equal to original collection")
    }

    @Test("Collection serialization and deserialization with round trip")
    func testCollectionSerializationAndDeserializationWithRoundTrip() throws {
        // Test that multiple serialization/deserialization cycles preserve data integrity
        let originalCollection = createCompleteNFTCollection(
            chain: .ethereum(isTestnet: false),
            contractType: .erc721,
            mediaKind: .image,
            assetCount: 3
        )

        // First round-trip
        let storableModel = NFTCachedModels.V1.Collection(from: originalCollection)
        let restoredCollection = try storableModel.toNFTCollection()

        // Second round-trip
        let secondStorableModel = NFTCachedModels.V1.Collection(from: restoredCollection)
        let secondRestoredCollection = try secondStorableModel.toNFTCollection()

        // Verify that data remains consistent after multiple conversions
        #expect(secondRestoredCollection == originalCollection, "Collection should remain consistent after multiple serialization cycles")
    }

    @Test("Collection serialization and deserialization with contract types")
    func testCollectionSerializationAndDeserializationWithContractTypes() throws {
        // Test all available contract types
        for contractType in NFTContractType.allCases {
            let originalCollection = createCompleteNFTCollection(
                chain: .ethereum(isTestnet: false),
                contractType: contractType,
                mediaKind: .image,
                assetCount: 1
            )

            let storableModel = NFTCachedModels.V1.Collection(from: originalCollection)
            let restoredCollection = try storableModel.toNFTCollection()

            #expect(restoredCollection.contractType == originalCollection.contractType, "Collections should be equal for contract type '\(contractType)'")
        }
    }

    @Test("Collection serialization and deserialization with media types")
    func testCollectionSerializationAndDeserializationWithMediaTypes() throws {
        // Test all available media kinds
        for mediaKind in NFTMedia.Kind.allCases {
            let originalCollection = createCompleteNFTCollection(
                chain: .ethereum(isTestnet: false),
                contractType: .erc721,
                mediaKind: mediaKind,
                assetCount: 10
            )

            let storableModel = NFTCachedModels.V1.Collection(from: originalCollection)
            let restoredCollection = try storableModel.toNFTCollection()

            #expect(restoredCollection.media == originalCollection.media, "Collections should be equal for media kind '\(mediaKind)'")
        }
    }

    @Test("Collection codability (JSON encoding/decoding)")
    func testCollectionCodability() throws {
        // Test that the storable model can be encoded to and decoded from JSON
        let originalCollection = createCompleteNFTCollection(
            chain: .ethereum(isTestnet: false),
            contractType: .erc721,
            mediaKind: .image,
            assetCount: 2
        )

        let storableModel = NFTCachedModels.V1.Collection(from: originalCollection)

        // Encode to Data
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(storableModel)

        // Decode back to storable model
        let decoder = JSONDecoder()
        let decodedStorableModel = try decoder.decode(NFTCachedModels.V1.Collection.self, from: encodedData)

        // Convert back to NFT collection
        let restoredCollection = try decodedStorableModel.toNFTCollection()

        // Verify with full equality check
        #expect(restoredCollection == originalCollection, "Collection should be equal after JSON encoding/decoding cycle")
    }

    @Test("Collection with nested assets serialization and deserialization")
    func testCollectionWithNestedAssets() throws {
        // Create a collection with multiple assets
        let assetCount = 5
        let originalCollection = createCompleteNFTCollection(
            chain: .ethereum(isTestnet: false),
            contractType: .erc721,
            mediaKind: .image,
            assetCount: assetCount
        )

        // Test serialization and deserialization
        let storableModel = NFTCachedModels.V1.Collection(from: originalCollection)

        // Verify that the nested assets were properly serialized
        #expect(storableModel.assets.count == assetCount)

        // Deserialize back to collection
        let restoredCollection = try storableModel.toNFTCollection()

        // Verify using full equality check
        #expect(restoredCollection == originalCollection)

        // Additional check to ensure each asset is properly restored
        for i in 0 ..< assetCount {
            #expect(
                restoredCollection.assetsResult.value[i] == originalCollection.assetsResult.value[i],
                "Restored number of assets should match original number of assets"
            )
        }

        // Verify errors are restored correctly
        #expect(restoredCollection.assetsResult.errors == originalCollection.assetsResult.errors, "Errors should match")
    }

    // MARK: - Private Helpers

    private func testCollectionSerializationAndDeserialization(for chain: NFTChain) throws {
        // Create a complete collection with all fields populated
        let originalCollection = createCompleteNFTCollection(
            chain: chain,
            contractType: .erc721,
            mediaKind: .image,
            assetCount: 2
        )

        // Convert to storable model
        let storableModel = NFTCachedModels.V1.Collection(from: originalCollection)

        // Convert back to NFT collection
        let restoredCollection = try storableModel.toNFTCollection()

        // Verify using full equality check instead of individual property comparisons
        #expect(restoredCollection == originalCollection, "Restored collection should equal original for chain '\(chain)'")
    }

    private func createCompleteNFTCollection(
        chain: NFTChain,
        contractType: NFTContractType,
        mediaKind: NFTMedia.Kind,
        assetCount: Int
    ) -> NFTCollection {
        // Create a unique identifier based on chain and contract type
        let identifier = "collection_\(chain.id)_\(contractType)"

        // Create assets for this collection
        var assets = [NFTAsset]()
        for i in 0 ..< assetCount {
            let assetId = NFTAsset.NFTAssetId(
                identifier: "asset_\(i)_\(identifier)",
                contractAddress: "0x\(identifier)_contract",
                ownerAddress: "0x\(identifier)_owner",
                chain: chain,
                contractType: contractType
            )

            let traits = [
                NFTAsset.Trait(name: "Background", value: "Blue"),
                NFTAsset.Trait(name: "Eyes", value: "Green"),
            ]

            let salePrice = NFTSalePrice(
                last: NFTSalePrice.Price(value: 2.5),
                lowest: NFTSalePrice.Price(value: 1.0),
                highest: NFTSalePrice.Price(value: 5.0)
            )

            let media = NFTMedia(
                kind: mediaKind,
                url: URL(string: "https://example.com/\(identifier)_\(i).png")!
            )

            let asset = NFTAsset(
                assetIdentifier: assetId.identifier,
                assetContractAddress: assetId.contractAddress,
                chain: assetId.chain,
                contractType: assetId.contractType,
                decimalCount: 0,
                ownerAddress: assetId.ownerAddress,
                name: "Asset \(i) in \(identifier)",
                description: "This is asset \(i) in collection \(identifier)",
                salePrice: salePrice,
                mediaFiles: [media],
                rarity: NFTAsset.Rarity(label: "Rare", percentage: 12.5, rank: 42),
                traits: traits
            )

            assets.append(asset)
        }

        // Create a collection with the assets
        return NFTCollection(
            collectionIdentifier: identifier,
            chain: chain,
            contractType: contractType,
            ownerAddress: "0x\(identifier)_owner",
            name: "Collection \(identifier)",
            description: "This is a test collection for \(chain.id) with \(contractType)",
            media: NFTMedia(
                kind: .image,
                url: URL(string: "https://example.com/collection_\(identifier).png")!
            ),
            assetsCount: assetCount,
            assetsResult: NFTPartialResult(
                value: assets,
                errors: [
                    NFTErrorDescriptor(code: 1, description: "Desc"),
                    NFTErrorDescriptor(code: 2, description: "Desc2"),
                ]
            )
        )
    }
}
