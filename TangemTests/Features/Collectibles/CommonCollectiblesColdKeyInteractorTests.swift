//
//  CommonCollectiblesColdKeyInteractorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemCollectibles
import TangemSdk
import TangemTestKit
import Testing
@testable import Tangem

@Suite("CommonCollectiblesColdKeyInteractor")
final class CommonCollectiblesColdKeyInteractorTests: LeakTrackingTestSuite {
    typealias SUT = CommonCollectiblesColdKeyInteractor

    // MARK: - Derive

    @Test("Derives the account path for the held seed key and stores the result")
    func deriveStoresDerivation() async throws {
        let (sut, doubles) = makeSUT()

        try await sut.derive(andRun: ClosureWork { _ in })

        #expect(doubles.keysDeriving.requestedDerivations == [[Constants.ed25519Seed: [Constants.path]]])
        #expect(doubles.keysRepository.keys.first?.derivedKeys[Constants.path] == Constants.extendedPublicKey)
    }

    @Test("Picks the seed key of the curve the derivation style dictates", arguments: Self.curveArguments)
    func derivePicksSeedKeyByDerivationStyle(derivationStyle: DerivationStyle?, seedKey: Data) async throws {
        let (sut, doubles) = makeSUT(derivationStyle: derivationStyle, keys: [Constants.ed25519Key, Constants.slip0010Key])

        try await sut.derive(andRun: ClosureWork { _ in })

        #expect(doubles.keysDeriving.requestedDerivations == [[seedKey: [Constants.path]]])
    }

    @Test("Runs the work after the derivation with a signer over the held key")
    func deriveRunsWorkAfterDerivation() async throws {
        let (sut, doubles) = makeSUT()
        let work = ClosureWork { signer in
            let isDerived = doubles.keysRepository.keys.first?.derivedKeys[Constants.path] != nil
            let signature = try await signer.sign(message: Constants.message, coldKey: Constants.coldKey)
            return (isDerived: isDerived, signature: signature)
        }

        let output = try await sut.derive(andRun: work)

        #expect(output.isDerived)
        #expect(output.signature == Constants.signature)
        #expect(doubles.signer.requestedHashes == [Constants.message])
        #expect(doubles.signer.requestedPublicKeys == [Constants.coldKey])
    }

    @Test("A failed derivation is rethrown and the work never runs")
    func deriveFailureSkipsWork() async {
        let (sut, doubles) = makeSUT(derivationResult: .failure(TestError.derivation))

        await #expect(throws: TestError.derivation) {
            try await sut.derive(andRun: ClosureWork { _ in Issue.record("The work must not run") })
        }
        #expect(doubles.keysRepository.keys.first?.derivedKeys.isEmpty == true)
    }

    @Test("A wallet without a seed key of the needed curve cannot derive")
    func deriveWithoutSeedKeyFails() async {
        let (sut, doubles) = makeSUT(keys: [])

        await #expect(throws: KeysProviderError.masterKeyNotFound) {
            try await sut.derive(andRun: ClosureWork { _ in Issue.record("The work must not run") })
        }
        #expect(doubles.keysDeriving.requestedDerivations.isEmpty)
    }

    // MARK: - Sign

    @Test("Signs with the held key without touching the derivation")
    func signUsesHeldKey() async throws {
        let (sut, doubles) = makeSUT()

        let signature = try await sut.sign(message: Constants.message, coldKey: Constants.coldKey)

        #expect(signature == Constants.signature)
        #expect(doubles.signer.requestedHashes == [Constants.message])
        #expect(doubles.signer.requestedPublicKeys == [Constants.coldKey])
        #expect(doubles.keysDeriving.requestedDerivations.isEmpty)
    }

    @Test("A failed signing is rethrown")
    func signFailureIsRethrown() async {
        let (sut, _) = makeSUT(signResult: .failure(TestError.signing))

        await #expect(throws: TestError.signing) {
            try await sut.sign(message: Constants.message, coldKey: Constants.coldKey)
        }
    }
}

// MARK: - Arguments

extension CommonCollectiblesColdKeyInteractorTests {
    nonisolated static let curveArguments: [(derivationStyle: DerivationStyle?, seedKey: Data)] = [
        (derivationStyle: nil, seedKey: Constants.ed25519Seed),
        (derivationStyle: .v1, seedKey: Constants.ed25519Seed),
        (derivationStyle: .v2, seedKey: Constants.ed25519Seed),
        (derivationStyle: .v3, seedKey: Constants.slip0010Seed),
    ]
}

