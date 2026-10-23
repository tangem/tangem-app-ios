//
//  MoralisSolanaNetworkMapperTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
@testable import TangemNFT

@Suite("MoralisSolanaNetworkMapperTests")
struct MoralisSolanaNetworkMapperTests {
    private let mapper = MoralisSolanaNetworkMapper()
    private let ownerAddress = "CUfZZHt9nNsSnQUv5jhGGLbRRtudpWvzoSwbJQf7T9PW"

    @Test
    func mapsCoreAssetIntoItsCollection() throws {
        let coreAssets = try #require(MoralisSolanaFixtures.decodeResponse(MoralisSolanaFixtures.coreResponse).result)

        let collections = mapper.map(regularAssets: [], coreAssets: coreAssets, ownerAddress: ownerAddress)

        let collection = try #require(collections.first { $0.id.collectionIdentifier == "CoreCollection11111111111111111111111111111" })
        #expect(collection.name == "Collector Crypt")
        #expect(collection.id.chain == .solana)
        #expect(collection.assetsCount == 1)
        #expect(collection.media?.url == URL(string: "https://media.moralis.io/high.png"))

        let asset = try #require(collection.assetsResult.value.first)
        #expect(asset.id.contractAddress == "CoreAsset1111111111111111111111111111111111")
        #expect(asset.id.identifier == "")
        #expect(asset.id.contractType == .other("MplCore"))
        #expect(asset.id.ownerAddress == ownerAddress)
        #expect(asset.name == "Card #1")
        #expect(asset.description == "A graded card")
        #expect(asset.decimalCount == 0)
        let indexedMediaURL = try #require(URL(string: "https://media.moralis.io/high.png"))
        let metadataImageURL = try #require(URL(string: "https://example.com/1.png"))
        #expect(asset.mediaFiles == [
            NFTMedia(kind: .image, url: indexedMediaURL),
            NFTMedia(kind: .image, url: metadataImageURL),
        ])
        #expect(asset.traits == [NFTAsset.Trait(name: "Background", value: "Purple")])
    }

    @Test
    func usesMetadataImageWhenMediaIsMissing() throws {
        let coreAssets = try #require(MoralisSolanaFixtures.decodeResponse(MoralisSolanaFixtures.coreResponse).result)

        let collections = mapper.map(regularAssets: [], coreAssets: coreAssets, ownerAddress: ownerAddress)

        let asset = try #require(collections.flatMap(\.assetsResult.value).first { $0.name == "No media" })
        let metadataImageURL = try #require(URL(string: "https://ipfs.io/ipfs/QmImage/2.png"))
        #expect(asset.mediaFiles == [NFTMedia(kind: .image, url: metadataImageURL)])
    }

    @Test
    func mergesRegularAndCoreAssetsOfOneCollection() throws {
        let regularAssets = try MoralisSolanaFixtures.decodeRegularAssets(MoralisSolanaFixtures.regularAssetsInCoreCollection)
        let coreAssets = try #require(MoralisSolanaFixtures.decodeResponse(MoralisSolanaFixtures.coreResponse).result)

        let collections = mapper.map(regularAssets: regularAssets, coreAssets: coreAssets, ownerAddress: ownerAddress)

        let collection = try #require(collections.first { $0.id.collectionIdentifier == "CoreCollection11111111111111111111111111111" })
        #expect(collection.assetsCount == 2)
        #expect(collection.description == "Regular collection description")

        let contractTypes = collection.assetsResult.value.map(\.id.contractType)
        #expect(contractTypes == [.analyticsOnly("4"), .other("MplCore")])
    }

    @Test
    func coreAssetJoinsRegularCollectionWithSameAddress() throws {
        let regularAssets = try MoralisSolanaFixtures.decodeRegularAssets(MoralisSolanaFixtures.regularAssetsWithOtherCollectionName)
        let coreAssets = try #require(MoralisSolanaFixtures.decodeResponse(MoralisSolanaFixtures.coreResponse).result)

        let collections = mapper.map(regularAssets: regularAssets, coreAssets: coreAssets, ownerAddress: ownerAddress)

        let matchingCollections = collections.filter { $0.id.collectionIdentifier == "CoreCollection11111111111111111111111111111" }
        #expect(matchingCollections.count == 1)
        #expect(matchingCollections.first?.name == "Other name")
        #expect(matchingCollections.first?.assetsCount == 2)
    }

    @Test
    func keepsCoreOnlyCollectionSeparate() throws {
        let regularAssets = try MoralisSolanaFixtures.decodeRegularAssets(MoralisSolanaFixtures.regularAssetsInCoreCollection)
        let coreAssets = try #require(MoralisSolanaFixtures.decodeResponse(MoralisSolanaFixtures.coreSameAddressDifferentNamesResponse).result)

        let collections = mapper.map(regularAssets: regularAssets, coreAssets: coreAssets, ownerAddress: ownerAddress)
            .sorted { $0.id.collectionIdentifier < $1.id.collectionIdentifier }

        #expect(collections.map(\.id.collectionIdentifier) == [
            "CoreCollection11111111111111111111111111111",
            "CoreCollection77777777777777777777777777777",
        ])
        #expect(collections.map(\.name) == ["Collector Crypt", "Named"])
        #expect(collections.map(\.assetsCount) == [1, 2])
        #expect(collections.last?.description == nil)
    }

    @Test
    func groupsRegularAssetsOfOneAddressTogetherWhenNamesDiffer() throws {
        let regularAssets = try MoralisSolanaFixtures.decodeRegularAssets(MoralisSolanaFixtures.regularAssetsInCoreCollection)
            + MoralisSolanaFixtures.decodeRegularAssets(MoralisSolanaFixtures.regularAssetsWithOtherCollectionName)

        let collections = mapper.map(regularAssets: regularAssets, coreAssets: [], ownerAddress: ownerAddress)

        #expect(collections.count == 1)
        #expect(collections.first?.name == "Collector Crypt")
        #expect(collections.first?.assetsCount == 2)
    }

    @Test
    func groupsRegularAndCoreAssetsOfOneAddressWhateverTheirNames() throws {
        let regularAssets = try MoralisSolanaFixtures.decodeRegularAssets(MoralisSolanaFixtures.regularAssetsOfOneAddressWithVariousNames)
        let coreAssets = try #require(MoralisSolanaFixtures.decodeResponse(MoralisSolanaFixtures.coreSameAddressDifferentNamesResponse).result)

        let collections = mapper.map(regularAssets: regularAssets, coreAssets: coreAssets, ownerAddress: ownerAddress)

        #expect(collections.count == 1)
        #expect(collections.first?.id.collectionIdentifier == "CoreCollection77777777777777777777777777777")
        #expect(collections.first?.assetsCount == 5)
    }

    @Test
    func groupsCoreAssetsOfOneAddressTogetherWhenNamesDiffer() throws {
        let coreAssets = try #require(MoralisSolanaFixtures.decodeResponse(MoralisSolanaFixtures.coreSameAddressDifferentNamesResponse).result)

        let collections = mapper.map(regularAssets: [], coreAssets: coreAssets, ownerAddress: ownerAddress)

        #expect(collections.count == 1)
        #expect(collections.first?.name == "Named")
        #expect(collections.first?.assetsCount == 2)
    }

    @Test
    func keepsMetadataImageNextToVideoMedia() throws {
        let coreAssets = try #require(MoralisSolanaFixtures.decodeResponse(MoralisSolanaFixtures.coreVideoResponse).result)

        let collections = mapper.map(regularAssets: [], coreAssets: coreAssets, ownerAddress: ownerAddress)

        let asset = try #require(collections.first?.assetsResult.value.first)
        #expect(asset.mediaFiles.map(\.kind) == [.video, .image])
        #expect(NFTAssetMediaExtractor.extractMedia(from: asset)?.url == URL(string: "https://example.com/preview.png"))
    }

    @Test
    func keepsRegularAssetsUnchangedWithoutCoreAssets() throws {
        let regularAssets = try MoralisSolanaFixtures.decodeRegularAssets(MoralisSolanaFixtures.regularAssetsInCoreCollection)

        let collections = mapper.map(regularAssets: regularAssets, coreAssets: [], ownerAddress: ownerAddress)

        let collection = try #require(collections.first)
        #expect(collections.count == 1)
        #expect(collection.name == "Collector Crypt")

        let asset = try #require(collection.assetsResult.value.first)
        #expect(asset.id.contractAddress == "RegularMint111111111111111111111111111111111")
        #expect(asset.id.contractType == .analyticsOnly("4"))
    }

    @Test
    func putsEveryAddresslessAssetIntoOneNoCollectionBucket() throws {
        let regularAssets = try MoralisSolanaFixtures.decodeRegularAssets(MoralisSolanaFixtures.regularAssetInNamedCollectionWithoutAddress)
            + MoralisSolanaFixtures.decodeRegularAssets(MoralisSolanaFixtures.regularAssetWithoutCollection)
            + MoralisSolanaFixtures.decodeRegularAssets(MoralisSolanaFixtures.regularAssetWithEmptyCollectionAddress)
        let coreAssets = try #require(MoralisSolanaFixtures.decodeResponse(MoralisSolanaFixtures.addresslessCoreResponse).result)

        let collections = mapper.map(regularAssets: regularAssets, coreAssets: coreAssets, ownerAddress: ownerAddress)

        #expect(collections.count == 1)
        #expect(collections.first?.id.collectionIdentifier == NFTDummyCollectionMapper.dummyCollectionIdentifier)
        #expect(collections.first?.assetsCount == 5)
    }

    @Test(arguments: [false, true])
    func keepsEachRegularAssetsOwnCollectionDescription(reversed: Bool) throws {
        let regularAssets = try MoralisSolanaFixtures.decodeRegularAssets(MoralisSolanaFixtures.regularAssetInNamedCollectionWithoutAddress)
            + MoralisSolanaFixtures.decodeRegularAssets(MoralisSolanaFixtures.regularAssetWithoutCollection)

        let collections = mapper.map(
            regularAssets: reversed ? regularAssets.reversed() : regularAssets,
            coreAssets: [],
            ownerAddress: ownerAddress
        )

        let assets = try #require(collections.first?.assetsResult.value)
        #expect(assets.first { $0.name == "Regular named loose" }?.description == "Named description")
        #expect(assets.first { $0.name == "Regular loose" }?.description == nil)
    }

    @Test
    func dropsCoreAssetWithoutTokenAddress() throws {
        let coreAssets = try #require(MoralisSolanaFixtures.decodeResponse(MoralisSolanaFixtures.coreAssetWithoutTokenAddressResponse).result)

        let collections = mapper.map(regularAssets: [], coreAssets: coreAssets, ownerAddress: ownerAddress)

        #expect(collections.first?.assetsCount == 0)
    }

    @Test
    func coreContractTypeSurvivesCacheRoundTrip() {
        let serialized = NFTCachedModels.ContractTypeUtils.serialize(.other("MplCore"))

        #expect(NFTCachedModels.ContractTypeUtils.deserialize(contractTypeIdentifier: serialized) == .other("MplCore"))
    }
}
