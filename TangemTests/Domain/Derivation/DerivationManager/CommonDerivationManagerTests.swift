//
//  CommonDerivationManagerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemSdk
import TangemTestKit
@testable import Tangem

@Suite("Common derivation manager", .timeLimit(.minutes(1)))
final class CommonDerivationManagerTests: LeakTrackingTestSuite {
    @Test("Counts the networks waiting for a key across every account of the wallet")
    func countsNetworksAcrossAccounts() async {
        let sut = makeSUT(pendingDerivationsPerAccount: [[Constants.pending(Constants.ethereum)], [Constants.pending(Constants.polygon)]])

        let count = await sut.manager.pendingDerivationsCount.values.first { $0 > 0 }

        #expect(count == 2)
    }

    @Test("The wallet has nothing pending once its only account has nothing left to derive")
    func statusFollowsAccount() async {
        let sut = makeSUT(pendingDerivationsPerAccount: [[Constants.pending(Constants.ethereum)]])
        _ = await sut.manager.hasPendingDerivations.values.first { $0 }

        sut.providers[0].pendingDerivationsSubject.send([])
        let hasPendingDerivations = await sut.manager.hasPendingDerivations.values.first { !$0 }

        #expect(hasPendingDerivations == false)
    }

    @Test("Deriving with nothing pending opens no card session")
    func nothingPendingOpensNoSession() async throws {
        let sut = makeSUT(pendingDerivationsPerAccount: [[]])

        try await sut.manager.deriveKeys()

        #expect(sut.interactor.requestedDerivations.isEmpty)
    }

    @Test("Deriving asks the card once for every pending path of the wallet and stores the keys it gets back")
    func derivesEveryPendingPathOnce() async throws {
        let derivedKey = ExtendedPublicKey(publicKey: Data(repeating: 0x03, count: 33), chainCode: Constants.chainCode)
        let sut = makeSUT(
            pendingDerivationsPerAccount: [[Constants.pending(Constants.ethereum)], [Constants.pending(Constants.polygon)]],
            derivationResult: .success([Constants.masterPublicKey: DerivedKeys(keys: [Constants.ethereumPath: derivedKey])])
        )
        _ = await sut.manager.pendingDerivationsCount.values.first { $0 == 2 }

        try await sut.manager.deriveKeys()

        #expect(sut.interactor.requestedDerivations == [[Constants.masterPublicKey: [Constants.ethereumPath, Constants.polygonPath]]])
        #expect(sut.keysRepository.keys.first?.derivedKeys == [Constants.ethereumPath: derivedKey])
    }

    @Test("A card session that fails hands its error to the caller")
    func failedSessionThrows() async {
        let sut = makeSUT(
            pendingDerivationsPerAccount: [[Constants.pending(Constants.ethereum)]],
            derivationResult: .failure(DerivationFailure())
        )
        _ = await sut.manager.hasPendingDerivations.values.first { $0 }

        await #expect(throws: DerivationFailure.self) {
            try await sut.manager.deriveKeys()
        }
    }

    @Test("A wallet that signs without a card never asks for one")
    func walletWithoutCardNeverAsks() async {
        let sut = makeSUT(pendingDerivationsPerAccount: [[Constants.pending(Constants.ethereum)]], requiresCard: false)
        _ = await sut.manager.hasPendingDerivations.values.first { $0 }

        #expect(!sut.manager.shouldDeriveKeys(networksToRemove: [], networksToAdd: [Constants.polygon]))
    }

    @Test("A key still pending in the wallet needs the card, unless its network is being removed", arguments: [false, true])
    func pendingKeyNeedsCard(isRemovingPendingNetwork: Bool) async {
        let sut = makeSUT(pendingDerivationsPerAccount: [[Constants.pending(Constants.ethereum)]])
        _ = await sut.manager.hasPendingDerivations.values.first { $0 }

        let networksToRemove = isRemovingPendingNetwork ? [Constants.ethereum] : []

        #expect(sut.manager.shouldDeriveKeys(networksToRemove: networksToRemove, networksToAdd: []) == !isRemovingPendingNetwork)
    }

    @Test("Adding a network whose key is not stored yet needs the card")
    func addingNetworkWithoutKeyNeedsCard() {
        let sut = makeSUT(pendingDerivationsPerAccount: [[]])

        #expect(sut.manager.shouldDeriveKeys(networksToRemove: [], networksToAdd: [Constants.polygon]))
    }
}

