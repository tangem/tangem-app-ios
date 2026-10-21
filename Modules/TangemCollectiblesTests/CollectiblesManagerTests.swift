//
//  CollectiblesManagerTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CryptoKit
import Foundation
import SolanaSwift
import TangemFoundation
import TangemSdk
import TangemTestKit
import Testing
@testable import BlockchainSdk
@testable import TangemCollectibles

@Suite("CollectiblesManager", .timeLimit(.minutes(1)))
final class CollectiblesManagerTests: LeakTrackingTestSuite {
    typealias SUT = CollectiblesManager

    // MARK: - State

    @Test("Resolves the chain and the device into the account state", arguments: Start.allCases)
    func resolvesState(start: Start) async {
        let (sut, doubles) = await makeSUT(start: start, isMarkedLocally: true)

        #expect(sut.state == start.expectedState)
        #expect(sut.hasAccount == start.hasVisibleVault)
        #expect(doubles.presenceStore.contains(Fixtures.userWalletId) == start.keepsPresenceMark)
    }

    @Test("Reads the USDC account only for a vault that is visible on chain", arguments: Start.allCases)
    func balanceFollowsVisibility(start: Start) async {
        let (sut, doubles) = await makeSUT(start: start)
        let usdcStates = PublisherRecorder(sut.vaultUsdcStatePublisher)

        await sut.refreshState()

        if start.hasVisibleVault {
            #expect(doubles.balanceUpdater.updates.map(\.testDescription) == ["loading", "loaded(1000000)"])
            #expect(doubles.usdcReader.requestedColdOwners == [Fixtures.coldOwnerKey])
            #expect(usdcStates.recorded == [.ready(Fixtures.usdcAccount)])
        } else {
            #expect(doubles.balanceUpdater.updates.map(\.testDescription) == ["unavailable"])
            #expect(doubles.usdcReader.requestedColdOwners.isEmpty)
            #expect(usdcStates.recorded == [.missing])
        }
    }

    @Test("Addresses the vault with the derived key, not the seed key")
    func addressesVaultWithDerivedKey() async {
        let (sut, doubles) = await makeSUT()

        await sut.refreshState()

        #expect(doubles.vaultReader.requestedColdOwners == [Fixtures.coldOwnerKey])
    }

    @Test("A failed read keeps the last known state and reports the failure on the balance")
    func failedReadKeepsLastKnownState() async {
        let (sut, doubles) = await makeSUT()
        let states = PublisherRecorder(sut.statePublisher)
        doubles.vaultReader.error = TestError.chain

        await sut.refreshState()

        #expect(sut.state == .ready(Fixtures.vault()))
        #expect(states.recorded == [.ready(Fixtures.vault())])
        #expect(doubles.balanceUpdater.updates.map(\.testDescription) == ["failed"])
        #expect(doubles.presenceStore.contains(Fixtures.userWalletId))
    }

    @Test("Re-resolving publishes real changes only, and the account answer only when it flips")
    func republishesOnlyChanges() async {
        let (sut, doubles) = await makeSUT()
        let states = PublisherRecorder(sut.statePublisher)
        let accountAnswers = PublisherRecorder(sut.hasAccountPublisher)

        await sut.refreshState()
        doubles.vaultReader.vault = Fixtures.vault(spentToday: 5)
        await sut.refreshState()
        doubles.vaultReader.vault = nil
        await sut.refreshState()

        #expect(states.recorded == [.ready(Fixtures.vault()), .ready(Fixtures.vault(spentToday: 5)), .notOnboarded])
        #expect(accountAnswers.recorded == [true, false])
        #expect(!doubles.presenceStore.contains(Fixtures.userWalletId))
    }

    @Test("While nothing has resolved, the account answer comes from the local mark", arguments: [true, false])
    func unresolvedAccountFallsBackToLocalMark(isMarkedLocally: Bool) async {
        let (sut, _) = await makeSUT(vaultReadError: TestError.chain, isMarkedLocally: isMarkedLocally)

        #expect(sut.state == .unresolved)
        #expect(sut.hasAccount == isMarkedLocally)
    }

    @Test("A read failure marks the USDC state failed until a refresh recovers it")
    func usdcStateRecoversAfterFailure() async {
        let (sut, doubles) = await makeSUT(vaultReadError: TestError.chain)
        let usdcStates = PublisherRecorder(sut.vaultUsdcStatePublisher)
        doubles.vaultReader.error = nil

        await sut.refreshState()

        #expect(usdcStates.recorded == [.failed, .loading, .ready(Fixtures.usdcAccount)])
        #expect(sut.state == .ready(Fixtures.vault()))
    }

    // MARK: - Onboarding

    @Test("An account that is already ready has nothing to set up")
    func onboardingOfReadyAccountDoesNothing() async throws {
        let (sut, doubles) = await makeSUT()

        try await sut.onboard()

        #expect(doubles.chainService.broadcasts.isEmpty)
        #expect(doubles.coldKeyInteractor.deriveCount == 0)
        #expect(doubles.sessionKeySigner.generateCount == 0)
        #expect(doubles.balanceUpdater.updates.map(\.testDescription) == ["loading", "loaded(1000000)"])
    }

    @Test("Deploys the vault with its USDC account under a freshly generated session key")
    func onboardingDeploysVault() async throws {
        let (sut, doubles) = await makeSUT(start: .notOnboarded, holdsSessionKey: false)
        doubles.chainService.onSend = { [vaultReader = doubles.vaultReader] in vaultReader.land(Fixtures.vault(sessionKey: Fixtures.generatedSessionKey)) }

        try await sut.onboard()

        let transaction = try #require(doubles.chainService.transactions.first)
        #expect(doubles.chainService.transactions.count == 1)
        #expect(doubles.chainService.broadcasts.count == 1)
        #expect(transaction.feePayer == Fixtures.coldOwnerKey)
        #expect(transaction.instructions.count == 2)
        #expect(transaction.instructions.first?.programId == CollectiblesChainEnvironment.programId)
        #expect(transaction.instructions.first?.data.prefix(8) == CollectiblesVaultProgram.instructionDiscriminator("init_vault"))
        #expect(transaction.instructions.last?.programId == SolanaSwift.PublicKey.splAssociatedTokenAccountProgramId.base58EncodedString)
        #expect(doubles.sessionKeySigner.generateCount == 1)
        #expect(doubles.coldKeyInteractor.deriveCount == 0)
        #expect(doubles.coldKeyInteractor.signedMessages == [transaction.message])
        #expect(doubles.coldKeyInteractor.signedColdKeys == [Fixtures.coldOwner])
        #expect(sut.state == .ready(Fixtures.vault(sessionKey: Fixtures.generatedSessionKey)))
    }

