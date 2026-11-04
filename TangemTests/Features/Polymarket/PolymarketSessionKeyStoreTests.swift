//
//  PolymarketSessionKeyStoreTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemSdk
import TangemTestKit
@testable import TangemMobileWalletSdk
@testable import Tangem

@Suite("Polymarket session key store")
final class PolymarketSessionKeyStoreTests: LeakTrackingTestSuite {
    typealias SUT = CommonPolymarketSessionKeyStore
    typealias KeyError = CommonPolymarketSessionKeyStore.KeyError

    // MARK: - Held key

    @Test("A held key reads as the lowercased address of its secp256k1 master key")
    func heldKeyReadsAsItsAddress() throws {
        let (sut, _, _) = makeSUT(heldWalletId: Constants.heldWalletId)

        #expect(try sut.heldAddress(for: Constants.userWalletId) == Constants.heldAddress)
    }

    @Test("Without a mapped key nothing is unlocked and nothing is created")
    func noMappedKeyReadsAsNoKey() throws {
        let (sut, sdk, _) = makeSUT()

        #expect(try sut.heldAddress(for: Constants.userWalletId) == nil)
        #expect(sdk.validatedWalletIds.isEmpty)
        #expect(sdk.generatedWalletIds.isEmpty)
    }

    @Test("A held key that fails to unlock is an error, not a missing key, and stays mapped")
    func heldKeyFailureIsNotAMissingKey() {
        let (sut, sdk, storage) = makeSUT(heldWalletId: Constants.heldWalletId)
        sdk.unvalidatableWalletIds = [Constants.heldWalletId]

        #expect(throws: TestError.validation) {
            try sut.heldAddress(for: Constants.userWalletId)
        }
        #expect(sdk.generatedWalletIds.isEmpty)
        #expect(sdk.deletedWalletIds.isEmpty)
        #expect(mappedWalletId(in: storage) == Constants.heldWalletId)
    }

    // MARK: - Generate

    @Test("A generated key replaces the held one: its wallet is mapped and the replaced wallet is deleted")
    func generateReplacesHeldKey() throws {
        let (sut, sdk, storage) = makeSUT(heldWalletId: Constants.heldWalletId)

        let address = try sut.generateKey(for: Constants.userWalletId)

        #expect(address == Constants.generatedAddress)
        #expect(mappedWalletId(in: storage) == Constants.generatedWalletId)
        #expect(sdk.deletedWalletIds == [Constants.heldWalletId])
        #expect(try sut.heldAddress(for: Constants.userWalletId) == Constants.generatedAddress)
    }

    @Test("A replaced wallet that refuses to be deleted does not fail the new key")
    func generateIgnoresReplacedWalletDeletionFailure() throws {
        let (sut, sdk, storage) = makeSUT(heldWalletId: Constants.heldWalletId)
        sdk.undeletableWalletIds = [Constants.heldWalletId]

        let address = try sut.generateKey(for: Constants.userWalletId)

        #expect(address == Constants.generatedAddress)
        #expect(mappedWalletId(in: storage) == Constants.generatedWalletId)
    }

    @Test("A new key that fails to come up is deleted and the held key stays mapped", arguments: GenerationFailure.allCases)
    func generateRollsBack(failure: GenerationFailure) throws {
        let (sut, sdk, storage) = makeSUT(heldWalletId: Constants.heldWalletId)
        failure.inject(into: sdk, storage: storage)

        let error = #expect(throws: (any Error).self) {
            try sut.generateKey(for: Constants.userWalletId)
        }

        let thrown = try #require(error)
        #expect(failure.isCause(of: thrown))
        #expect(sdk.deletedWalletIds == [Constants.generatedWalletId])
        #expect(mappedWalletId(in: storage) == Constants.heldWalletId)
    }

    // MARK: - Sign

    @Test("A signature is the held key's r‖s‖v as lowercased 0x-prefixed hex")
    func signReturnsRecoverableSignature() throws {
        let (sut, sdk, _) = makeSUT(heldWalletId: Constants.heldWalletId)
        sdk.signature = Constants.compactSignature

        let signature = try sut.sign(hash: Constants.hash, for: Constants.userWalletId)

        let request = try #require(sdk.signRequests.first)
        let signData = try #require(request.dataToSign.first)
        #expect(signature == Constants.recoverableSignature)
        #expect(sdk.signRequests.count == 1)
        #expect(request.dataToSign.count == 1)
        #expect(request.seedKey == Constants.heldPublicKey)
        #expect(signData.publicKey == Constants.heldPublicKey)
        #expect(signData.hashes == [Constants.hash])
        #expect(signData.derivationPath == nil)
    }

    @Test("Signing without a mapped key is refused instead of creating one")
    func signWithoutKeyIsRefused() {
        let (sut, sdk, _) = makeSUT()

        #expect(throws: KeyError.keyMissing) {
            try sut.sign(hash: Constants.hash, for: Constants.userWalletId)
        }
        #expect(sdk.signRequests.isEmpty)
        #expect(sdk.generatedWalletIds.isEmpty)
    }

    // MARK: - Delete

    @Test("Deleting without a mapped key touches no wallet and no mapping")
    func deleteWithoutKeyTouchesNothing() throws {
        let (sut, sdk, storage) = makeSUT()

        try sut.deleteKey(for: Constants.userWalletId)

        #expect(sdk.deletedWalletIds.isEmpty)
        #expect(storage.deletedAccounts.isEmpty)
    }

    @Test("Deleting removes the key's own wallet and its mapping, so the key no longer reads as held")
    func deleteRemovesWalletAndMapping() throws {
        let (sut, sdk, storage) = makeSUT(heldWalletId: Constants.heldWalletId)
        let addressBeforeDeletion = try sut.heldAddress(for: Constants.userWalletId)

        try sut.deleteKey(for: Constants.userWalletId)

        #expect(addressBeforeDeletion == Constants.heldAddress)
        #expect(sdk.deletedWalletIds == [Constants.heldWalletId])
        #expect(mappedWalletId(in: storage) == nil)
        #expect(try sut.heldAddress(for: Constants.userWalletId) == nil)
    }

    @Test("A wallet that refuses to be deleted keeps its mapping for another attempt")
    func deleteFailureKeepsMapping() {
        let (sut, sdk, storage) = makeSUT(heldWalletId: Constants.heldWalletId)
        sdk.undeletableWalletIds = [Constants.heldWalletId]

        #expect(throws: TestError.deletion) {
            try sut.deleteKey(for: Constants.userWalletId)
        }
        #expect(mappedWalletId(in: storage) == Constants.heldWalletId)
    }

    @Test("A deleted wallet whose mapping fails to be removed is not read back from the cache")
    func deleteMappingFailureDropsCachedKey() throws {
        let (sut, sdk, storage) = makeSUT(heldWalletId: Constants.heldWalletId)
        _ = try sut.heldAddress(for: Constants.userWalletId)
        storage.deleteError = TestError.storage

        #expect(throws: TestError.storage) {
            try sut.deleteKey(for: Constants.userWalletId)
        }
        #expect(sdk.deletedWalletIds == [Constants.heldWalletId])
        #expect(throws: TestError.validation) {
            try sut.heldAddress(for: Constants.userWalletId)
        }
    }

    // MARK: - Mapping

    @Test("A mapping that cannot be read fails the operation instead of reading as no key", arguments: StoreOperation.allCases)
    func unreadableMappingFailsOperation(operation: StoreOperation) {
        let (sut, sdk, storage) = makeSUT(heldWalletId: Constants.heldWalletId)
        storage.readError = TestError.storage

        #expect(throws: TestError.storage) {
            try perform(operation, on: sut)
        }
        #expect(sdk.generatedWalletIds.isEmpty)
        #expect(sdk.deletedWalletIds.isEmpty)
    }
}