// MARK: - Helpers

private extension CommonCollectiblesColdKeyInteractorTests {
    enum Constants {
        static let path = CollectiblesAccountKeyPath.derivationPath
        static let ed25519Seed = Data(repeating: 0x11, count: 32)
        static let slip0010Seed = Data(repeating: 0x22, count: 32)
        static let chainCode = Data(repeating: 0x33, count: 32)
        static let message = Data([1, 2, 3])
        static let signature = Data(repeating: 0xAA, count: 64)
        static let extendedPublicKey = ExtendedPublicKey(publicKey: Data(repeating: 0x44, count: 32), chainCode: chainCode)
        static let coldKey = Wallet.PublicKey(seedKey: ed25519Seed, derivationType: .plain(.init(path: path, extendedPublicKey: extendedPublicKey)))
        static let signatureInfo = SignatureInfo(signature: signature, publicKey: extendedPublicKey.publicKey, hash: message)
        static let ed25519Key = KeyInfo(publicKey: ed25519Seed, chainCode: chainCode, curve: .ed25519, isImported: false, derivedKeys: [:])
        static let slip0010Key = KeyInfo(publicKey: slip0010Seed, chainCode: chainCode, curve: .ed25519_slip0010, isImported: false, derivedKeys: [:])
        static let derivationResult: DerivationResult = [
            ed25519Seed: DerivedKeys(keys: [path: extendedPublicKey]),
            slip0010Seed: DerivedKeys(keys: [path: extendedPublicKey]),
        ]
    }

    struct Doubles {
        let keysRepository: KeysRepositoryTestsMock
        let keysDeriving: KeysDerivingSpy
        let signer: TangemSignerSpy
    }

    func makeSUT(
        derivationStyle: DerivationStyle? = nil,
        keys: [KeyInfo] = [Constants.ed25519Key],
        derivationResult: Result<DerivationResult, any Error> = .success(Constants.derivationResult),
        signResult: Result<SignatureInfo, any Error> = .success(Constants.signatureInfo)
    ) -> (SUT, Doubles) {
        var config = UserWalletConfigStub()
        config.derivationStyle = derivationStyle
        let doubles = Doubles(
            keysRepository: KeysRepositoryTestsMock(keys: keys),
            keysDeriving: KeysDerivingSpy(result: derivationResult),
            signer: TangemSignerSpy(result: signResult)
        )
        let sut = SUT(config: config, keysRepository: doubles.keysRepository, keysDeriving: doubles.keysDeriving, signer: doubles.signer)
        return (trackForMemoryLeaks(sut), doubles)
    }
}

// MARK: - Doubles

private enum TestError: Error {
    case derivation
    case signing
    case unexpectedCall
}

private struct ClosureWork<Output>: CollectiblesColdKeySessionWork {
    let body: (any CollectiblesColdKeySigner) async throws -> Output

    init(_ body: @escaping (any CollectiblesColdKeySigner) async throws -> Output) {
        self.body = body
    }

    func run(signer: any CollectiblesColdKeySigner) async throws -> Output {
        try await body(signer)
    }
}

private final class KeysDerivingSpy: KeysDeriving {
    let requiresCard = false
    private(set) var requestedDerivations: [[Data: [DerivationPath]]] = []

    private let result: Result<DerivationResult, any Error>

    init(result: Result<DerivationResult, any Error>) {
        self.result = result
    }

    func deriveKeys(derivations: [Data: [DerivationPath]], completion: @escaping (Result<DerivationResult, any Error>) -> Void) {
        requestedDerivations.append(derivations)
        completion(result)
    }
}

private final class TangemSignerSpy: TangemSigner {
    let latestSignerType: TangemSignerType? = nil
    private(set) var requestedHashes: [Data] = []
    private(set) var requestedPublicKeys: [Wallet.PublicKey] = []

    private let result: Result<SignatureInfo, any Error>

    init(result: Result<SignatureInfo, any Error>) {
        self.result = result
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, any Error> {
        requestedHashes.append(hash)
        requestedPublicKeys.append(walletPublicKey)
        return result.publisher.eraseToAnyPublisher()
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        Fail(error: TestError.unexpectedCall).eraseToAnyPublisher()
    }

    func sign(dataToSign: [SignData], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        Fail(error: TestError.unexpectedCall).eraseToAnyPublisher()
    }
}