    @Test("Derives the cold key and sets the vault up within the same session for a fresh wallet")
    func onboardingDerivesAndDeploys() async throws {
        let (sut, doubles) = await makeSUT(start: .coldOwnerNotDerived, holdsSessionKey: false)
        doubles.chainService.onSend = { [vaultReader = doubles.vaultReader] in vaultReader.land(Fixtures.vault(sessionKey: Fixtures.generatedSessionKey)) }

        try await sut.onboard()

        let transaction = try #require(doubles.chainService.transactions.first)
        #expect(doubles.coldKeyInteractor.deriveCount == 1)
        #expect(doubles.chainService.broadcasts.count == 1)
        #expect(transaction.instructions.first?.data.prefix(8) == CollectiblesVaultProgram.instructionDiscriminator("init_vault"))
        #expect(sut.state == .ready(Fixtures.vault(sessionKey: Fixtures.generatedSessionKey)))
        #expect(doubles.presenceStore.contains(Fixtures.userWalletId))
    }

    @Test("Points a vault naming a foreign session key back at the held one, keeping the held key")
    func onboardingRekeysVault() async throws {
        let (sut, doubles) = await makeSUT(start: .rekeyMismatch)
        doubles.chainService.onSend = { [vaultReader = doubles.vaultReader] in vaultReader.land(Fixtures.vault()) }

        try await sut.onboard()

        let transaction = try #require(doubles.chainService.transactions.first)
        #expect(transaction.instructions.count == 1)
        #expect(transaction.instructions.first?.data.prefix(8) == CollectiblesVaultProgram.instructionDiscriminator("update_vault"))
        #expect(transaction.feePayer == Fixtures.coldOwnerKey)
        #expect(doubles.sessionKeySigner.generateCount == 0)
        #expect(doubles.chainService.broadcasts.first?.startSendingTimestamp == Fixtures.blockhashFetchedAt)
        #expect(sut.state == .ready(Fixtures.vault()))
    }

    @Test("A step that landed is not repeated while the chain catches up")
    func onboardingWaitsForLaggingChain() async throws {
        let (sut, doubles) = await makeSUT(start: .notOnboarded)
        doubles.chainService.onSend = { [vaultReader = doubles.vaultReader] in vaultReader.land(Fixtures.vault(), afterStaleReads: 3) }

        try await sut.onboard()

        #expect(doubles.chainService.broadcasts.count == 1)
        #expect(doubles.delayProvider.waits == [2, 2, 2])
        #expect(sut.state == .ready(Fixtures.vault()))
    }

    @Test("A step that never shows up on chain fails once the wait runs out")
    func onboardingGivesUpOnStuckStep() async {
        let (sut, doubles) = await makeSUT(start: .notOnboarded)

        let error = await #expect(throws: CollectiblesOnboardingError.self) {
            try await sut.onboard()
        }

        #expect(doubles.chainService.broadcasts.count == 1)
        #expect(doubles.delayProvider.waits.count == 10)
        #expect(sut.state == .notOnboarded)

