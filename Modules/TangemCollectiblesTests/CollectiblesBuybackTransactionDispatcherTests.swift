//
//  CollectiblesBuybackTransactionDispatcherTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift
import TangemFoundation
import TangemSdk
import TangemTestKit
import Testing
@testable import BlockchainSdk
@testable import TangemCollectibles

@Suite("CollectiblesBuybackTransactionDispatcher", .timeLimit(.minutes(1)))
final class CollectiblesBuybackTransactionDispatcherTests: LeakTrackingTestSuite {
    typealias SUT = CollectiblesBuybackTransactionDispatcher
    typealias VerificationError = CollectiblesBuybackTransactionVerifier.VerificationError
    typealias ParsingError = CollectiblesPreparedTransaction.ParsingError

    // MARK: - Sign

    @Test(
        "Signs the partner's message as it arrived and fills only the owner's slot",
        arguments: [MessageVersion.legacy, .v0]
    )
    func signsIntoOwnerSlot(version: MessageVersion) async throws {
        let (sut, doubles) = makeSUT()
        let message = Fixtures.liveMessage(version: version)
        let prepared = Fixtures.serialized(
            signatures: [Fixtures.liveCollectorSignature, Fixtures.emptySignature],
            message: message
        )

        let signed = try await sut.sign(prepared, terms: Fixtures.terms)

        let expected = Fixtures.serialized(
            signatures: [Fixtures.liveCollectorSignature, Fixtures.ownerSignature],
            message: message
        )
        #expect(doubles.coldKeyInteractor.signedMessages == [message])
        #expect(doubles.coldKeyInteractor.signedColdKeys.map(\.blockchainKey) == [Fixtures.ownerKey])
        #expect(signed.serializedTransaction == expected)
        #expect(signed.signature == Fixtures.liveCollectorSignature.base58EncodedString)
    }

    @Test("Refuses a payout to anything but the vault's USDC account before asking for the card")
    func refusesPayoutOutsideVault() async {
        let (sut, doubles) = makeSUT()

        await #expect(throws: VerificationError.foreignPayout) {
            try await sut.sign(Fixtures.liveBuyback, terms: Fixtures.terms)
        }

        #expect(doubles.coldKeyInteractor.signedMessages.isEmpty)
    }

    @Test("Refuses a transaction it cannot complete before asking for the card", arguments: Unsignable.allCases)
    func refusesBeforeCardTap(unsignable: Unsignable) async {
        let (sut, doubles) = makeSUT()

        let error = await #expect(throws: (any Error).self) {
            try await sut.sign(unsignable.serialized, terms: Fixtures.terms)
        }

        #expect(error.map(unsignable.isExpected) == true)
        #expect(doubles.coldKeyInteractor.signedMessages.isEmpty)
    }

    @Test("Refuses a payout below the agreed price before asking for the card")
    func refusesPayoutBelowAgreedPrice() async {
        let (sut, doubles) = makeSUT()
        let terms = CollectiblesBuybackTerms(
            nftAddress: Fixtures.nftAddress,
            minimumPayoutInBaseUnits: Fixtures.payout + 1
        )

        await #expect(throws: VerificationError.payoutBelowAgreedPrice) {
            try await sut.sign(Fixtures.liveBuybackToVault, terms: terms)
        }

        #expect(doubles.coldKeyInteractor.signedMessages.isEmpty)
    }

    @Test("Refuses when the account key was never derived")
    func refusesWithoutColdKey() async {
        let (sut, doubles) = makeSUT(coldOwner: nil)

        await #expect(throws: CollectiblesOnboardingError.self) {
            try await sut.sign(Fixtures.liveBuyback, terms: Fixtures.terms)
        }

        #expect(doubles.coldKeyInteractor.signedMessages.isEmpty)
    }

    // MARK: - Send

    @Test("Sends the signed bytes at once, without waiting out the partner's blockhash")
    func sendsSignedBytes() async throws {
        let (sut, doubles) = makeSUT()
        let signed = try await sut.sign(Fixtures.liveBuybackToVault, terms: Fixtures.terms)

        try await sut.send(signed)

        #expect(doubles.chainService.broadcasts.map(\.serializedTransaction) == [signed.serializedTransaction])
        #expect(doubles.chainService.broadcasts.map(\.startSendingTimestamp) == [Date.distantPast])
    }

    @Test("A response lost on the way counts as sent")
    func acceptsAlreadyProcessed() async throws {
        let (sut, doubles) = makeSUT()
        doubles.chainService.sendError = SolanaSendError.alreadyProcessed

        try await sut.send(Fixtures.signedBuyback(receivedAt: Date()))

        #expect(doubles.chainService.broadcasts.count == 1)
    }

    @Test("Send failures are told apart", arguments: SendFailure.allCases)
    func tellsSendFailuresApart(failure: SendFailure) async throws {
        let (sut, doubles) = makeSUT()
        doubles.chainService.sendError = try failure.makeError()

        let error = await #expect(throws: CollectiblesSendError.self) {
            try await sut.send(Fixtures.signedBuyback(receivedAt: failure.receivedAt))
        }

        #expect(error?.testDescription == failure.expectedDescription)
    }
}

