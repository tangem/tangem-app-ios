//
//  CommonCollectiblesSessionKeyWalletStoreTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemSdk
import TangemTestKit
@testable import TangemCollectibles
@testable import TangemMobileWalletSdk

@Suite("CommonCollectiblesSessionKeyWalletStore")
final class CommonCollectiblesSessionKeyWalletStoreTests: LeakTrackingTestSuite {
    typealias SUT = CommonCollectiblesSessionKeyWalletStore
    typealias KeyError = CommonCollectiblesSessionKeyWalletStore.KeyError

    // MARK: - Generate

    @Test("Generates a wallet and hands out its ed25519 master key")
    func generateHandsOutFreshMasterKey() throws {
        let (sut, sdk, idStore) = makeSUT()

        let publicKey = try sut.generateKey(for: Constants.userWalletId)

        let generatedWalletId = try #require(sdk.generatedWalletIds.last)
        #expect(publicKey == sdk.masterKey(for: generatedWalletId))
        #expect(try idStore.sessionKeyWalletId(for: Constants.userWalletId) == generatedWalletId)
        #expect(sdk.deletedWalletIds.isEmpty)
    }

    @Test("Replaces the held key and deletes the wallet behind it")
    func generateDeletesPreviousWallet() throws {
        let (sut, sdk, idStore) = makeSUT(heldWalletId: Constants.heldWalletId)

        _ = try sut.generateKey(for: Constants.userWalletId)

        let generatedWalletId = try #require(sdk.generatedWalletIds.last)
        #expect(sdk.deletedWalletIds == [Constants.heldWalletId])
        #expect(try idStore.sessionKeyWalletId(for: Constants.userWalletId) == generatedWalletId)
    }

    @Test("A previous wallet that refuses to be deleted does not fail the rotation")
    func generateIgnoresPreviousWalletDeletionFailure() throws {
        let (sut, sdk, idStore) = makeSUT(heldWalletId: Constants.heldWalletId)
        sdk.undeletableWalletIds = [Constants.heldWalletId]

        let publicKey = try sut.generateKey(for: Constants.userWalletId)

        let generatedWalletId = try #require(sdk.generatedWalletIds.last)
        #expect(publicKey == sdk.masterKey(for: generatedWalletId))
        #expect(try idStore.sessionKeyWalletId(for: Constants.userWalletId) == generatedWalletId)
    }

    @Test("Rolls back the new wallet when it fails to validate and keeps the held mapping")
    func generateRollsBackOnValidationFailure() throws {
        let (sut, sdk, idStore) = makeSUT(heldWalletId: Constants.heldWalletId)
        sdk.validateError = TestError.validation

        #expect(throws: TestError.validation) {
            try sut.generateKey(for: Constants.userWalletId)
        }