        if case .stepDidNotAdvance(let step)? = error {
            #expect(step == .vault(.deploy))
        } else {
            Issue.record("Expected the deploy step to be reported as stuck, got \(String(describing: error))")
        }
    }

    @Test("A broadcast that fails stops the onboarding at the resolved state")
    func onboardingStopsOnBroadcastFailure() async {
        let (sut, doubles) = await makeSUT(start: .notOnboarded)
        doubles.chainService.sendError = TestError.chain

        await #expect(throws: TestError.chain) {
            try await sut.onboard()
        }
        #expect(sut.state == .notOnboarded)
    }

    @Test("A deploy the node already holds counts as sent")
    func onboardingAcceptsAlreadyProcessedDeploy() async throws {
        let (sut, doubles) = await makeSUT(start: .notOnboarded)
        doubles.vaultReader.land(Fixtures.vault(), afterStaleReads: 1)
        doubles.chainService.sendError = SolanaSendError.alreadyProcessed

        try await sut.onboard()

        #expect(doubles.chainService.broadcasts.count == 1)
        #expect(sut.state == .ready(Fixtures.vault()))
    }

    @Test("A session key that cannot be read stops the rekey before anything is signed")
    func onboardingStopsWhenSessionKeyIsUnreadable() async {
        let (sut, doubles) = await makeSUT(start: .rekeyUnreadable)

        await #expect(throws: TestError.sessionKey) {
            try await sut.onboard()
        }
        #expect(doubles.chainService.transactions.isEmpty)
        #expect(doubles.sessionKeySigner.generateCount == 0)
        #expect(sut.state == .rekeyRequired(Fixtures.vault()))
    }

    // MARK: - Caps

    @Test("Updates both caps with one cold-signed update_vault and waits for them to show up")
    func updateCapsSignsAndWaitsForChain() async throws {
        let (sut, doubles) = await makeSUT()
        let updatedVault = Fixtures.vault(perSpinCap: 1_000, dailyCap: 2_000)
        doubles.chainService.onSend = { [vaultReader = doubles.vaultReader] in vaultReader.land(updatedVault, afterStaleReads: 1) }

        try await sut.updateCaps(perSpinCap: 1_000, dailyCap: 2_000)

        let transaction = try #require(doubles.chainService.transactions.first)
        #expect(doubles.chainService.transactions.count == 1)
        #expect(transaction.instructions.count == 1)
        #expect(transaction.instructions.first?.data.prefix(8) == CollectiblesVaultProgram.instructionDiscriminator("update_vault"))
        #expect(transaction.feePayer == Fixtures.coldOwnerKey)
        #expect(doubles.coldKeyInteractor.signedColdKeys == [Fixtures.coldOwner])
        #expect(doubles.delayProvider.waits == [2, 2])
        #expect(sut.state == .ready(updatedVault))
    }

    // MARK: - Deposit

    @Test("Waits for the deposit by polling silently until the vault balance grows")
    func awaitDepositReturnsOnceBalanceGrows() async {
        let (sut, doubles) = await makeSUT()
        doubles.usdcReader.enqueue([
            .success(Fixtures.usdcInfo(balance: 1_000_000)),
            .success(Fixtures.usdcInfo(balance: 1_500_000)),
        ])

        await sut.awaitDeposit()

        #expect(doubles.usdcReader.requestedColdOwners.count == 2)
        #expect(doubles.delayProvider.waits == [5])
        #expect(doubles.balanceUpdater.updates.map(\.testDescription) == ["loaded(1000000)", "loaded(1500000)"])
    }

    @Test("Gives up on the deposit after the last poll")
    func awaitDepositGivesUpAfterLastPoll() async {
        let (sut, doubles) = await makeSUT()

        await sut.awaitDeposit()

        #expect(doubles.usdcReader.requestedColdOwners.count == 18)
        #expect(doubles.delayProvider.waits.count == 17)
    }

    // MARK: - Purchase

    @Test("Purchase addresses point at the cold owner once the vault is ready")
    func purchaseAddressesOfReadyVault() async {
        let (sut, _) = await makeSUT()
        let address = Fixtures.coldOwnerKey.base58EncodedString

        #expect(sut.purchaseAddresses == CollectiblesPurchaseAddresses(player: address, prizeRecipient: address))
    }

    @Test("There are no purchase addresses before the vault is ready", arguments: Start.allCases.filter { $0 != .ready })
    func noPurchaseAddressesBeforeReady(start: Start) async {
        let (sut, _) = await makeSUT(start: start)

        #expect(sut.purchaseAddresses == nil)
    }

    @Test("Signs the purchase with the session key paying the fee, without sending it")
    func signPurchaseBuildsSessionKeyTransaction() async throws {
        let (sut, doubles) = await makeSUT()

        let signed = try await sut.signPurchase(Fixtures.purchase(), confirmedPrice: Fixtures.confirmedPrice())

        let transaction = try #require(doubles.chainService.transactions.first)
        #expect(doubles.chainService.transactions.count == 1)
        #expect(transaction.feePayer == Fixtures.heldSessionKey)
        #expect(transaction.instructions.count == 2)
        #expect(transaction.instructions.first?.programId == "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr")
        #expect(transaction.instructions.first.map { String(decoding: $0.data, as: UTF8.self) } == "order-1:open")
        #expect(transaction.instructions.last?.data.prefix(8) == CollectiblesVaultProgram.instructionDiscriminator("purchase_pack"))
        #expect(doubles.sessionKeySigner.signedMessages == [transaction.message])
        #expect(signed.signature == doubles.sessionKeySigner.signatures.last?.base58EncodedString)
        #expect(signed.amount == 10_000_000)
        #expect(signed.feeAmount == 200_000)
        #expect(signed.blockhashFetchedAt == Fixtures.blockhashFetchedAt)
        #expect(doubles.chainService.broadcasts.isEmpty)
    }

    @Test("A fee below the confirmed one is accepted")
    func signPurchaseAcceptsLowerFee() async throws {
        let (sut, _) = await makeSUT()

        let signed = try await sut.signPurchase(Fixtures.purchase(feeAmount: 150_000), confirmedPrice: Fixtures.confirmedPrice())

        #expect(signed.feeAmount == 150_000)
    }

    @Test("A purchase the price, the config or the vault disagrees with is refused", arguments: Rejection.allCases)
    func signPurchaseRefusesDisagreement(rejection: Rejection) async {
        let (sut, doubles) = await makeSUT()

        await #expect(throws: (any Error).self) {
            try await sut.signPurchase(rejection.purchase, confirmedPrice: rejection.confirmedPrice)
        }
        #expect(doubles.sessionKeySigner.signedMessages.isEmpty)
        #expect(doubles.chainService.transactions.isEmpty)
    }

    @Test("Signing is refused until the vault is ready", arguments: [Start.notOnboarded, .rekeyMismatch])
    func signPurchaseRefusedBeforeReady(start: Start) async {
        let (sut, doubles) = await makeSUT(start: start)

        await #expect(throws: (any Error).self) {
            try await sut.signPurchase(Fixtures.purchase(), confirmedPrice: Fixtures.confirmedPrice())
        }
        #expect(doubles.chainService.transactions.isEmpty)
    }

    @Test("Signing the same order again reuses the first signature")
    func signPurchaseReusesSignature() async throws {
        let (sut, doubles) = await makeSUT()

        let first = try await sut.signPurchase(Fixtures.purchase(), confirmedPrice: Fixtures.confirmedPrice())
        let second = try await sut.signPurchase(Fixtures.purchase(), confirmedPrice: Fixtures.confirmedPrice())

        #expect(first.signature == second.signature)
        #expect(doubles.sessionKeySigner.signedMessages.count == 1)
    }

    @Test("An order signed again with another amount is a conflict")
    func signPurchaseDetectsConflict() async throws {
        let (sut, doubles) = await makeSUT()
        _ = try await sut.signPurchase(Fixtures.purchase(), confirmedPrice: Fixtures.confirmedPrice())

        await #expect(throws: (any Error).self) {
            try await sut.signPurchase(
                Fixtures.purchase(amount: 20_000_000, feeAmount: 400_000),
                confirmedPrice: Fixtures.confirmedPrice(amount: 20_000_000, feeAmount: 400_000)
            )
        }
        #expect(doubles.sessionKeySigner.signedMessages.count == 1)
    }

    @Test("A failed signing is forgotten so the order can be signed again")
    func signPurchaseRetriesAfterFailure() async throws {
        let (sut, doubles) = await makeSUT()
        doubles.sessionKeySigner.signError = TestError.signing

        await #expect(throws: TestError.signing) {
            try await sut.signPurchase(Fixtures.purchase(), confirmedPrice: Fixtures.confirmedPrice())
        }
        doubles.sessionKeySigner.signError = nil
        let signed = try await sut.signPurchase(Fixtures.purchase(), confirmedPrice: Fixtures.confirmedPrice())

        #expect(signed.signature == doubles.sessionKeySigner.signatures.last?.base58EncodedString)
        #expect(doubles.sessionKeySigner.signedMessages.count == 2)
    }

    // MARK: - Send

    @Test("Sends the signed bytes with the blockhash time they were built at")
    func sendPurchaseBroadcasts() async throws {
        let (sut, doubles) = await makeSUT()
        let signed = try await sut.signPurchase(Fixtures.purchase(), confirmedPrice: Fixtures.confirmedPrice())

        try await sut.sendPurchase(signed)

        #expect(doubles.chainService.broadcasts.count == 1)
        #expect(doubles.chainService.broadcasts.first?.serializedTransaction == signed.serializedTransaction)
        #expect(doubles.chainService.broadcasts.first?.startSendingTimestamp == Fixtures.blockhashFetchedAt)
    }

    @Test("A response lost on the way counts as sent")
    func sendPurchaseAcceptsAlreadyProcessed() async throws {
        let (sut, doubles) = await makeSUT()
        let signed = try await sut.signPurchase(Fixtures.purchase(), confirmedPrice: Fixtures.confirmedPrice())
        doubles.chainService.sendError = SolanaSendError.alreadyProcessed

        try await sut.sendPurchase(signed)

        #expect(doubles.chainService.broadcasts.count == 1)
    }

    @Test("Send failures are told apart", arguments: SendFailure.allCases)
    func sendPurchaseTellsFailuresApart(failure: SendFailure) async throws {
        let (sut, doubles) = await makeSUT()
        doubles.chainService.blockhashFetchedAt = failure.blockhashFetchedAt
        let signed = try await sut.signPurchase(Fixtures.purchase(), confirmedPrice: Fixtures.confirmedPrice())
        doubles.chainService.sendError = try failure.makeError()

        let error = await #expect(throws: CollectiblesPurchaseError.self) {
            try await sut.sendPurchase(signed)
        }

        #expect(error?.testDescription == failure.expectedDescription)
    }
}