// MARK: - Arguments

extension CollectiblesBuybackTransactionDispatcherTests {
    enum MessageVersion {
        case legacy
        case v0
    }

    enum Unsignable: CaseIterable {
        case ownerNotSigner
        case cosignerUnsigned
        case noSignatures
        case missingSignatureSlot
        case truncatedSigners
        case empty
        case unsupportedVersion
        case addressTableLookups
        case trailingBytes
        case programOutsideAccountKeys
        case oversizedSignatureCount
        case oversizedInstructionDataLength

        var serialized: Data {
            switch self {
            case .ownerNotSigner:
                Fixtures.serialized(
                    signatures: [Fixtures.collectorSignature, Fixtures.emptySignature],
                    message: Fixtures.message(signers: [Fixtures.collectorKey, Fixtures.strangerKey])
                )
            case .cosignerUnsigned:
                Fixtures.serialized(
                    signatures: [Fixtures.emptySignature, Fixtures.emptySignature],
                    message: Fixtures.message(signers: [Fixtures.collectorKey, Fixtures.ownerKey])
                )
            case .noSignatures:
                Fixtures.serialized(
                    signatures: [],
                    message: Fixtures.message(signers: [Fixtures.ownerKey])
                )
            case .missingSignatureSlot:
                Fixtures.serialized(
                    signatures: [Fixtures.collectorSignature],
                    message: Fixtures.message(signers: [Fixtures.collectorKey, Fixtures.ownerKey])
                )
            case .truncatedSigners:
                Fixtures.serialized(
                    signatures: [Fixtures.emptySignature],
                    message: Fixtures.message(signers: [Fixtures.ownerKey]).prefix(Fixtures.accountKeysOffset + 16)
                )
            case .empty:
                Data()
            case .unsupportedVersion:
                Fixtures.serialized(
                    signatures: [Fixtures.emptySignature],
                    message: Fixtures.message(prefix: [0x81], signers: [Fixtures.ownerKey], suffix: [0])
                )
            case .addressTableLookups:
                Fixtures.serialized(
                    signatures: [Fixtures.emptySignature],
                    message: Fixtures.message(prefix: [0x80], signers: [Fixtures.ownerKey], suffix: [1])
                )
            case .trailingBytes:
                Fixtures.serialized(
                    signatures: [Fixtures.emptySignature],
                    message: Fixtures.message(signers: [Fixtures.ownerKey], suffix: [0])
                )
            case .programOutsideAccountKeys:
                Fixtures.serialized(
                    signatures: [Fixtures.emptySignature],
                    message: Fixtures.message(signers: [Fixtures.ownerKey], programIndex: 2)
                )
            case .oversizedSignatureCount:
                Data(Fixtures.oversizedLength) + Fixtures.message(signers: [Fixtures.ownerKey])
            case .oversizedInstructionDataLength:
                Fixtures.serialized(
                    signatures: [Fixtures.emptySignature],
                    message: Fixtures.message(signers: [Fixtures.ownerKey], dataLength: Fixtures.oversizedLength)
                )
            }
        }

        func isExpected(_ error: any Error) -> Bool {
            switch self {
            case .ownerNotSigner: (error as? VerificationError) == .ownerNotSigner
            case .cosignerUnsigned: (error as? VerificationError) == .cosignerSignatureMissing
            case .noSignatures: (error as? ParsingError) == .missingSignatures
            case .missingSignatureSlot: (error as? ParsingError) == .signatureSlotsMismatch
            case .truncatedSigners, .empty: error is BinaryReaderError
            case .unsupportedVersion: (error as? ParsingError) == .unsupportedMessageVersion
            case .addressTableLookups: (error as? ParsingError) == .addressTableLookups
            case .trailingBytes: (error as? ParsingError) == .trailingBytes
            case .programOutsideAccountKeys: (error as? ParsingError) == .indexOutsideAccountKeys
            case .oversizedSignatureCount, .oversizedInstructionDataLength: (error as? ParsingError) == .invalidLength
            }
        }
    }

