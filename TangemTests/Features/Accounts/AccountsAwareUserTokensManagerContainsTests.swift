//
//  AccountsAwareUserTokensManagerContainsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
import BlockchainSdk
import TangemSdk
import TangemFoundation
import TangemAssets
@testable import Tangem

// MARK: - Tests

@Suite("Test for `AccountsAwareUserTokensManager.contains(_:derivationInsensitive:)` logic")
struct AccountsAwareUserTokensManagerContainsTests {
    // MARK: - Private properties

    private let ethereumMainnet = Blockchain.ethereum(testnet: false)
    private let bitcoinMainnet = Blockchain.bitcoin(testnet: false)
    private let bscMainnet = Blockchain.bsc(testnet: false)
    private let derivationStyle: DerivationStyle = .v3
    private let mainAccountDerivationIndex = AccountModelUtils.mainAccountDerivationIndex
    private let nonMainAccountDerivationIndex = 100

    // MARK: - Group 1: Derivation path preservation

    @Test("Nil derivation is enriched for main account")
    func nilDerivationIsEnrichedForMainAccount() throws {
        let mainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: mainAccountDerivationIndex)
        let storedItem = TokenItem.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: mainAccountPath))
        let sut = try makeSUT(derivationIndex: mainAccountDerivationIndex, derivationStyle: derivationStyle, storedTokenItems: [storedItem])

        let result = sut.contains(.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: nil)), derivationInsensitive: false)

        #expect(result == true)
    }

    @Test("Nil derivation is enriched for non-main account")
    func nilDerivationIsEnrichedForNonMainAccount() throws {
        let nonMainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: nonMainAccountDerivationIndex)
        let storedItem = TokenItem.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: nonMainAccountPath))
        let sut = try makeSUT(derivationIndex: nonMainAccountDerivationIndex, derivationStyle: derivationStyle, storedTokenItems: [storedItem])

        let result = sut.contains(.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: nil)), derivationInsensitive: false)

        #expect(result == true)
    }

    @Test("Existing derivation preserved for main account")
    func existingDerivationPreservedMainAccount() throws {
        let mainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: mainAccountDerivationIndex)
        let storedItem = TokenItem.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: mainAccountPath))
        let sut = try makeSUT(derivationIndex: mainAccountDerivationIndex, derivationStyle: derivationStyle, storedTokenItems: [storedItem])

        let result = sut.contains(.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: mainAccountPath)), derivationInsensitive: false)

        #expect(result == true)
    }

    @Test("Existing derivation preserved does not match wrong account")
    func existingDerivationPreservedDoesNotMatchWrongAccount() throws {
        let mainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: mainAccountDerivationIndex)
        let nonMainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: nonMainAccountDerivationIndex)
        let storedItem = TokenItem.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: mainAccountPath))
        let sut = try makeSUT(derivationIndex: mainAccountDerivationIndex, derivationStyle: derivationStyle, storedTokenItems: [storedItem])

        let result = sut.contains(.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: nonMainAccountPath)), derivationInsensitive: false)

        #expect(result == false)
    }

    @Test("Existing derivation not rewritten to wrong account (the bug fix)")
    func existingDerivationNotRewrittenToWrongAccount() throws {
        let mainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: mainAccountDerivationIndex)
        let nonMainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: nonMainAccountDerivationIndex)
        let storedItem = TokenItem.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: nonMainAccountPath))
        let sut = try makeSUT(derivationIndex: nonMainAccountDerivationIndex, derivationStyle: derivationStyle, storedTokenItems: [storedItem])

        // Passing account-0 path should NOT be rewritten to account-1
        let result = sut.contains(.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: mainAccountPath)), derivationInsensitive: false)

        #expect(result == false)
    }

    // MARK: - Group 2: derivationInsensitive flag

    @Test("Derivation insensitive matches different paths")
    func derivationInsensitiveMatchesDifferentPaths() throws {
        let mainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: mainAccountDerivationIndex)
        let nonMainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: nonMainAccountDerivationIndex)
        let storedItem = TokenItem.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: mainAccountPath))
        let sut = try makeSUT(derivationIndex: mainAccountDerivationIndex, derivationStyle: derivationStyle, storedTokenItems: [storedItem])

        let result = sut.contains(.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: nonMainAccountPath)), derivationInsensitive: true)

        #expect(result == true)
    }

    @Test("Derivation sensitive rejects different paths")
    func derivationSensitiveRejectsDifferentPaths() throws {
        let mainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: mainAccountDerivationIndex)
        let nonMainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: nonMainAccountDerivationIndex)
        let storedItem = TokenItem.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: mainAccountPath))
        let sut = try makeSUT(derivationIndex: mainAccountDerivationIndex, derivationStyle: derivationStyle, storedTokenItems: [storedItem])

        let result = sut.contains(.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: nonMainAccountPath)), derivationInsensitive: false)

        #expect(result == false)
    }

    @Test("Derivation insensitive matches token by same contract address")
    func derivationInsensitiveMatchesTokenBySameContractAddress() throws {
        let mainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: mainAccountDerivationIndex)
        let nonMainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: nonMainAccountDerivationIndex)
        let usdt = Token(name: "Tether USD", symbol: "USDT", contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7", decimalCount: 6)
        let storedItem = TokenItem.token(usdt, BlockchainNetwork(ethereumMainnet, derivationPath: mainAccountPath))
        let sut = try makeSUT(derivationIndex: mainAccountDerivationIndex, derivationStyle: derivationStyle, storedTokenItems: [storedItem])

        let inputItem = TokenItem.token(usdt, BlockchainNetwork(ethereumMainnet, derivationPath: nonMainAccountPath))
        let result = sut.contains(inputItem, derivationInsensitive: true)

        #expect(result == true)
    }

    @Test("Derivation insensitive rejects different token")
    func derivationInsensitiveRejectsDifferentToken() throws {
        let mainAccountPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: mainAccountDerivationIndex)
        let usdt = Token(name: "Tether USD", symbol: "USDT", contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7", decimalCount: 6)
        let dai = Token(name: "Dai Stablecoin", symbol: "DAI", contractAddress: "0x6B175474E89094C44Da98b954EedeAC495271d0F", decimalCount: 18)
        let storedItem = TokenItem.token(usdt, BlockchainNetwork(ethereumMainnet, derivationPath: mainAccountPath))
        let sut = try makeSUT(derivationIndex: mainAccountDerivationIndex, derivationStyle: derivationStyle, storedTokenItems: [storedItem])

        let inputItem = TokenItem.token(dai, BlockchainNetwork(ethereumMainnet, derivationPath: mainAccountPath))
        let result = sut.contains(inputItem, derivationInsensitive: true)

        #expect(result == false)
    }

    @Test("Derivation insensitive rejects different network")
    func derivationInsensitiveRejectsDifferentNetwork() throws {
        let ethPath = try derivationPath(for: ethereumMainnet, style: derivationStyle, accountIndex: mainAccountDerivationIndex)
        let bscPath = try derivationPath(for: bscMainnet, style: derivationStyle, accountIndex: mainAccountDerivationIndex)
        let storedItem = TokenItem.blockchain(BlockchainNetwork(ethereumMainnet, derivationPath: ethPath))
        let sut = try makeSUT(derivationIndex: mainAccountDerivationIndex, derivationStyle: derivationStyle, storedTokenItems: [storedItem])

        let inputItem = TokenItem.blockchain(BlockchainNetwork(bscMainnet, derivationPath: bscPath))
        let result = sut.contains(inputItem, derivationInsensitive: true)

        #expect(result == false)
    }

    // MARK: - Group 3: Main vs non-main account enrichment

    @Test("Main account enriches nil derivation blockchain item")
    func mainAccountEnrichesNilDerivationBlockchainItem() throws {
        let mainAccountPath = try derivationPath(for: bitcoinMainnet, style: derivationStyle, accountIndex: mainAccountDerivationIndex)
        let storedItem = TokenItem.blockchain(BlockchainNetwork(bitcoinMainnet, derivationPath: mainAccountPath))
        let sut = try makeSUT(derivationIndex: mainAccountDerivationIndex, derivationStyle: derivationStyle, storedTokenItems: [storedItem])

        let result = sut.contains(.blockchain(BlockchainNetwork(bitcoinMainnet, derivationPath: nil)), derivationInsensitive: false)

        #expect(result == true)
    }

    @Test("Non-main account enriches nil derivation to correct index")
    func nonMainAccountEnrichesNilDerivationToCorrectIndex() throws {
        let nonMainAccountPath = try derivationPath(for: bitcoinMainnet, style: derivationStyle, accountIndex: nonMainAccountDerivationIndex)
        let storedItem = TokenItem.blockchain(BlockchainNetwork(bitcoinMainnet, derivationPath: nonMainAccountPath))
        let sut = try makeSUT(derivationIndex: nonMainAccountDerivationIndex, derivationStyle: derivationStyle, storedTokenItems: [storedItem])

        let result = sut.contains(.blockchain(BlockchainNetwork(bitcoinMainnet, derivationPath: nil)), derivationInsensitive: false)

        #expect(result == true)
    }

    @Test("Non-main account enriched nil does not match main tokens")
    func nonMainAccountEnrichedNilDoesNotMatchMainTokens() throws {
        let mainAccountPath = try derivationPath(for: bitcoinMainnet, style: derivationStyle, accountIndex: mainAccountDerivationIndex)
        let storedItem = TokenItem.blockchain(BlockchainNetwork(bitcoinMainnet, derivationPath: mainAccountPath))
        let sut = try makeSUT(derivationIndex: nonMainAccountDerivationIndex, derivationStyle: derivationStyle, storedTokenItems: [storedItem])

        // Nil derivation will be enriched to account-1 path, which won't match the stored account-0 path
        let result = sut.contains(.blockchain(BlockchainNetwork(bitcoinMainnet, derivationPath: nil)), derivationInsensitive: false)

        #expect(result == false)
    }

    // MARK: - Helpers

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

    private func makeSUT(
        derivationIndex: Int,
        derivationStyle: DerivationStyle,
        storedTokenItems: [TokenItem]
    ) throws -> AccountsAwareUserTokensManager {
        let storedTokens = StoredEntryConverter.convertToStoredEntries(storedTokenItems)
        let icon = AccountModel.CompositeIcon(
            name: try #require(AccountModel.CompositeIcon.Name.allCases.randomElement()),
            color: try #require(AccountModel.CompositeIcon.Color.allCases.randomElement())
        )
        let config = CryptoAccountPersistentConfig(
            derivationIndex: derivationIndex,
            name: .empty,
            icon: icon
        )
        let account = StoredCryptoAccount(
            config: config,
            tokenListAppearance: .default,
            tokens: storedTokens
        )
        let repository = UserTokensRepositoryStub(cryptoAccount: account)
        let derivationInfo = AccountsAwareUserTokensManager.DerivationInfo(
            derivationIndex: derivationIndex,
            derivationStyle: derivationStyle
        )
        let userWalletId = UserWalletId(value: .randomData(count: 32))

        return AccountsAwareUserTokensManager(
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