// MARK: - Arguments

extension CollectiblesManagerTests {
    enum Start: CaseIterable {
        case ready
        case rekeyMismatch
        case rekeyUnreadable
        case notOnboarded
        case coldOwnerNotDerived

        var expectedState: CollectiblesState {
            switch self {
            case .ready: .ready(Fixtures.vault())
            case .rekeyMismatch: .rekeyRequired(Fixtures.vault(sessionKey: Fixtures.foreignSessionKey))
            case .rekeyUnreadable: .rekeyRequired(Fixtures.vault())
            case .notOnboarded: .notOnboarded
            case .coldOwnerNotDerived: .coldOwnerNotDerived
            }
        }

        var keepsPresenceMark: Bool {
            self != .notOnboarded
        }

        var hasVisibleVault: Bool {
            switch self {
            case .ready, .rekeyMismatch, .rekeyUnreadable: true
            case .notOnboarded, .coldOwnerNotDerived: false
            }
        }

        var vaultOnChain: CollectiblesVaultInfo? {
            switch self {
            case .ready, .rekeyUnreadable: Fixtures.vault()
            case .rekeyMismatch: Fixtures.vault(sessionKey: Fixtures.foreignSessionKey)
            case .notOnboarded, .coldOwnerNotDerived: nil
            }
        }
    }

    enum Rejection: CaseIterable {
        case amountMismatch
        case feeAboveConfirmed
        case mintMismatch
        case feeOutsideCorridor
        case exceedsLimits

        var purchase: CollectiblesPackPurchase {
            switch self {
            case .amountMismatch: Fixtures.purchase(amount: 10_000_001)
            case .feeAboveConfirmed: Fixtures.purchase(feeAmount: 200_001)
            case .mintMismatch: Fixtures.purchase(usdcMint: Fixtures.foreignSessionKey.base58EncodedString)
            case .feeOutsideCorridor: Fixtures.purchase(feeAmount: 50_000)
            case .exceedsLimits: Fixtures.purchase(amount: 60_000_000, feeAmount: 1_200_000)
            }
        }

        var confirmedPrice: CollectiblesConfirmedPrice {
            switch self {
            case .amountMismatch, .feeAboveConfirmed, .mintMismatch: Fixtures.confirmedPrice()
            case .feeOutsideCorridor: Fixtures.confirmedPrice(feeAmount: 50_000)
            case .exceedsLimits: Fixtures.confirmedPrice(amount: 60_000_000, feeAmount: 1_200_000)
            }
        }
    }

    enum SendFailure: CaseIterable {
        case blockhashNotFound
        case nodeRejection
        case staleNodeRejection
        case programRejection
        case unknown

        var blockhashFetchedAt: Date {
            switch self {
            case .nodeRejection, .programRejection: Date()
            case .blockhashNotFound, .staleNodeRejection, .unknown: Fixtures.blockhashFetchedAt
            }
        }

        var expectedDescription: String {
            switch self {
            case .blockhashNotFound, .staleNodeRejection: "transactionExpired"
            case .nodeRejection, .programRejection: "rejected"
            case .unknown: "sendOutcomeUnknown"
            }
        }

