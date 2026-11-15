//
//  JointUserTokensRepositoryAdapterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
import BlockchainSdk
@testable import Tangem

// MARK: - Tests

/// What a joint account's tokens repository does on top of the plain adapter it wraps.
@Suite("Tests for the tokens repository of a joint account")
struct JointUserTokensRepositoryAdapterTests {
    @Test("The account is emitted anew once its address arrives, so that its wallets get built after all")
    func accountIsReEmittedWhenTheAddressArrives() {
        let safeAddressProvider = JointAccountSafeAddressProviderStub()
        let sut = Self.makeSUT(safeAddressProvider: safeAddressProvider)
        var emitted: [StoredCryptoAccount] = []
        let subscription = sut.cryptoAccountPublisher.sink { emitted.append($0) }

        #expect(emitted.count == 1)

        safeAddressProvider.send(Self.safeAddress)

        #expect(emitted.count == 2)
        #expect(emitted.last == Self.storedCryptoAccount)
        withExtendedLifetime(subscription) {}
    }

    @Test("The tokens leave the stream while there is no address and come back with it, and the account itself keeps them")
    func tokensFollowTheAddress() {
        let safeAddressProvider = JointAccountSafeAddressProviderStub()
        let sut = Self.makeSUT(
            cryptoAccount: Self.storedCryptoAccount.withTokens([Self.token]),
            safeAddressProvider: safeAddressProvider
        )
        var emittedTokens: [[StoredCryptoAccount.Token]] = []
        let subscription = sut.cryptoAccountPublisher.sink { emittedTokens.append($0.tokens) }

        safeAddressProvider.send(Self.safeAddress)
        safeAddressProvider.send(nil)

        #expect(emittedTokens == [[], [Self.token], []])
        #expect(sut.cryptoAccount.tokens == [Self.token])
        withExtendedLifetime(subscription) {}
    }

    @Test("A refresh reads the account's record along with the list")
    func refreshReadsTheRecordToo() async throws {
        let jointAccountsRepository = JointAccountsRepositoryStub()
        let sut = Self.makeSUT(jointAccountsRepository: jointAccountsRepository)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sut.updateLocalRepositoryFromServer { continuation.resume(with: $0) }
        }

        #expect(jointAccountsRepository.loadJointAccountsFromRemoteCallsCount == 1)
        withExtendedLifetime(sut) {}
    }
}

// MARK: - Helpers

private extension JointUserTokensRepositoryAdapterTests {
    static let safeAddress = "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b"

    static let storedCryptoAccount = StoredCryptoAccount(
        derivationIndex: 1,
        type: .joint,
        name: "Vacation fund",
        icon: StoredCryptoAccount.Icon(iconName: "Star", iconColor: "Azure"),
        tokens: [],
        grouping: .none,
        sorting: .manual
    )

    static let token = StoredCryptoAccount.Token(
        id: "ethereum",
        name: "Ethereum",
        symbol: "ETH",
        decimalCount: 18,
        blockchainNetwork: .known(blockchainNetwork: .init(
            blockchain: .ethereum(testnet: false),
            derivationPath: nil,
            settings: nil
        )),
        contractAddress: nil
    )

    static func makeSUT(
        cryptoAccount: StoredCryptoAccount = storedCryptoAccount,
        jointAccountsRepository: JointAccountsRepository = JointAccountsRepositoryStub(),
        safeAddressProvider: JointAccountSafeAddressProvider = JointAccountSafeAddressProviderStub()
    ) -> JointUserTokensRepositoryAdapter {
        JointUserTokensRepositoryAdapter(
            innerAdapter: UserTokensRepositoryStub(cryptoAccount: cryptoAccount),
            jointAccountsRepository: jointAccountsRepository,
            safeAddressProvider: safeAddressProvider
        )
    }
}