        let generatedWalletId = try #require(sdk.generatedWalletIds.last)
        #expect(sdk.deletedWalletIds == [generatedWalletId])
        #expect(try idStore.sessionKeyWalletId(for: Constants.userWalletId) == Constants.heldWalletId)
    }

    @Test("Rolls back the new wallet when the mapping cannot be written")
    func generateRollsBackOnMappingFailure() throws {
        let (sut, sdk, idStore) = makeSUT()
        idStore.writeError = TestError.storage

        #expect(throws: TestError.storage) {
            try sut.generateKey(for: Constants.userWalletId)
        }

        let generatedWalletId = try #require(sdk.generatedWalletIds.last)
        #expect(sdk.deletedWalletIds == [generatedWalletId])
        #expect(try idStore.sessionKeyWalletId(for: Constants.userWalletId) == nil)
    }

    @Test("Rolls back the new wallet when it holds no ed25519 master key")
    func generateRollsBackWithoutEd25519Key() throws {
        let (sut, sdk, idStore) = makeSUT(masterKeyCurve: .secp256k1)

        #expect(throws: KeyError.masterKeyUnavailable) {
            try sut.generateKey(for: Constants.userWalletId)
        }

        let generatedWalletId = try #require(sdk.generatedWalletIds.last)
        #expect(sdk.deletedWalletIds == [generatedWalletId])
        #expect(try idStore.sessionKeyWalletId(for: Constants.userWalletId) == nil)
    }

    // MARK: - Public key

    @Test("No held wallet means no public key")
    func publicKeyIsNilWithoutHeldWallet() throws {
        let (sut, sdk, _) = makeSUT()

        #expect(try sut.publicKey(for: Constants.userWalletId) == nil)
        #expect(sdk.validateCallCount == 0)
    }

    @Test("Reads the held wallet's master key once and serves it from the cache afterwards")
    func publicKeyReadsAndCachesHeldMasterKey() throws {
        let (sut, sdk, _) = makeSUT(heldWalletId: Constants.heldWalletId)

        let firstRead = try sut.publicKey(for: Constants.userWalletId)
        let secondRead = try sut.publicKey(for: Constants.userWalletId)

        #expect(firstRead == sdk.masterKey(for: Constants.heldWalletId))
        #expect(secondRead == firstRead)
        #expect(sdk.validateCallCount == 1)
        #expect(sdk.deriveMasterKeysCallCount == 1)
    }

    @Test("A key generated in this session is served without another validation")
    func publicKeyAfterGenerateIsServedFromCache() throws {
        let (sut, sdk, _) = makeSUT()
        let generatedKey = try sut.generateKey(for: Constants.userWalletId)

        let publicKey = try sut.publicKey(for: Constants.userWalletId)

        #expect(publicKey == generatedKey)
        #expect(sdk.validateCallCount == 1)
    }

    @Test("A mapping that outlived its wallet reads as no key")
    func publicKeyIsNilWhenHeldWalletIsGone() throws {
        let (sut, sdk, _) = makeSUT(heldWalletId: Constants.heldWalletId)
        sdk.validateError = TestError.validation

        #expect(try sut.publicKey(for: Constants.userWalletId) == nil)
    }

    // MARK: - Sign

    @Test("Signing without a held wallet is refused")
    func signWithoutHeldWalletIsRefused() {
        let (sut, sdk, _) = makeSUT()

        #expect(throws: KeyError.keyMissing) {
            try sut.sign(Constants.message, for: Constants.userWalletId)
        }
        #expect(sdk.signRequests.isEmpty)
    }

    @Test("Signs the message with the held master key as both the signing key and the seed")
    func signSendsMessageAndHeldKey() throws {
        let (sut, sdk, _) = makeSUT(heldWalletId: Constants.heldWalletId)
        let heldKey = sdk.masterKey(for: Constants.heldWalletId)
        sdk.signatures = [MobileWalletSignature(publicKey: heldKey, hash: Constants.message, signature: Constants.signature)]

        let signature = try sut.sign(Constants.message, for: Constants.userWalletId)

        let request = try #require(sdk.signRequests.first)
        let signData = try #require(request.dataToSign.first)
        #expect(signature == Constants.signature)
        #expect(sdk.signRequests.count == 1)
        #expect(request.dataToSign.count == 1)
        #expect(request.seedKey == heldKey)
        #expect(signData.hashes == [Constants.message])
        #expect(signData.publicKey == heldKey)
        #expect(signData.derivationPath == nil)
    }

    @Test("An SDK that produces no signature fails the signing")
    func signWithoutSignatureFails() {
        let (sut, sdk, _) = makeSUT(heldWalletId: Constants.heldWalletId)
        sdk.signatures = []

        #expect(throws: KeyError.signingFailed) {
            try sut.sign(Constants.message, for: Constants.userWalletId)
        }
    }

    @Test("A held wallet that fails to validate fails the signing")
    func signRethrowsValidationFailure() {
        let (sut, sdk, _) = makeSUT(heldWalletId: Constants.heldWalletId)
        sdk.validateError = TestError.validation

        #expect(throws: TestError.validation) {
            try sut.sign(Constants.message, for: Constants.userWalletId)
        }
    }

    // MARK: - Delete

    @Test("Deleting without a held wallet touches nothing")
    func deleteWithoutHeldWalletTouchesNothing() throws {
        let (sut, sdk, idStore) = makeSUT()

        try sut.deleteKey(for: Constants.userWalletId)

        #expect(sdk.deletedWalletIds.isEmpty)
        #expect(idStore.writeCount == 0)
    }

    @Test("Deletes the held wallet together with its mapping and cached key")
    func deleteRemovesWalletMappingAndCache() throws {
        let (sut, sdk, idStore) = makeSUT(heldWalletId: Constants.heldWalletId)
        _ = try sut.publicKey(for: Constants.userWalletId)

        try sut.deleteKey(for: Constants.userWalletId)
        let mappingAfterDelete = try idStore.sessionKeyWalletId(for: Constants.userWalletId)
        try idStore.setSessionKeyWalletId(Constants.heldWalletId, for: Constants.userWalletId)
        _ = try sut.publicKey(for: Constants.userWalletId)

        #expect(mappingAfterDelete == nil)
        #expect(sdk.deletedWalletIds == [Constants.heldWalletId])
        #expect(sdk.validateCallCount == 2)
    }

    @Test("A wallet that refuses to be deleted keeps its mapping")
    func deleteFailureKeepsMapping() throws {
        let (sut, sdk, idStore) = makeSUT(heldWalletId: Constants.heldWalletId)
        sdk.undeletableWalletIds = [Constants.heldWalletId]

        #expect(throws: TestError.deletion) {
            try sut.deleteKey(for: Constants.userWalletId)
        }
        #expect(try idStore.sessionKeyWalletId(for: Constants.userWalletId) == Constants.heldWalletId)
    }

    // MARK: - Mapping store

    @Test("A mapping store that cannot be read fails every operation", arguments: StoreOperation.allCases)
    func unreadableMappingStoreFailsOperation(operation: StoreOperation) {
        let (sut, sdk, idStore) = makeSUT()
        idStore.readError = TestError.storage

        #expect(throws: TestError.storage) {
            try perform(operation, on: sut)
        }
        #expect(sdk.generatedWalletIds.isEmpty)
    }
}