// MARK: - Arguments

extension PolymarketSessionKeyStoreTests {
    enum GenerationFailure: CaseIterable {
        case validation
        case missingSecp256k1Key
        case mappingWrite

        fileprivate func inject(into sdk: MobileWalletSdkSpy, storage: PolymarketSecureStorageSpy) {
            switch self {
            case .validation:
                sdk.unvalidatableWalletIds = [Constants.generatedWalletId]
            case .missingSecp256k1Key:
                sdk.walletsWithoutSecp256k1Key = [Constants.generatedWalletId]
            case .mappingWrite:
                storage.writeError = TestError.storage
            }
        }

        fileprivate func isCause(of error: any Error) -> Bool {
            switch self {
            case .validation:
                (error as? TestError) == .validation
            case .missingSecp256k1Key:
                (error as? KeyError) == .masterKeyUnavailable
            case .mappingWrite:
                (error as? TestError) == .storage
            }
        }
    }

    enum StoreOperation: CaseIterable {
        case heldAddress
        case generate
        case sign
        case delete
    }
}

// MARK: - Helpers

private extension PolymarketSessionKeyStoreTests {
    enum Constants {
        static let userWalletId = UserWalletId(value: Data(repeating: 0x11, count: 32))
        static let mappingAccount = "polymarket_session_key_wallet_id_" + userWalletId.stringValue.lowercased()

