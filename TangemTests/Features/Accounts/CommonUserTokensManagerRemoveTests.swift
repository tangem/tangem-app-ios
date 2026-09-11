//
//  CommonUserTokensManagerRemoveTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemSdk
import TangemFoundation
import TangemAssets
@testable import Tangem

@Suite("Tests for `CommonUserTokensManager` token items removal logic")
struct CommonUserTokensManagerRemoveTests {
    // MARK: - Private properties

    private let ethereumMainnet = Blockchain.ethereum(testnet: false)
    private let derivationStyle: DerivationStyle = .v3
    private let mainAccountDerivationIndex = AccountModelUtils.mainAccountDerivationIndex

    // MARK: - Tests

    @Test("Coin is removed together with its tokens in one batch when tokens come first")
    func coinAndTokensAreRemovedInOneBatchWhenTokensComeFirst() throws {
        let fixtures = try makeFixtures()
        let sut = try makeSUT(storedTokenItems: [fixtures.coin, fixtures.usdt, fixtures.usdc])

        try sut.update(itemsToRemove: [fixtures.usdt, fixtures.usdc, fixtures.coin], itemsToAdd: [])

        #expect(sut.userTokens.isEmpty)
    }

    @Test("Coin is removed together with its tokens in one batch when coin comes first")
    func coinAndTokensAreRemovedInOneBatchWhenCoinComesFirst() throws {
        let fixtures = try makeFixtures()
        let sut = try makeSUT(storedTokenItems: [fixtures.coin, fixtures.usdt, fixtures.usdc])

        try sut.update(itemsToRemove: [fixtures.coin, fixtures.usdt, fixtures.usdc], itemsToAdd: [])

        #expect(sut.userTokens.isEmpty)
    }

    @Test("Removing a coin while one of its tokens stays throws and leaves the batch unapplied")
    func removingCoinWithRemainingTokenThrowsAndLeavesBatchUnapplied() throws {
        let fixtures = try makeFixtures()
        let storedTokenItems = [fixtures.coin, fixtures.usdt, fixtures.usdc]
        let sut = try makeSUT(storedTokenItems: storedTokenItems)

        let error = try #require(throws: CommonUserTokensManager.Error.self) {
            try sut.update(itemsToRemove: [fixtures.usdt, fixtures.coin], itemsToAdd: [])
        }

        guard case .failedToDeleteNetworkHasTokens(let tokenItem) = error else {
            Issue.record("Expected `failedToDeleteNetworkHasTokens`, got \(error)")
            return
        }

        #expect(tokenItem == fixtures.coin)
        #expect(sut.userTokens == storedTokenItems)
    }

    @Test("Removing a coin while a token is being added to its network throws and leaves the batch unapplied")
    func removingCoinWithTokenBeingAddedThrowsAndLeavesBatchUnapplied() throws {
        let fixtures = try makeFixtures()
        let storedTokenItems = [fixtures.coin, fixtures.usdt]
        let sut = try makeSUT(storedTokenItems: storedTokenItems)

        let error = try #require(throws: CommonUserTokensManager.Error.self) {
            try sut.update(itemsToRemove: [fixtures.usdt, fixtures.coin], itemsToAdd: [fixtures.dai])
        }

        guard case .failedToDeleteNetworkHasTokens(let tokenItem) = error else {
            Issue.record("Expected `failedToDeleteNetworkHasTokens`, got \(error)")
            return
        }

        #expect(tokenItem == fixtures.coin)
        #expect(sut.userTokens == storedTokenItems)
    }

    @Test("Single removal of a coin with tokens is a no-op")
    func singleRemovalOfCoinWithTokensIsNoOp() throws {
        let fixtures = try makeFixtures()
        let storedTokenItems = [fixtures.coin, fixtures.usdt, fixtures.usdc]
        let sut = try makeSUT(storedTokenItems: storedTokenItems)

        sut.remove(fixtures.coin)

        #expect(sut.userTokens == storedTokenItems)
    }

    @Test("Token is removed while its coin stays")
    func tokenIsRemovedWhileCoinStays() throws {
        let fixtures = try makeFixtures()
        let sut = try makeSUT(storedTokenItems: [fixtures.coin, fixtures.usdt, fixtures.usdc])

        try sut.update(itemsToRemove: [fixtures.usdt], itemsToAdd: [])

        #expect(sut.userTokens == [fixtures.coin, fixtures.usdc])
    }

    // MARK: - Helpers

    private func makeFixtures() throws -> Fixtures {
        let derivationPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: mainAccountDerivationIndex)
        let blockchainNetwork = BlockchainNetwork(ethereumMainnet, derivationPath: derivationPath)

        return Fixtures(
            coin: .blockchain(blockchainNetwork),
            usdt: .token(Token(name: "USDT", symbol: "USDT", contractAddress: "0xUSDT", decimalCount: 6), blockchainNetwork),
            usdc: .token(Token(name: "USDC", symbol: "USDC", contractAddress: "0xUSDC", decimalCount: 6), blockchainNetwork),
            dai: .token(Token(name: "DAI", symbol: "DAI", contractAddress: "0xDAI", decimalCount: 18), blockchainNetwork)
        )
    }

    private func derivationPath(
        for blockchain: Blockchain,
        style: DerivationStyle,
        accountIndex: Int
    ) throws -> DerivationPath {
        guard let basePath = blockchain.derivationPath(for: style) else {
            throw "No derivation path for blockchain \(blockchain) and style \(style)"
        }

        return try AccountDerivationPathHelper(blockchain: blockchain).makeDerivationPath(from: basePath, forAccountWithIndex: accountIndex)
    }

    private func makeSUT(storedTokenItems: [TokenItem]) throws -> CommonUserTokensManager {
        let storedTokens = StoredEntryConverter.convertToStoredEntries(storedTokenItems)
        let icon = AccountModel.CompositeIcon(
            name: try #require(AccountModel.CompositeIcon.Name.allCases.randomElement()),
            color: try #require(AccountModel.CompositeIcon.Color.allCases.randomElement())
        )
        let config = CryptoAccountPersistentConfig(
            derivationIndex: mainAccountDerivationIndex,
            name: .empty,
            icon: icon
        )
        let account = StoredCryptoAccount(
            config: config,
            tokenListAppearance: .default,
            tokens: storedTokens
        )
        let repository = UserTokensRepositoryStub(cryptoAccount: account)
        let derivationInfo = CommonUserTokensManager.DerivationInfo(
            derivationIndex: mainAccountDerivationIndex,
            derivationStyle: derivationStyle
        )
        let userWalletId = UserWalletId(value: .randomData(count: 32))

        return CommonUserTokensManager(
            userWalletId: userWalletId,
            userTokensRepository: repository,
            derivationInfo: derivationInfo,
            existingCurves: EllipticCurve.allCases,
            persistentBlockchains: [],
            shouldLoadExpressAvailability: false,
            hardwareLimitationsUtil: HardwareLimitationsUtil(config: UserWalletConfigStubs.walletV2Stub)
        )
    }
}

// MARK: - Auxiliary types

private extension CommonUserTokensManagerRemoveTests {
    struct Fixtures {
        let coin: TokenItem
        let usdt: TokenItem
        let usdc: TokenItem
        let dai: TokenItem
    }
}