// MARK: - Arguments

extension CommonCollectiblesSessionKeyWalletStoreTests {
    enum StoreOperation: CaseIterable {
        case generate
        case publicKey
        case sign
        case delete
    }
}

// MARK: - Helpers

private extension CommonCollectiblesSessionKeyWalletStoreTests {
    enum Constants {
        static let userWalletId = UserWalletId(value: Data(repeating: 0x11, count: 32))
        static let heldWalletId = UserWalletId(value: Data(repeating: 0xA0, count: 32))
        static let message = Data([1, 2, 3])
        static let signature = Data(repeating: 0xCC, count: 64)
    }

    func makeSUT(
        heldWalletId: UserWalletId? = nil,
        masterKeyCurve: EllipticCurve = .ed25519
    ) -> (SUT, MobileWalletSdkFake, SessionKeyWalletIdStoreFake) {
        let sdk = MobileWalletSdkFake(masterKeyCurve: masterKeyCurve)
        let idStore = SessionKeyWalletIdStoreFake(mapping: heldWalletId.map { [Constants.userWalletId: $0] } ?? [:])
        let sut = SUT(sdk: sdk, walletIdStore: idStore)
        return (trackForMemoryLeaks(sut), sdk, idStore)
    }

    func perform(_ operation: StoreOperation, on sut: SUT) throws {
        switch operation {
        case .generate:
            _ = try sut.generateKey(for: Constants.userWalletId)
        case .publicKey:
            _ = try sut.publicKey(for: Constants.userWalletId)
        case .sign:
            _ = try sut.sign(Constants.message, for: Constants.userWalletId)
        case .delete:
            try sut.deleteKey(for: Constants.userWalletId)
        }
    }
}

// MARK: - Doubles

private enum TestError: Error {
    case validation
    case storage
    case deletion
    case unexpectedCall
}

private final class SessionKeyWalletIdStoreFake: CollectiblesSessionKeyWalletIdStore {
    var readError: (any Error)?
    var writeError: (any Error)?
    private(set) var writeCount = 0