// MARK: - Helpers

private extension CommonDerivationManagerTests {
    typealias SUT = (
        manager: CommonDerivationManager,
        providers: [AccountPendingDerivationProviderStub],
        interactor: KeysDerivingSpy,
        keysDerivingProvider: KeysDerivingProviderStub,
        keysRepository: KeysRepositoryTestsMock
    )

    func makeSUT(
        pendingDerivationsPerAccount: [[PendingDerivation]],
        requiresCard: Bool = true,
        derivationResult: Result<DerivationResult, any Error> = .success([:])
    ) -> SUT {
        let keysRepository = KeysRepositoryTestsMock(keys: [Constants.masterKey])
        let providers = pendingDerivationsPerAccount.map { AccountPendingDerivationProviderStub(pendingDerivations: $0) }
        let accounts = providers.enumerated().map { index, provider in
            CryptoAccountModelMock(isMainAccount: index == 0, pendingDerivationProvider: provider, onArchive: { _ in })
        }
        let accountModelsManager = AccountModelsManagerStub(accounts: [.standard(.multiple(accounts))])
        let interactor = KeysDerivingSpy(requiresCard: requiresCard, result: derivationResult)
        let keysDerivingProvider = KeysDerivingProviderStub(keysDerivingInteractor: interactor)

        let manager = CommonDerivationManager(keysRepository: keysRepository)
        manager.configure(with: keysDerivingProvider)
        manager.configure(with: accountModelsManager)

        return (trackForMemoryLeaks(manager), providers, interactor, keysDerivingProvider, keysRepository)
    }

    enum Constants {
        static let masterPublicKey = Data(repeating: 0x02, count: 33)
        static let chainCode = Data(repeating: 0x33, count: 32)

        static let masterKey = KeyInfo(
            publicKey: masterPublicKey,
            chainCode: chainCode,
            curve: .secp256k1,
            isImported: false,
            derivedKeys: [:]
        )

        static let ethereumPath = DerivationPath(nodes: [.hardened(44), .hardened(60), .hardened(0), .nonHardened(0), .nonHardened(0)])
        static let polygonPath = DerivationPath(nodes: [.hardened(44), .hardened(60), .hardened(1), .nonHardened(0), .nonHardened(0)])

        static let ethereum = BlockchainNetwork(.ethereum(testnet: false), derivationPath: ethereumPath)
        static let polygon = BlockchainNetwork(.polygon(testnet: false), derivationPath: polygonPath)

        static func pending(_ network: BlockchainNetwork) -> PendingDerivation {
            PendingDerivation(network: network, masterKey: masterKey, paths: network.derivationPaths())
        }
    }
}

// MARK: - Stubs

private final class AccountPendingDerivationProviderStub: AccountPendingDerivationProvider {
    let pendingDerivationsSubject: CurrentValueSubject<[PendingDerivation], Never>

    init(pendingDerivations: [PendingDerivation]) {
        pendingDerivationsSubject = CurrentValueSubject(pendingDerivations)
    }

    var pendingDerivationsPublisher: AnyPublisher<[PendingDerivation], Never> {
        pendingDerivationsSubject.eraseToAnyPublisher()
    }
}

private final class KeysDerivingProviderStub: KeysDerivingProvider {
    let keysDerivingInteractor: KeysDeriving

    init(keysDerivingInteractor: KeysDeriving) {
        self.keysDerivingInteractor = keysDerivingInteractor
    }
}

private final class KeysDerivingSpy: KeysDeriving {
    let requiresCard: Bool
    private(set) var requestedDerivations: [[Data: [DerivationPath]]] = []

    private let result: Result<DerivationResult, any Error>

    init(requiresCard: Bool, result: Result<DerivationResult, any Error>) {
        self.requiresCard = requiresCard
        self.result = result
    }

    func deriveKeys(derivations: [Data: [DerivationPath]], completion: @escaping (Result<DerivationResult, any Error>) -> Void) {
        requestedDerivations.append(derivations)
        completion(result)
    }
}

private struct DerivationFailure: Error {}