        static let heldWalletId = UserWalletId(value: Data(repeating: 0xA0, count: 32))
        static let heldPublicKey = Data(hexString: "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798")
        static let heldAddress = "0x7e5f4552091a69125d5dfcb7b8c2659029395bdf"

        static let generatedWalletId = UserWalletId(value: Data(repeating: 0xB0, count: 32))
        static let generatedPublicKey = Data(hexString: "02c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5")
        static let generatedAddress = "0x2b5ad5c4795c026514f8317c7a215e218dccd6cf"

        static let hash = Data(hexString: "a0dc65ffca799873cbea0ac274015b9526505daaaed385155425f7337704883e")
        static let compactSignature = Data(
            hexString: "934b1ea10a4b3c1757e2b0c017d0b6143ce3c9a7e6a4a49860d7a6ab210ee3d82442ce9d2b916064108014783e923ec36b49743e2ffa1c4496f01a512aafd9e5"
        )
        static let recoverableSignature = "0x934b1ea10a4b3c1757e2b0c017d0b6143ce3c9a7e6a4a49860d7a6ab210ee3d82442ce9d2b916064108014783e923ec36b49743e2ffa1c4496f01a512aafd9e51c"
    }

    func makeSUT(heldWalletId: UserWalletId? = nil) -> (SUT, MobileWalletSdkSpy, PolymarketSecureStorageSpy) {
        let sdk = MobileWalletSdkSpy(
            masterKeys: [Constants.heldWalletId: Constants.heldPublicKey, Constants.generatedWalletId: Constants.generatedPublicKey],
            nextWalletId: Constants.generatedWalletId
        )
        let storage = PolymarketSecureStorageSpy(items: heldWalletId.map { [Constants.mappingAccount: $0.value] } ?? [:])
        let sut = SUT(sdk: sdk, secureStorage: storage)

        return (trackForMemoryLeaks(sut), sdk, storage)
    }

    func mappedWalletId(in storage: PolymarketSecureStorageSpy) -> UserWalletId? {
        storage.items[Constants.mappingAccount].map(UserWalletId.init(value:))
    }

    func perform(_ operation: StoreOperation, on sut: SUT) throws {
        switch operation {
        case .heldAddress:
            _ = try sut.heldAddress(for: Constants.userWalletId)
        case .generate:
            _ = try sut.generateKey(for: Constants.userWalletId)
        case .sign:
            _ = try sut.sign(hash: Constants.hash, for: Constants.userWalletId)
        case .delete:
            try sut.deleteKey(for: Constants.userWalletId)
        }
    }
}

// MARK: - Stubs

private enum TestError: Error {
    case validation
    case storage
    case deletion
    case unexpectedCall
}

private final class MobileWalletSdkSpy: MobileWalletSdk {
    var unvalidatableWalletIds: Set<UserWalletId> = []
    var walletsWithoutSecp256k1Key: Set<UserWalletId> = []
    var undeletableWalletIds: Set<UserWalletId> = []
    var signature: Data?

    private(set) var generatedWalletIds: [UserWalletId] = []
    private(set) var validatedWalletIds: [UserWalletId] = []
    private(set) var deletedWalletIds: [UserWalletId] = []
    private(set) var signRequests: [(dataToSign: [SignData], seedKey: Data)] = []

    private let masterKeys: [UserWalletId: Data]
    private let nextWalletId: UserWalletId

    init(masterKeys: [UserWalletId: Data], nextWalletId: UserWalletId) {
        self.masterKeys = masterKeys
        self.nextWalletId = nextWalletId
    }

    func generateWallet() throws -> UserWalletId {
        generatedWalletIds.append(nextWalletId)
        return nextWalletId
    }

    func validate(auth: AuthenticationUnlockData, for walletID: UserWalletId) throws -> MobileWalletContext {
        validatedWalletIds.append(walletID)

        guard !unvalidatableWalletIds.contains(walletID), !deletedWalletIds.contains(walletID) else {
            throw TestError.validation
        }

        return MobileWalletContext(walletID: walletID, authentication: auth)
    }

    func deriveMasterKeys(context: MobileWalletContext) throws -> MobileWallet {
        let curve: EllipticCurve = walletsWithoutSecp256k1Key.contains(context.walletID) ? .ed25519 : .secp256k1
        let keyInfo = MobileWalletKeyInfo(publicKey: masterKeys[context.walletID] ?? Data(), chainCode: nil, curve: curve)
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

        guard let signature, let hash = dataToSign.first?.hashes.first else {
            return []
        }

        return [MobileWalletSignature(publicKey: seedKey, hash: hash, signature: signature)]
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