    private var mapping: [UserWalletId: UserWalletId]

    init(mapping: [UserWalletId: UserWalletId]) {
        self.mapping = mapping
    }

    func sessionKeyWalletId(for userWalletId: UserWalletId) throws -> UserWalletId? {
        if let readError {
            throw readError
        }

        return mapping[userWalletId]
    }

    func setSessionKeyWalletId(_ sessionKeyWalletId: UserWalletId?, for userWalletId: UserWalletId) throws {
        if let writeError {
            throw writeError
        }

        writeCount += 1
        mapping[userWalletId] = sessionKeyWalletId
    }
}

private final class MobileWalletSdkFake: MobileWalletSdk {
    var validateError: (any Error)?
    var undeletableWalletIds: Set<UserWalletId> = []
    var signatures: [MobileWalletSignature] = []

    private(set) var generatedWalletIds: [UserWalletId] = []
    private(set) var deletedWalletIds: [UserWalletId] = []
    private(set) var signRequests: [(dataToSign: [SignData], seedKey: Data)] = []
    private(set) var validateCallCount = 0
    private(set) var deriveMasterKeysCallCount = 0

    private let masterKeyCurve: EllipticCurve

    init(masterKeyCurve: EllipticCurve) {
        self.masterKeyCurve = masterKeyCurve
    }

    func masterKey(for walletId: UserWalletId) -> Data {
        Data(walletId.value.map { $0 &+ 1 })
    }

    func generateWallet() throws -> UserWalletId {
        let walletId = UserWalletId(value: Data(repeating: UInt8(generatedWalletIds.count + 1), count: 32))
        generatedWalletIds.append(walletId)
        return walletId
    }

    func validate(auth: AuthenticationUnlockData, for walletID: UserWalletId) throws -> MobileWalletContext {
        validateCallCount += 1

        if let validateError {
            throw validateError
        }

        return MobileWalletContext(walletID: walletID, authentication: auth)
    }

    func deriveMasterKeys(context: MobileWalletContext) throws -> MobileWallet {
        deriveMasterKeysCallCount += 1
        let keyInfo = MobileWalletKeyInfo(publicKey: masterKey(for: context.walletID), chainCode: nil, curve: masterKeyCurve)
        return MobileWallet(id: context.walletID, wallets: [keyInfo])
    }

    func delete(walletIDs: [UserWalletId]) throws {
        guard undeletableWalletIds.isDisjoint(with: walletIDs) else {
            throw TestError.deletion
        }

        deletedWalletIds += walletIDs
    }

    func sign(dataToSign: [SignData], seedKey: Data, context: MobileWalletContext) throws -> [MobileWalletSignature] {
        signRequests.append((dataToSign: dataToSign, seedKey: seedKey))
        return signatures
    }

    func isBiometricsEnabled(for walletID: UserWalletId) -> Bool {
        false
    }

    func clearBiometrics(walletIDs: [UserWalletId]) {}

    func importWallet(entropy: Data, passphrase: String) throws -> UserWalletId {
        throw TestError.unexpectedCall
    }

    func exportMnemonic(context: MobileWalletContext) throws -> [String] {
        throw TestError.unexpectedCall
    }

    func exportPassphrase(context: MobileWalletContext) throws -> String {
        throw TestError.unexpectedCall
    }

    func exportBackup(context: MobileWalletContext) throws -> Data {
        throw TestError.unexpectedCall
    }

    func updateAccessCode(_ newAccessCode: String, enableBiometrics: Bool, seedKey: Data, context: MobileWalletContext) throws {
        throw TestError.unexpectedCall
    }

    func refreshBiometrics(context: MobileWalletContext) throws {
        throw TestError.unexpectedCall
    }

    func deriveKeys(context: MobileWalletContext, derivationPaths: [Data: [DerivationPath]]) throws -> [Data: MobileWalletKeyInfo] {
        throw TestError.unexpectedCall
    }

    func userWalletEncryptionKey(context: MobileWalletContext) throws -> UserWalletEncryptionKey {
        throw TestError.unexpectedCall
    }
}