        func makeError() throws -> any Error {
            switch self {
            case .blockhashNotFound:
                SolanaSwift.RPCError.invalidResponse(try Self.responseError("Blockhash not found"))
            case .nodeRejection, .staleNodeRejection:
                SolanaSwift.RPCError.invalidResponse(try Self.responseError("Transaction simulation failed: Error processing Instruction 1"))
            case .programRejection:
                SolanaSendError.programError(code: 101, logs: [])
            case .unknown:
                TestError.chain
            }
        }

        private static func responseError(_ message: String) throws -> SolanaSwift.ResponseError {
            try JSONDecoder().decode(SolanaSwift.ResponseError.self, from: Data(#"{"message": "\#(message)"}"#.utf8))
        }
    }
}

// MARK: - Helpers

private extension CollectiblesManagerTests {
    enum Fixtures {
        static let userWalletId = UserWalletId(value: Data(repeating: 0x77, count: 32))
        static let coldOwnerSeed = Data(repeating: 0x11, count: 32)
        static let coldOwnerKey = signingKey(seed: 0x44).publicKey.rawRepresentation
        static let heldSessionKey = signingKey(seed: 0x22).publicKey.rawRepresentation
        static let foreignSessionKey = Data(repeating: 0x33, count: 32)
        static let generatedSessionKey = signingKey(seed: 0x99).publicKey.rawRepresentation
        static let usdcMint = Data(repeating: 0x55, count: 32)
        static let blockhash = Data(repeating: 0x66, count: 32).base58EncodedString
        static let blockhashFetchedAt = Date(timeIntervalSince1970: 1_700_000_000)
        static let usdcAccount = CollectiblesVaultUsdcAccount(
            address: "7UX2i7SucgLMQcfZ75s3VXmZZY4YRUyJN9X1RgfMoDUi",
            mint: usdcMint.base58EncodedString
        )
        static let config = CollectiblesConfigInfo(
            usdcMint: usdcMint,
            collectiblesUsdcAccount: Data(repeating: 0x56, count: 32),
            feeUsdcAccount: Data(repeating: 0x57, count: 32),
            minFeeBps: 100,
            maxFeeBps: 300
        )

        static var coldOwner: BlockchainSdk.Wallet.PublicKey {
            let extendedPublicKey = ExtendedPublicKey(publicKey: coldOwnerKey, chainCode: Data(repeating: 0x88, count: 32))
            let hdKey = BlockchainSdk.Wallet.PublicKey.HDKey(path: CollectiblesAccountKeyPath.derivationPath, extendedPublicKey: extendedPublicKey)
            return BlockchainSdk.Wallet.PublicKey(seedKey: coldOwnerSeed, derivationType: .plain(hdKey))
        }

        static var coldOwnerSigningKey: Curve25519.Signing.PrivateKey { signingKey(seed: 0x44) }
        static var heldSessionSigningKey: Curve25519.Signing.PrivateKey { signingKey(seed: 0x22) }
        static var generatedSessionSigningKey: Curve25519.Signing.PrivateKey { signingKey(seed: 0x99) }

        static func signingKey(seed: UInt8) -> Curve25519.Signing.PrivateKey {
            try! Curve25519.Signing.PrivateKey(rawRepresentation: Data(repeating: seed, count: 32))
        }

        static func vault(
            sessionKey: Data = heldSessionKey,
            perSpinCap: UInt64 = 50_000_000,
            dailyCap: UInt64 = 500_000_000,
            spentToday: UInt64 = 0
        ) -> CollectiblesVaultInfo {
            CollectiblesVaultInfo(
                vaultAddress: "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA",
                sessionKey: sessionKey,
                perSpinCap: perSpinCap,
                dailyCap: dailyCap,
                spentToday: spentToday,
                dayIndex: 0
            )
        }

        static func usdcInfo(balance: UInt64 = 1_000_000) -> CollectiblesVaultUsdcInfo {
            CollectiblesVaultUsdcInfo(account: usdcAccount, balance: balance)
        }

        static func purchase(
            memo: String = "order-1",
            usdcMint: String = Fixtures.usdcMint.base58EncodedString,
            amount: UInt64 = 10_000_000,
            feeAmount: UInt64 = 200_000
        ) -> CollectiblesPackPurchase {
            CollectiblesPackPurchase(memo: memo, usdcMint: usdcMint, amount: amount, feeAmount: feeAmount)
        }

        static func confirmedPrice(amount: UInt64 = 10_000_000, feeAmount: UInt64 = 200_000) -> CollectiblesConfirmedPrice {
            CollectiblesConfirmedPrice(amount: amount, feeAmount: feeAmount)
        }
    }

    struct Doubles {
        let coldOwnerProvider: ColdOwnerProviderFake
        let vaultReader: VaultReaderFake
        let usdcReader: VaultUsdcReaderFake
        let balanceUpdater: BalanceUpdaterSpy
        let sessionKeySigner: SessionKeySignerFake
        let coldKeyInteractor: ColdKeyInteractorFake
        let presenceStore: PresenceStoreFake
        let chainService: ChainServiceFake
        let delayProvider: PollDelaySpy
    }

