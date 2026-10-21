//
//  SolanaNFTTransferBuilderTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift
import Testing
@testable import BlockchainSdk

struct SolanaNFTTransferBuilderTests {
    private typealias Programmable = SolanaNFTFixtures.Programmable
    private typealias Core = SolanaNFTFixtures.Core

    private let tokenMetadataProgramId = "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s"
    private let coreProgramId = "CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d"
    private let tokenProgramId = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
    private let token2022ProgramId = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
    private let recipient = "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"
    private let supportedTransactionSize = 964

    // MARK: - Core

    @Test
    func routesACoreAssetToTransferV1WithItsCollection() async throws {
        let builder = makeBuilder(accounts: coreAccounts())

        let plan = try await programPlan(builder.route(assetAddress: Core.asset, owner: Core.owner, destination: recipient, payer: Core.owner))

        #expect(plan.instructions.count == 1)
        #expect(plan.instructions[0].programId == coreProgramId)
        #expect(plan.instructions[0].accounts[1].address == Core.collection)
        #expect(plan.instructions[0].accounts[4].address == recipient)
        #expect(plan.createdAccountSpaces.isEmpty)
    }

    @Test
    func refusesACoreAssetOwnedBySomeoneElse() async {
        let builder = makeBuilder(accounts: coreAccounts())

        await #expect(throws: SolanaNFTTransferError.notOwner) {
            try await builder.route(assetAddress: Core.asset, owner: recipient, destination: Core.owner, payer: recipient)
        }
    }

    @Test
    func refusesAFrozenCoreAsset() async {
        var assetData = Core.assetAccountData
        assetData[Core.assetFreezeFlagOffset] = 1
        let builder = makeBuilder(accounts: coreAccounts(assetData: assetData))

        await #expect(throws: SolanaNFTTransferError.frozen) {
            try await builder.route(assetAddress: Core.asset, owner: Core.owner, destination: recipient, payer: Core.owner)
        }
    }

    @Test
    func refusesACoreAssetInAFrozenCollection() async {
        var collectionData = Core.collectionAccountData
        collectionData[Core.collectionFreezeFlagOffset] = 1
        let builder = makeBuilder(accounts: coreAccounts(collectionData: collectionData))

        await #expect(throws: SolanaNFTTransferError.frozen) {
            try await builder.route(assetAddress: Core.asset, owner: Core.owner, destination: recipient, payer: Core.owner)
        }
    }

    @Test
    func refusesACoreAssetWithAnExternalTransferCheck() async {
        let assetData = Core.assetAccountData(withExternalPluginCheckingEvent: 1)
        let builder = makeBuilder(accounts: [Core.asset: SolanaRawAccount(owner: coreProgramId, data: assetData)])

        await #expect(throws: SolanaNFTTransferError.unsupportedAsset) {
            try await builder.route(assetAddress: Core.asset, owner: Core.owner, destination: recipient, payer: Core.owner)
        }
    }

    @Test
    func refusesToSendACoreAssetToItself() async {
        let builder = makeBuilder(accounts: coreAccounts())

        await #expect(throws: SolanaNFTTransferError.invalidDestination) {
            try await builder.route(assetAddress: Core.asset, owner: Core.owner, destination: Core.asset, payer: Core.owner)
        }
    }

    @Test
    func fitsACoreTransferIntoTheCardSigningLimit() async throws {
        let builder = makeBuilder(accounts: coreAccounts())
        let plan = try await programPlan(builder.route(assetAddress: Core.asset, owner: Core.owner, destination: recipient, payer: Core.owner))

        let messageSize = try messageSize(plan: plan, payer: Core.owner)

        #expect(messageSize == 261)
        #expect(messageSize <= supportedTransactionSize)
    }

    // MARK: - Programmable

    @Test
    func routesAProgrammableNFTAndFundsTheMissingDestinationAccounts() async throws {
        let builder = makeBuilder(accounts: programmableAccounts())

        let plan = try await programPlan(builder.route(
            assetAddress: Programmable.mint,
            owner: Programmable.owner,
            destination: Programmable.destinationOwner,
            payer: Programmable.owner
        ))

        #expect(plan.instructions.map(\.programId) == [tokenMetadataProgramId])
        #expect(plan.instructions[0].accounts.last?.address == Programmable.ruleSet)
        #expect(plan.createdAccountSpaces == [165, 80])
    }

    @Test
    func fundsNothingWhenTheDestinationAccountsExist() async throws {
        var accounts = programmableAccounts()
        accounts[Programmable.destinationToken] = SolanaRawAccount(owner: tokenProgramId, data: Data(count: 165))
        accounts[Programmable.destinationTokenRecord] = SolanaRawAccount(owner: tokenMetadataProgramId, data: Programmable.unlockedTokenRecordData)
        let builder = makeBuilder(accounts: accounts)

        let plan = try await programPlan(builder.route(
            assetAddress: Programmable.mint,
            owner: Programmable.owner,
            destination: Programmable.destinationOwner,
            payer: Programmable.owner
        ))

        #expect(plan.createdAccountSpaces.isEmpty)
    }

    @Test(arguments: [UInt8(1), 2])
    func refusesALockedProgrammableNFT(state: UInt8) async {
        var tokenRecord = Programmable.unlockedTokenRecordData
        tokenRecord[2] = state
        var accounts = programmableAccounts()
        accounts[Programmable.ownerTokenRecord] = SolanaRawAccount(owner: tokenMetadataProgramId, data: tokenRecord)
        let builder = makeBuilder(accounts: accounts)

        await #expect(throws: SolanaNFTTransferError.locked) {
            try await builder.route(
                assetAddress: Programmable.mint,
                owner: Programmable.owner,
                destination: Programmable.destinationOwner,
                payer: Programmable.owner
            )
        }
    }

    @Test
    func refusesAProgrammableNFTWithoutTheOwnerTokenRecord() async {
        var accounts = programmableAccounts()
        accounts[Programmable.ownerTokenRecord] = nil
        let builder = makeBuilder(accounts: accounts)

        await #expect(throws: SolanaNFTTransferError.notOwner) {
            try await builder.route(
                assetAddress: Programmable.mint,
                owner: Programmable.owner,
                destination: Programmable.destinationOwner,
                payer: Programmable.owner
            )
        }
    }

    @Test
    func fitsAProgrammableTransferWithComputeBudgetIntoTheCardSigningLimit() async throws {
        let builder = makeBuilder(accounts: programmableAccounts())
        let plan = try await programPlan(builder.route(
            assetAddress: Programmable.mint,
            owner: Programmable.owner,
            destination: Programmable.destinationOwner,
            payer: Programmable.owner
        ))

        let messageSize = try messageSize(plan: plan, payer: Programmable.owner)

        #expect(messageSize == 632)
        #expect(messageSize <= supportedTransactionSize)
    }

    // MARK: - Plain SPL

    @Test
    func keepsANonProgrammableTokenMetadataNFTOnTheSPLPath() async throws {
        var accounts = programmableAccounts()
        accounts[Programmable.metadata] = SolanaRawAccount(
            owner: tokenMetadataProgramId,
            data: SolanaNFTMetadataBuilder(tokenStandard: 0).build()
        )
        let builder = makeBuilder(accounts: accounts)

        let route = try await builder.route(
            assetAddress: Programmable.mint,
            owner: Programmable.owner,
            destination: Programmable.destinationOwner,
            payer: Programmable.owner
        )

        #expect(route.isSPLToken)
    }

    @Test
    func keepsAMintWithoutMetadataOnTheSPLPath() async throws {
        let builder = makeBuilder(accounts: [Programmable.mint: SolanaRawAccount(owner: tokenProgramId, data: Data(count: 82))])

        let route = try await builder.route(
            assetAddress: Programmable.mint,
            owner: Programmable.owner,
            destination: Programmable.destinationOwner,
            payer: Programmable.owner
        )

        #expect(route.isSPLToken)
    }

    @Test
    func keepsAToken2022MintOnTheSPLPath() async throws {
        let builder = makeBuilder(accounts: [Programmable.mint: SolanaRawAccount(owner: token2022ProgramId, data: Data(count: 82))])

        let route = try await builder.route(
            assetAddress: Programmable.mint,
            owner: Programmable.owner,
            destination: Programmable.destinationOwner,
            payer: Programmable.owner
        )

        #expect(route.isSPLToken)
    }

    // MARK: - Unknown

    @Test
    func refusesAnAssetThatDoesNotExist() async {
        let builder = makeBuilder(accounts: [:])

        await #expect(throws: SolanaNFTTransferError.assetNotFound) {
            try await builder.route(assetAddress: Core.asset, owner: Core.owner, destination: recipient, payer: Core.owner)
        }
    }

    @Test
    func refusesAnAssetOfAnUnknownProgram() async {
        let builder = makeBuilder(accounts: [Core.asset: SolanaRawAccount(owner: "11111111111111111111111111111111", data: Data())])

        await #expect(throws: SolanaNFTTransferError.unsupportedAsset) {
            try await builder.route(assetAddress: Core.asset, owner: Core.owner, destination: recipient, payer: Core.owner)
        }
    }

    // MARK: - Helpers

    private func makeBuilder(accounts: [String: SolanaRawAccount]) -> SolanaNFTTransferBuilder {
        SolanaNFTTransferBuilder(accountProvider: SolanaRawAccountProviderStub(accounts: accounts))
    }

    private func coreAccounts(
        assetData: Data = Core.assetAccountData,
        collectionData: Data = Core.collectionAccountData
    ) -> [String: SolanaRawAccount] {
        [
            Core.asset: SolanaRawAccount(owner: coreProgramId, data: assetData),
            Core.collection: SolanaRawAccount(owner: coreProgramId, data: collectionData),
        ]
    }

    private func programmableAccounts() -> [String: SolanaRawAccount] {
        [
            Programmable.mint: SolanaRawAccount(owner: tokenProgramId, data: Data(count: 82)),
            Programmable.metadata: SolanaRawAccount(owner: tokenMetadataProgramId, data: Programmable.metadataAccountData),
            Programmable.ownerTokenRecord: SolanaRawAccount(owner: tokenMetadataProgramId, data: Programmable.unlockedTokenRecordData),
        ]
    }

    private func programPlan(_ route: SolanaNFTTransferRoute) throws -> SolanaNFTTransferPlan {
        guard case .program(let plan) = route else {
            throw SolanaNFTTransferBuilderTestsError.unexpectedRoute
        }

        return plan
    }

    private func messageSize(plan: SolanaNFTTransferPlan, payer: String) throws -> Int {
        let instructions = SolanaComputeBudgetInstruction.instructions(
            computeUnitLimit: plan.computeUnitLimit,
            computeUnitPrice: 1_000_000
        ) + plan.instructions

        return try SolanaSelfPaidTransaction.make(
            instructions: instructions,
            feePayer: PublicKey(string: payer)!.data,
            blockhash: SolanaBlockhash(value: "11111111111111111111111111111111", fetchedAt: Date())
        ).message.count
    }
}

private struct SolanaRawAccountProviderStub: SolanaRawAccountProvider {
    let accounts: [String: SolanaRawAccount]

    func rawAccountInfo(address: String) async throws -> SolanaRawAccount? {
        accounts[address]
    }
}

private enum SolanaNFTTransferBuilderTestsError: Error {
    case unexpectedRoute
}

private extension SolanaNFTTransferRoute {
    var isSPLToken: Bool {
        if case .splToken = self {
            return true
        }

        return false
    }
}
