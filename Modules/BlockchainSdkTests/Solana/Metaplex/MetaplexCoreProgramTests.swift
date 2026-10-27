//
//  MetaplexCoreProgramTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift
import Testing
@testable import BlockchainSdk

struct MetaplexCoreProgramTests {
    private typealias Fixture = SolanaNFTFixtures.Core

    private let coreProgramId = "CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d"
    private let newOwner = "5Y5zMeo3EtRBt6QFQMmJCyG1xcHfiUDH1buhVryLHarv"

    @Test
    func readsOwnerAndCollectionOfAMainnetAsset() throws {
        let asset = try MetaplexCoreProgram.asset(from: Fixture.assetAccountData)

        #expect(asset.owner.base58EncodedString == Fixture.owner)
        #expect(asset.collection?.base58EncodedString == Fixture.collection)
        #expect(asset.transferBlock == nil)
    }

    @Test
    func detectsAFrozenAsset() throws {
        var data = Fixture.assetAccountData
        data[Fixture.assetFreezeFlagOffset] = 1

        #expect(try MetaplexCoreProgram.asset(from: data).transferBlock == .frozen)
    }

    @Test
    func readsAMainnetCollectionAsNotFrozen() throws {
        #expect(try MetaplexCoreProgram.collectionTransferBlock(data: Fixture.collectionAccountData) == nil)
    }

    @Test
    func detectsAFrozenCollection() throws {
        var data = Fixture.collectionAccountData
        data[Fixture.collectionFreezeFlagOffset] = 1

        #expect(try MetaplexCoreProgram.collectionTransferBlock(data: data) == .frozen)
    }

    @Test
    func readsAnAssetWithoutPlugins() throws {
        var data = Data([1]) + PublicKey(string: Fixture.owner)!.data + Data([0])
        data += Data([0, 0, 0, 0]) + Data([0, 0, 0, 0]) + Data([0])

        let asset = try MetaplexCoreProgram.asset(from: data)

        #expect(asset.collection == nil)
        #expect(asset.transferBlock == nil)
    }

    @Test(arguments: [
        (UInt8(1), MetaplexCoreProgram.TransferBlock?.some(.externalCheck)),
        (3, nil),
    ])
    func detectsAnExternalPluginThatChecksTransfers(lifecycleEvent: UInt8, transferBlock: MetaplexCoreProgram.TransferBlock?) throws {
        let data = Fixture.assetAccountData(withExternalPluginCheckingEvent: lifecycleEvent)

        #expect(try MetaplexCoreProgram.asset(from: data).transferBlock == transferBlock)
    }

    @Test
    func rejectsAPluginRegistryOffsetThatDoesNotFitAnInt() {
        var data = Data([1]) + PublicKey(string: Fixture.owner)!.data + Data([0])
        data += Data([0, 0, 0, 0]) + Data([0, 0, 0, 0]) + Data([0])
        data += Data([3]) + Data(repeating: 0xFF, count: 8)

        #expect(throws: MetaplexAccountError.unsupportedLayout) {
            try MetaplexCoreProgram.asset(from: data)
        }
    }

    @Test
    func rejectsAnAccountThatIsNotAnAsset() {
        #expect(throws: MetaplexAccountError.unexpectedAccountKey) {
            try MetaplexCoreProgram.asset(from: Fixture.collectionAccountData)
        }
    }

    @Test
    func buildsTransferWithCollectionAndOwnerAsPayer() throws {
        let owner = PublicKey(string: Fixture.owner)!

        let instruction = MetaplexCoreProgram.transferInstruction(
            asset: PublicKey(string: Fixture.asset)!,
            collection: PublicKey(string: Fixture.collection)!,
            payer: owner,
            authority: owner,
            newOwner: PublicKey(string: newOwner)!
        )

        #expect(instruction.programId == coreProgramId)
        #expect(instruction.data == Data([0x0E, 0x00]))
        #expect(instruction.accounts.map(\.address) == [
            Fixture.asset,
            Fixture.collection,
            Fixture.owner,
            coreProgramId,
            newOwner,
            coreProgramId,
            coreProgramId,
        ])
        #expect(instruction.accounts.map(\.isSigner) == [false, false, true, false, false, false, false])
        #expect(instruction.accounts.map(\.isWritable) == [true, false, true, false, false, false, false])
    }

    @Test
    func passesASeparateAuthorityAsSigner() throws {
        let instruction = MetaplexCoreProgram.transferInstruction(
            asset: PublicKey(string: Fixture.asset)!,
            collection: nil,
            payer: PublicKey(string: newOwner)!,
            authority: PublicKey(string: Fixture.owner)!,
            newOwner: PublicKey(string: newOwner)!
        )

        #expect(instruction.accounts[1].address == coreProgramId)
        #expect(instruction.accounts[3].address == Fixture.owner)
        #expect(instruction.accounts[3].isSigner)
    }
}