    func makeSUT(
        start: Start = .ready,
        holdsSessionKey: Bool = true,
        vaultReadError: (any Error)? = nil,
        isMarkedLocally: Bool = false
    ) async -> (SUT, Doubles) {
        let coldOwnerProvider = ColdOwnerProviderFake(key: start == .coldOwnerNotDerived ? nil : Fixtures.coldOwner)
        let vaultReader = VaultReaderFake(vault: start.vaultOnChain)
        vaultReader.error = vaultReadError
        let sessionKeySigner = SessionKeySignerFake(
            heldSigningKey: holdsSessionKey ? Fixtures.heldSessionSigningKey : nil,
            generatedSigningKey: Fixtures.generatedSessionSigningKey
        )
        sessionKeySigner.publicKeyError = start == .rekeyUnreadable ? TestError.sessionKey : nil
        let chainService = ChainServiceFake(blockhash: Fixtures.blockhash, blockhashFetchedAt: Fixtures.blockhashFetchedAt)
        let coldKeyInteractor = ColdKeyInteractorFake(signingKey: Fixtures.coldOwnerSigningKey) {
            coldOwnerProvider.set(Fixtures.coldOwner)
        }
        let delayProvider = PollDelaySpy()
        let coldKeyInteractorFactory = ColdKeyInteractorFactoryStub(interactor: coldKeyInteractor)
        let configReader = ConfigReaderFake(config: Fixtures.config)
        let transactionSender = CollectiblesColdKeyTransactionSender(
            serviceProvider: ChainServiceProviderStub(chainService: chainService)
        )
        let doubles = Doubles(
            coldOwnerProvider: coldOwnerProvider,
            vaultReader: vaultReader,
            usdcReader: VaultUsdcReaderFake(result: .success(Fixtures.usdcInfo())),
            balanceUpdater: BalanceUpdaterSpy(),
            sessionKeySigner: sessionKeySigner,
            coldKeyInteractor: coldKeyInteractor,
            presenceStore: PresenceStoreFake(marked: isMarkedLocally ? [Fixtures.userWalletId] : []),
            chainService: chainService,
            delayProvider: delayProvider
        )
        var sut = SUT(
            userWalletId: Fixtures.userWalletId,
            coldOwnerProvider: coldOwnerProvider,
            vaultReader: doubles.vaultReader,
            vaultUsdcReader: doubles.usdcReader,
            balanceUpdater: doubles.balanceUpdater,
            sessionKeySigner: sessionKeySigner,
            coldKeyInteractorFactory: coldKeyInteractorFactory,
            transactionSender: transactionSender,
            onboardingInteractor: CollectiblesOnboardingInteractor(
                coldOwnerProvider: coldOwnerProvider,
                sessionKeySigner: sessionKeySigner,
                configReader: configReader,
                coldKeyInteractorFactory: coldKeyInteractorFactory,
                transactionSender: transactionSender
            ),
            purchaseTransactionDispatcher: CollectiblesPurchaseTransactionDispatcher(
                coldOwnerProvider: coldOwnerProvider,
                configReader: configReader,
                sessionKeySigner: sessionKeySigner,
                transactionSender: transactionSender
            ),
            presenceStore: doubles.presenceStore,
            delayProvider: delayProvider
        )

        await settle(sut, doubles: doubles)

        let isReleasedByInitRefresh = await waitUntil { isKnownUniquelyReferenced(&sut) }
        #expect(isReleasedByInitRefresh, "The refresh started by init still holds the manager")

        trackForMemoryLeaks(doubles.coldOwnerProvider)
        trackForMemoryLeaks(doubles.vaultReader)
        trackForMemoryLeaks(doubles.usdcReader)
        trackForMemoryLeaks(doubles.balanceUpdater)
        trackForMemoryLeaks(doubles.sessionKeySigner)
        trackForMemoryLeaks(doubles.coldKeyInteractor)
        trackForMemoryLeaks(doubles.presenceStore)
        trackForMemoryLeaks(doubles.chainService)
        trackForMemoryLeaks(doubles.delayProvider)

        return (trackForMemoryLeaks(sut), doubles)
    }

    func settle(_ sut: SUT, doubles: Doubles) async {
        let didSettle = await waitUntil { doubles.balanceUpdater.updates.contains { !$0.isLoading } }
        #expect(didSettle, "The refresh started by init did not finish in time")

        await sut.refreshState()

        doubles.balanceUpdater.reset()
        doubles.vaultReader.resetRecords()
        doubles.usdcReader.resetRecords()
    }
}

private func waitUntil(timeout: Duration = .seconds(5), _ condition: () -> Bool) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now + timeout

    while !condition() {
        guard clock.now < deadline else {
            return false
        }

        await Task.yield()
    }

    return true
}

private extension CollectiblesBalanceState {
    var testDescription: String {
        switch self {
        case .loading: "loading"
        case .loaded(let balance): "loaded(\(balance))"
        case .failed: "failed"
        case .unavailable: "unavailable"
        }
    }
}

private extension CollectiblesPurchaseError {
    var testDescription: String {
        switch self {
        case .transactionExpired: "transactionExpired"
        case .sendOutcomeUnknown: "sendOutcomeUnknown"
        case .rejected: "rejected"
        }
    }
}

// MARK: - Doubles

private enum TestError: Error {
    case chain
    case signing
    case sessionKey
    case unexpectedCall
}

private final class PublisherRecorder<Value> {
    private let values = OSAllocatedUnfairLock(uncheckedState: [Value]())
    private var cancellable: AnyCancellable?

    init(_ publisher: AnyPublisher<Value, Never>) {
        cancellable = publisher.sink { [values] value in
            values { $0.append(value) }
        }
    }

    var recorded: [Value] {
        values { $0 }
    }
}

private final class ColdOwnerProviderFake: CollectiblesColdOwnerProvider {
    private let key: OSAllocatedUnfairLock<BlockchainSdk.Wallet.PublicKey?>

    init(key: BlockchainSdk.Wallet.PublicKey?) {
        self.key = OSAllocatedUnfairLock(uncheckedState: key)
    }

    func set(_ newKey: BlockchainSdk.Wallet.PublicKey?) {
        key { $0 = newKey }
    }

    func coldOwnerKey() -> BlockchainSdk.Wallet.PublicKey? {
        key { $0 }
    }
}

private final class VaultReaderFake: CollectiblesVaultReader {
    private struct Landing {
        let vault: CollectiblesVaultInfo?
        var staleReadsRemaining: Int
    }

    private struct State {
        var vault: CollectiblesVaultInfo?
        var landing: Landing?
        var error: (any Error)?
        var requestedColdOwners: [Data] = []
    }

    private let state: OSAllocatedUnfairLock<State>