    enum SendFailure: CaseIterable {
        case blockhashNotFound
        case nodeRejection
        case staleNodeRejection
        case programRejection
        case unknown

        var receivedAt: Date {
            switch self {
            case .blockhashNotFound, .nodeRejection, .programRejection: Date()
            case .staleNodeRejection, .unknown: Fixtures.receivedLongAgo
            }
        }

        var expectedDescription: String {
            switch self {
            case .blockhashNotFound, .staleNodeRejection: "transactionExpired"
            case .nodeRejection, .programRejection: "rejected"
            case .unknown: "outcomeUnknown"
            }
        }

        func makeError() throws -> any Error {
            switch self {
            case .blockhashNotFound:
                SolanaSwift.RPCError.invalidResponse(try Self.responseError("Blockhash not found"))
            case .nodeRejection, .staleNodeRejection:
                SolanaSwift.RPCError.invalidResponse(
                    try Self.responseError("Transaction simulation failed: Error processing Instruction 1")
                )
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

private extension CollectiblesBuybackTransactionDispatcherTests {
    struct Doubles {
        let coldOwnerProvider: ColdOwnerProviderStub
        let configReader: ConfigReaderStub
        let coldKeyInteractor: ColdKeyInteractorSpy
        let chainService: ChainServiceSpy
    }

    enum Fixtures {
        static let ownerAddress = "f2AQUg4bys9YrHgL6DvKaZYftB81BsymeRupnsuxMbn"
        static let nftAddress = "GPuvDVEEczHwXiPSxf269xz8Nrnc62ybFk4C1iM6FRR4"
        static let usdcMintAddress = "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"
        static let payout: UInt64 = 12_750_000

        static let terms = CollectiblesBuybackTerms(nftAddress: nftAddress, minimumPayoutInBaseUnits: payout)

        static let liveBuyback = Data(
            base64Encoded: """
            AlQYLWVifxuPsAw4kVBU/60egRs8r/lVDnpG/WuwV/URqzaHYiQvLx9WUt/i0BamL6IAU7DRiZmdOrcYflFPvQkAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgEJDoakCFBHeIP62Wfd1yRpn2NS
            Ju3WGlYaXwdBjxcDWn9/Cb1igdTOukueBOv4c1erNsqIqkhVXhhkfr5fXw8kbIkSJe2JgFKSNFCWMINiHhZ3TuoDSbbPYbMLFDUx
            djOE/X8tHLsqlhPPfHMQftnlm7Jct1DLzZ9vIrwXjN+kV1ia5L3qa+AoXhua6um6hR+mNKnDalq4TQctR2G/ErAElhMAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIyXJY9OJInxuz0QKRSODYMLWhOZ2v8QhASOe9jb6fhZpnp1Fpjwvz4eGn76FE9GJ9oh
            sIsCtacq5krP94RMHvUDBkZv5SEXMv/srbpyw5vnvIzlu8X3EmssQ5s6QAAAAK9UqxC9l6VCoJ73s5iJ3QzTlKTM6d+mzcl+vi0j
            W6dI6Sg5VQll/9TWSsqvRtRd9zGOW09XyQxIfWBiXYKbg3sFEx3Boojpr4HDt2UYv/YIKDiAAK9b/9o7s+EsDGGT5wVKU1qZKSEG
            TSTocWDaOHx8NbXdvJK7geQfqEBBBUSNBt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKnJIe4725n4bB0/Bp9qNv3ttl6f
            m/ZiO+7P5HwBEr66rAYIAAUCkNADAAkHBAcAAQsJCQIOAAgACQMgTgAAAAAAAAYGAAIBCgUNAQENBAMKAgAKDLCMwgAAAAAABgwA
            L2NjLWFjMDY3YzRlLTZiYjEtNDA5MS05MTViLTNmNWU5ZjQyZWQ1MDpidXliYWNr
            """,
            options: .ignoreUnknownCharacters
        )!

        static let liveSignaturesLength = 1 + 2 * 64
        static let liveCollectorSignature = liveBuyback.subdata(in: 1 ..< 65)
        static let livePayoutAccountRange = 4 + 2 * 32 ..< 4 + 3 * 32
        static let oversizedLength: [UInt8] = Array(repeating: 0xFF, count: 9) + [0x01]

        static var liveBuybackToVault: Data {
            serialized(signatures: [liveCollectorSignature, emptySignature], message: liveMessage(version: .legacy))
        }

        static var vaultUsdcAccount: Data {
            let program = try! CollectiblesVaultProgram(programId: CollectiblesChainEnvironment.programId)
            let address = try! program.vaultUsdcAddress(coldOwner: ownerKey, usdcMint: config.usdcMint)
            return SolanaSwift.PublicKey(string: address)!.data
        }

        static let ownerKey = SolanaSwift.PublicKey(string: ownerAddress)!.data
        static let collectorKey = Data(repeating: 0x21, count: 32)
        static let strangerKey = Data(repeating: 0x31, count: 32)
        static let memoProgramKey = Data(repeating: 0x05, count: 32)
        static let blockhash = Data(repeating: 0x66, count: 32)
        static let memo = Data("order-1:buyback".utf8)
        static let collectorSignature = Data(repeating: 0xC1, count: 64)
        static let ownerSignature = Data(repeating: 0xA1, count: 64)
        static let emptySignature = Data(repeating: 0, count: 64)
        static let receivedLongAgo = Date(timeIntervalSince1970: 1_700_000_000)
        static let accountKeysOffset = 4

        static var coldOwner: BlockchainSdk.Wallet.PublicKey {
            let extendedPublicKey = ExtendedPublicKey(publicKey: ownerKey, chainCode: Data(repeating: 0x88, count: 32))
            let hdKey = BlockchainSdk.Wallet.PublicKey.HDKey(
                path: CollectiblesAccountKeyPath.derivationPath,
                extendedPublicKey: extendedPublicKey
            )
            return BlockchainSdk.Wallet.PublicKey(
                seedKey: Data(repeating: 0x11, count: 32),
                derivationType: .plain(hdKey)
            )
        }

        static var config: CollectiblesConfigInfo {
            CollectiblesConfigInfo(
                usdcMint: SolanaSwift.PublicKey(string: usdcMintAddress)!.data,
                collectiblesUsdcAccount: Data(repeating: 0x56, count: 32),
                feeUsdcAccount: Data(repeating: 0x57, count: 32),
                minFeeBps: 100,
                maxFeeBps: 300
            )
        }

        static func liveMessage(version: MessageVersion) -> Data {
            var message = liveBuyback.subdata(in: liveSignaturesLength ..< liveBuyback.count)
            message.replaceSubrange(livePayoutAccountRange, with: vaultUsdcAccount)

            switch version {
            case .legacy:
                return message
            case .v0:
                return Data([0x80]) + message + Data([0])
            }
        }

        static func message(
            prefix: [UInt8] = [],
            signers: [Data],
            programIndex: UInt8? = nil,
            dataLength: [UInt8]? = nil,
            suffix: [UInt8] = []
        ) -> Data {
            let accountKeys = signers + [memoProgramKey]
            var message = Data(prefix)
            message.append(contentsOf: [UInt8(signers.count), 1, 1, UInt8(accountKeys.count)])
            accountKeys.forEach { message.append($0) }
            message.append(blockhash)
            message.append(contentsOf: [1, programIndex ?? UInt8(accountKeys.count - 1), 0])
            message.append(contentsOf: dataLength ?? [UInt8(memo.count)])
            message.append(memo)
            message.append(contentsOf: suffix)
            return message
        }

        static func serialized(signatures: [Data], message: Data) -> Data {
            var transaction = Data([UInt8(signatures.count)])
            signatures.forEach { transaction.append($0) }
            transaction.append(message)
            return transaction
        }

        static func signedBuyback(receivedAt: Date) -> CollectiblesSignedBuyback {
            CollectiblesSignedBuyback(
                signature: ownerSignature.base58EncodedString,
                serializedTransaction: serialized(signatures: [ownerSignature], message: message(signers: [ownerKey])),
                receivedAt: receivedAt
            )
        }
    }

    func makeSUT(coldOwner: BlockchainSdk.Wallet.PublicKey? = Fixtures.coldOwner) -> (SUT, Doubles) {
        let doubles = Doubles(
            coldOwnerProvider: ColdOwnerProviderStub(key: coldOwner),
            configReader: ConfigReaderStub(config: Fixtures.config),
            coldKeyInteractor: ColdKeyInteractorSpy(signature: Fixtures.ownerSignature),
            chainService: ChainServiceSpy()
        )
        let sut = SUT(
            coldOwnerProvider: doubles.coldOwnerProvider,
            configReader: doubles.configReader,
            coldKeyInteractorFactory: ColdKeyInteractorFactoryStub(interactor: doubles.coldKeyInteractor),
            transactionSender: CollectiblesColdKeyTransactionSender(
                serviceProvider: ChainServiceProviderStub(chainService: doubles.chainService)
            )
        )

        trackForMemoryLeaks(doubles.coldOwnerProvider)
        trackForMemoryLeaks(doubles.configReader)
        trackForMemoryLeaks(doubles.coldKeyInteractor)
        trackForMemoryLeaks(doubles.chainService)

        return (sut, doubles)
    }
}

private extension CollectiblesSendError {
    var testDescription: String {
        switch self {
        case .transactionExpired: "transactionExpired"
        case .outcomeUnknown: "outcomeUnknown"
        case .rejected: "rejected"
        }
    }
}

// MARK: - Doubles

private enum TestError: Error {
    case chain
    case unexpectedCall
}

private final class ColdOwnerProviderStub: CollectiblesColdOwnerProvider {
    private let key: BlockchainSdk.Wallet.PublicKey?

    init(key: BlockchainSdk.Wallet.PublicKey?) {
        self.key = key
    }

    func coldOwnerKey() -> BlockchainSdk.Wallet.PublicKey? {
        key
    }
}

private final class ConfigReaderStub: CollectiblesConfigReader {
    private let config: CollectiblesConfigInfo

    init(config: CollectiblesConfigInfo) {
        self.config = config
    }

    func configInfo() async throws -> CollectiblesConfigInfo {
        config
    }
}

private final class ColdKeyInteractorSpy: CollectiblesColdKeyInteractor {
    private struct State {
        var signedMessages: [Data] = []
        var signedColdKeys: [BlockchainSdk.Wallet.PublicKey] = []
    }

    private let state = OSAllocatedUnfairLock(uncheckedState: State())
    private let signature: Data

    init(signature: Data) {
        self.signature = signature
    }

    var signedMessages: [Data] {
        state { $0.signedMessages }
    }

    var signedColdKeys: [BlockchainSdk.Wallet.PublicKey] {
        state { $0.signedColdKeys }
    }

    func derive<Work: CollectiblesColdKeySessionWork>(andRun work: Work) async throws -> Work.Output {
        try await work.run(signer: self)
    }

    func sign(message: Data, coldKey: BlockchainSdk.Wallet.PublicKey) async throws -> Data {
        state { state in
            state.signedMessages.append(message)
            state.signedColdKeys.append(coldKey)
        }

        return signature
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

private final class ChainServiceProviderStub: CollectiblesChainServiceProvider {
    private let chainService: ChainServiceSpy

    init(chainService: ChainServiceSpy) {
        self.chainService = chainService
    }

    func service() throws -> any CollectiblesChainService {
        chainService
    }
}

private final class ChainServiceSpy: CollectiblesChainService {
    struct Broadcast {
        let serializedTransaction: Data
        let startSendingTimestamp: Date
    }

    private struct State {
        var sendError: (any Error)?
        var broadcasts: [Broadcast] = []
    }

    private let state = OSAllocatedUnfairLock(uncheckedState: State())

    var sendError: (any Error)? {
        get { state { $0.sendError } }
        set { state { $0.sendError = newValue } }
    }

    var broadcasts: [Broadcast] {
        state { $0.broadcasts }
    }

    func account(address: String) async throws -> SolanaRawAccount? {
        throw TestError.unexpectedCall
    }

    func latestBlockhash() async throws -> SolanaBlockhash {
        throw TestError.unexpectedCall
    }

    func makeSelfPaidTransaction(
        instructions: [SolanaRawInstruction],
        feePayer: Data,
        blockhash: SolanaBlockhash
    ) throws -> SolanaSelfPaidTransaction {
        throw TestError.unexpectedCall
    }

    func send(serializedTransaction: Data, startSendingTimestamp: Date) async throws -> String {
        let error = state { state -> (any Error)? in
            state.broadcasts.append(Broadcast(
                serializedTransaction: serializedTransaction,
                startSendingTimestamp: startSendingTimestamp
            ))
            return state.sendError
        }

        if let error {
            throw error
        }

        return "sent"
    }
}
