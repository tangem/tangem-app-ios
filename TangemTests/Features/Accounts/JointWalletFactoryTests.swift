//
//  JointWalletFactoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BlockchainSdk
import TangemSdk
@testable import Tangem

// MARK: - Tests

/// The wallet of a joint account lives at the address the account is given, not at the one its key derives.
@Suite("Tests for building the wallet of a joint account")
struct JointWalletFactoryTests {
    @Test("Without an address there is no wallet to build; once it arrives, the same factory builds the wallet there")
    func walletFollowsTheAddress() throws {
        let safeAddressProvider = JointAccountSafeAddressProviderStub()
        let sut = JointWalletFactory(
            defaultWalletFactory: DefaultWalletFactoryStub(),
            safeAddressProvider: safeAddressProvider,
            userRoleService: JointAccountUserRoleServiceMock(address: JointAccountCompositionFixture.ownAddress)
        )
        let blockchainNetwork = BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)

        let error = #expect(throws: AnyWalletFactoryError.self) {
            try sut.makeWallet(blockchainNetwork: blockchainNetwork, keys: [])
        }
        guard case .accountAddressUnavailable? = error else {
            Issue.record("Expected the address to be reported unavailable, got \(String(describing: error))")
            return
        }

        safeAddressProvider.send(Self.safeAddress)
        let wallet = try sut.makeWallet(blockchainNetwork: blockchainNetwork, keys: [])

        #expect(wallet.address == Self.safeAddress)
        #expect(wallet.publicKey == DefaultWalletFactoryStub.publicKey)
    }

    @Test("A key arriving for an account whose members exclude this wallet builds no wallet, read the moment the key arrives")
    func lateKeyOutsideTheMembersBuildsNoWallet() throws {
        let outcome = Self.walletBuiltWhenTheKeyArrives(memberAddress: JointAccountCompositionFixture.strangerAddress)

        let error = #expect(throws: AnyWalletFactoryError.self) { try outcome.get() }
        guard case .accountAddressUnavailable? = error else {
            Issue.record("Expected the address to be reported unavailable, got \(String(describing: error))")
            return
        }
    }

    @Test("A key arriving for an account this wallet is a member of builds the wallet at its Safe")
    func lateKeyOfAMemberBuildsTheWallet() throws {
        let outcome = Self.walletBuiltWhenTheKeyArrives(memberAddress: JointAccountCompositionFixture.ownAddress)

        #expect(try outcome.get().address == Self.checksummedSafeAddress)
    }

    @Test("A token the backend files under another key builds no wallet while this wallet's own key is unknown, even with that key at hand")
    func tokenAtAForeignPathBuildsNoWalletWithoutTheOwnKey() throws {
        let foreignPath = try DerivationPath(rawPath: "m/44'/60'/0'/0/0")
        let keysRepository = KeysRepositoryTestsMock(
            keys: [JointAccountCompositionFixture.masterKey(derivedKeys: [foreignPath: JointAccountCompositionFixture.derivedKey])]
        )
        let sut = Self.makeSUT(
            memberAddress: JointAccountCompositionFixture.strangerAddress,
            keysRepository: keysRepository
        )

        let error = #expect(throws: AnyWalletFactoryError.self) {
            try sut.makeWallet(blockchainNetwork: Self.network(at: foreignPath), keys: keysRepository.keys)
        }
        guard case .noDerivation? = error else {
            Issue.record("Expected the own key to be reported missing, got \(String(describing: error))")
            return
        }
    }

    @Test("A wallet that cannot derive the account's key builds no wallet, even with a factory that does not need it")
    func walletThatCannotDeriveTheKeyBuildsNoWallet() {
        let keysRepository = KeysRepositoryTestsMock(keys: [JointAccountCompositionFixture.masterKey()])
        let sut = Self.makeSUT(
            memberAddress: JointAccountCompositionFixture.strangerAddress,
            keysRepository: keysRepository,
            defaultWalletFactory: SimpleWalletFactory()
        )

        let error = #expect(throws: AnyWalletFactoryError.self) {
            try sut.makeWallet(blockchainNetwork: Self.network(at: JointAccountCompositionFixture.ownKeyPath), keys: keysRepository.keys)
        }
        guard case .noDerivation? = error else {
            Issue.record("Expected the own key to be reported missing, got \(String(describing: error))")
            return
        }
    }
}

// MARK: - Helpers

private extension JointWalletFactoryTests {
    static let safeAddress = "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b"
    static let checksummedSafeAddress = "0x9295a5836685C5F5f42242f9B64d23E46F8c259F"

    static func network(at derivationPath: DerivationPath) -> BlockchainNetwork {
        BlockchainNetwork(.ethereum(testnet: false), derivationPath: derivationPath)
    }

    static func makeSUT(
        memberAddress: String,
        keysRepository: KeysRepositoryTestsMock,
        defaultWalletFactory: any AnyWalletFactory = HDWalletFactory()
    ) -> JointWalletFactory {
        let repository = JointAccountsRepositoryStub(jointAccounts: [
            JointAccountCompositionFixture.storedAccount(
                status: .active(safeAddress: checksummedSafeAddress),
                membersCount: 1,
                members: [JointAccountCompositionFixture.member(address: memberAddress, role: .creator)]
            ),
        ])
        let userRoleService = JointAccountCompositionFixture.makeUserRoleService(repository: repository, keysProvider: keysRepository)
        let statusProvider = JointAccountCompositionFixture.makeStatusProvider(repository: repository, userRoleService: userRoleService)

        return JointWalletFactory(
            defaultWalletFactory: defaultWalletFactory,
            safeAddressProvider: statusProvider,
            userRoleService: userRoleService
        )
    }

    static func walletBuiltWhenTheKeyArrives(memberAddress: String) -> Result<Wallet, any Error> {
        let keysRepository = KeysRepositoryTestsMock(keys: [JointAccountCompositionFixture.masterKey()])
        let sut = makeSUT(memberAddress: memberAddress, keysRepository: keysRepository)
        var outcome: Result<Wallet, any Error>?

        let subscription = keysRepository.keysPublisher
            .dropFirst()
            .sink { keys in
                outcome = Result {
                    try sut.makeWallet(blockchainNetwork: network(at: JointAccountCompositionFixture.ownKeyPath), keys: keys)
                }
            }

        keysRepository.update(derivations: JointAccountCompositionFixture.ownKeyDerivation)
        withExtendedLifetime(subscription) {}

        return outcome ?? .failure(CancellationError())
    }

    /// The wallet the member's own key derives, whose address the joint account's is meant to replace.
    struct DefaultWalletFactoryStub: AnyWalletFactory {
        static let publicKey = Wallet.PublicKey(seedKey: Data(repeating: 0x01, count: 33), derivationType: .none)

        func makeWallet(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet {
            Wallet(
                blockchain: blockchainNetwork.blockchain,
                publicKey: Self.publicKey,
                addressesProvider: CommonAddressesProvider(defaultAddress: PlainAddress(value: "0xDerivedFromTheKey", type: .default))
            )
        }
    }
}