    init(vault: CollectiblesVaultInfo?) {
        state = OSAllocatedUnfairLock(uncheckedState: State(vault: vault))
    }

    var vault: CollectiblesVaultInfo? {
        get { state { $0.vault } }
        set { state { $0.vault = newValue } }
    }

    var error: (any Error)? {
        get { state { $0.error } }
        set { state { $0.error = newValue } }
    }

    var requestedColdOwners: [Data] {
        state { $0.requestedColdOwners }
    }

    func land(_ vault: CollectiblesVaultInfo?, afterStaleReads staleReads: Int = 0) {
        state { $0.landing = Landing(vault: vault, staleReadsRemaining: staleReads) }
    }

    func resetRecords() {
        state { $0.requestedColdOwners = [] }
    }

    func vaultInfo(coldOwner: Data) async throws -> CollectiblesVaultInfo? {
        try state { state -> CollectiblesVaultInfo? in
            state.requestedColdOwners.append(coldOwner)

            if let error = state.error {
                throw error
            }

            if var landing = state.landing {
                if landing.staleReadsRemaining > 0 {
                    landing.staleReadsRemaining -= 1
                    state.landing = landing
                } else {
                    state.vault = landing.vault
                    state.landing = nil
                }
            }

            return state.vault
        }
    }
}

private final class VaultUsdcReaderFake: CollectiblesVaultUsdcReader {
    private struct State {
        var result: Result<CollectiblesVaultUsdcInfo, any Error>
        var queued: [Result<CollectiblesVaultUsdcInfo, any Error>] = []
        var requestedColdOwners: [Data] = []
    }

    private let state: OSAllocatedUnfairLock<State>

    init(result: Result<CollectiblesVaultUsdcInfo, any Error>) {
        state = OSAllocatedUnfairLock(uncheckedState: State(result: result))
    }

    var requestedColdOwners: [Data] {
        state { $0.requestedColdOwners }
    }

    func resetRecords() {
        state { $0.requestedColdOwners = [] }
    }

    func enqueue(_ results: [Result<CollectiblesVaultUsdcInfo, any Error>]) {
        state { $0.queued = results }
    }

    func usdcAccount(coldOwner: Data) async throws -> CollectiblesVaultUsdcInfo {
        try state { state -> CollectiblesVaultUsdcInfo in
            state.requestedColdOwners.append(coldOwner)

            if !state.queued.isEmpty {
                state.result = state.queued.removeFirst()
            }

            return try state.result.get()
        }
    }
}

private final class ConfigReaderFake: CollectiblesConfigReader {
    private let config: CollectiblesConfigInfo

    init(config: CollectiblesConfigInfo) {
        self.config = config
    }

    func configInfo() async throws -> CollectiblesConfigInfo {
        config
    }
}

private final class BalanceUpdaterSpy: CollectiblesBalanceUpdater {
    private let recorded = OSAllocatedUnfairLock(uncheckedState: [CollectiblesBalanceState]())

    var updates: [CollectiblesBalanceState] {
        recorded { $0 }
    }

    func reset() {
        recorded { $0 = [] }
    }

    func update(_ state: CollectiblesBalanceState) {
        recorded { $0.append(state) }
    }
}

private final class SessionKeySignerFake: CollectiblesSessionKeySigner {
    private struct State {
        var signingKey: Curve25519.Signing.PrivateKey?
        var publicKeyError: (any Error)?
        var signError: (any Error)?
        var generateCount = 0
        var signedMessages: [Data] = []
        var signatures: [Data] = []
    }

    private let state: OSAllocatedUnfairLock<State>
    private let generatedSigningKey: Curve25519.Signing.PrivateKey

    init(heldSigningKey: Curve25519.Signing.PrivateKey?, generatedSigningKey: Curve25519.Signing.PrivateKey) {
        state = OSAllocatedUnfairLock(uncheckedState: State(signingKey: heldSigningKey))
        self.generatedSigningKey = generatedSigningKey
    }

    var publicKeyError: (any Error)? {
        get { state { $0.publicKeyError } }
        set { state { $0.publicKeyError = newValue } }
    }

    var signError: (any Error)? {
        get { state { $0.signError } }
        set { state { $0.signError = newValue } }
    }

    var generateCount: Int {
        state { $0.generateCount }
    }

    var signedMessages: [Data] {
        state { $0.signedMessages }
    }

    var signatures: [Data] {
        state { $0.signatures }
    }

    func generateKey() async throws -> Data {
        state { state in
            state.generateCount += 1
            state.signingKey = generatedSigningKey
        }

        return generatedSigningKey.publicKey.rawRepresentation
    }

    func publicKey() async throws -> Data? {
        try state { state -> Data? in
            if let error = state.publicKeyError {
                throw error
            }

            return state.signingKey?.publicKey.rawRepresentation
        }
    }

    func signSpin(_ message: Data) async throws -> Data {
        try state { state -> Data in
            state.signedMessages.append(message)

            if let error = state.signError {
                throw error
            }

            guard let signingKey = state.signingKey else {
                throw TestError.sessionKey
            }

            let signature = try signingKey.signature(for: message)
            state.signatures.append(signature)
            return signature
        }
    }
}

private final class ColdKeyInteractorFake: CollectiblesColdKeyInteractor {
    private struct State {
        var deriveCount = 0
        var signedMessages: [Data] = []
        var signedColdKeys: [BlockchainSdk.Wallet.PublicKey] = []
    }

    private let state = OSAllocatedUnfairLock(uncheckedState: State())
    private let signingKey: Curve25519.Signing.PrivateKey
    private let onDerive: () -> Void

    init(signingKey: Curve25519.Signing.PrivateKey, onDerive: @escaping () -> Void) {
        self.signingKey = signingKey
        self.onDerive = onDerive
    }

    var deriveCount: Int {
        state { $0.deriveCount }
    }

    var signedMessages: [Data] {
        state { $0.signedMessages }
    }

    var signedColdKeys: [BlockchainSdk.Wallet.PublicKey] {
        state { $0.signedColdKeys }
    }

    func derive<Work: CollectiblesColdKeySessionWork>(andRun work: Work) async throws -> Work.Output {
        state { $0.deriveCount += 1 }
        onDerive()
        return try await work.run(signer: self)
    }

    func sign(message: Data, coldKey: BlockchainSdk.Wallet.PublicKey) async throws -> Data {
        state { state in
            state.signedMessages.append(message)
            state.signedColdKeys.append(coldKey)
        }

        return try signingKey.signature(for: message)
    }
}

private final class ColdKeyInteractorFactoryStub: CollectiblesColdKeyInteractorFactory {
    private let interactor: any CollectiblesColdKeyInteractor

    init(interactor: any CollectiblesColdKeyInteractor) {
        self.interactor = interactor
    }

    func makeInteractor() -> any CollectiblesColdKeyInteractor {
        interactor
    }
}

private final class PresenceStoreFake: CollectiblesAccountPresenceStore {
    private let marked: OSAllocatedUnfairLock<Set<UserWalletId>>

    init(marked: Set<UserWalletId>) {
        self.marked = OSAllocatedUnfairLock(uncheckedState: marked)
    }

    func contains(_ userWalletId: UserWalletId) -> Bool {
        marked { $0.contains(userWalletId) }
    }

    func insert(_ userWalletId: UserWalletId) {
        marked { _ = $0.insert(userWalletId) }
    }

    func remove(_ userWalletId: UserWalletId) {
        marked { _ = $0.remove(userWalletId) }
    }
}

private final class PollDelaySpy: PollDelayProvider {
    private let recorded = OSAllocatedUnfairLock(uncheckedState: [TimeInterval]())

    var waits: [TimeInterval] {
        recorded { $0 }
    }

    func wait(for seconds: TimeInterval) async throws {
        recorded { $0.append(seconds) }
    }
}

private final class ChainServiceProviderStub: CollectiblesChainServiceProvider {
    private let chainService: ChainServiceFake

    init(chainService: ChainServiceFake) {
        self.chainService = chainService
    }

    func service() throws -> any CollectiblesChainService {
        chainService
    }
}

private final class ChainServiceFake: CollectiblesChainService {
    struct BuiltTransaction {
        let instructions: [SolanaRawInstruction]
        let feePayer: Data
        let message: Data
    }

    struct Broadcast {
        let serializedTransaction: Data
        let startSendingTimestamp: Date
    }

    private struct State {
        var blockhashFetchedAt: Date
        var sendError: (any Error)?
        var onSend: (() -> Void)?
        var transactions: [BuiltTransaction] = []
        var broadcasts: [Broadcast] = []
    }

    private let state: OSAllocatedUnfairLock<State>
    private let blockhash: String

    init(blockhash: String, blockhashFetchedAt: Date) {
        self.blockhash = blockhash
        state = OSAllocatedUnfairLock(uncheckedState: State(blockhashFetchedAt: blockhashFetchedAt))
    }

    var blockhashFetchedAt: Date {
        get { state { $0.blockhashFetchedAt } }
        set { state { $0.blockhashFetchedAt = newValue } }
    }

    var sendError: (any Error)? {
        get { state { $0.sendError } }
        set { state { $0.sendError = newValue } }
    }

    var onSend: (() -> Void)? {
        get { state { $0.onSend } }
        set { state { $0.onSend = newValue } }
    }

    var transactions: [BuiltTransaction] {
        state { $0.transactions }
    }

    var broadcasts: [Broadcast] {
        state { $0.broadcasts }
    }

    func account(address: String) async throws -> SolanaRawAccount? {
        throw TestError.unexpectedCall
    }

    func latestBlockhash() async throws -> SolanaBlockhash {
        SolanaBlockhash(value: blockhash, fetchedAt: blockhashFetchedAt)
    }

    func makeSelfPaidTransaction(
        instructions: [SolanaRawInstruction],
        feePayer: Data,
        blockhash: SolanaBlockhash
    ) throws -> SolanaSelfPaidTransaction {
        guard let feePayerKey = SolanaSwift.PublicKey(data: feePayer) else {
            throw TestError.unexpectedCall
        }

        let transaction = SolanaSwift.Transaction.empty(feePayer: feePayerKey, recentBlockhash: blockhash.value)

        for instruction in instructions {
            _ = transaction.add(try Self.transactionInstruction(instruction))
        }

        let message = try transaction.serializeMessage().get()
        state { $0.transactions.append(BuiltTransaction(instructions: instructions, feePayer: feePayer, message: message)) }

        return SolanaSelfPaidTransaction(
            transaction: transaction,
            feePayer: feePayerKey,
            message: message,
            blockhashFetchedAt: blockhash.fetchedAt
        )
    }

    func send(serializedTransaction: Data, startSendingTimestamp: Date) async throws -> String {
        let (error, onSend) = state { state -> ((any Error)?, (() -> Void)?) in
            state.broadcasts.append(Broadcast(serializedTransaction: serializedTransaction, startSendingTimestamp: startSendingTimestamp))
            return (state.sendError, state.onSend)
        }

        if let error {
            throw error
        }

        onSend?()

        return "sent"
    }

    private static func transactionInstruction(_ instruction: SolanaRawInstruction) throws -> SolanaSwift.TransactionInstruction {
        guard let programId = SolanaSwift.PublicKey(string: instruction.programId) else {
            throw TestError.unexpectedCall
        }

        let keys = try instruction.accounts.map { account -> SolanaSwift.Account.Meta in
            guard let publicKey = SolanaSwift.PublicKey(string: account.address) else {
                throw TestError.unexpectedCall
            }

            return SolanaSwift.Account.Meta(publicKey: publicKey, isSigner: account.isSigner, isWritable: account.isWritable)
        }

        return SolanaSwift.TransactionInstruction(keys: keys, programId: programId, data: [UInt8](instruction.data))
    }
}
