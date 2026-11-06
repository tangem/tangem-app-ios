//
//  CommonUserTokensManagerSupportedBlockchainsTests.swift
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
@testable import Tangem

@Suite("Tests for `CommonUserTokensManager` adding only the blockchains the wallet config supports")
struct CommonUserTokensManagerSupportedBlockchainsTests {
    // MARK: - Private properties

    private let legacySolana = Blockchain.solana(curve: .ed25519, testnet: false)
    private let walletSolana = Blockchain.solana(curve: .ed25519_slip0010, testnet: false)
    private let derivationStyle: DerivationStyle = .v3

    // MARK: - Tests

    @Test("A token on a curve the wallet config doesn't support is rejected and nothing is stored")
    func tokenOnUnsupportedCurveIsRejected() throws {
        let sut = try makeSUT(supportedBlockchains: [walletSolana])

        let error = try #require(throws: CommonUserTokensManager.Error.self) {
            try sut.update(itemsToRemove: [], itemsToAdd: [makePumpToken(network: BlockchainNetwork(legacySolana, derivationPath: nil))])
        }

        guard case .unsupportedBlockchain(let blockchain, _) = error else {
            Issue.record("Expected `unsupportedBlockchain`, got \(error)")
            return
        }

        #expect(blockchain == legacySolana)
        #expect(sut.userTokens.isEmpty)
    }

    @Test("A token on a blockchain the wallet config supports is stored together with its network")
    func tokenOnSupportedBlockchainIsStored() throws {
        let sut = try makeSUT(supportedBlockchains: [walletSolana])

        try sut.update(itemsToRemove: [], itemsToAdd: [makePumpToken(network: BlockchainNetwork(walletSolana, derivationPath: nil))])

        let storedNetwork = try makeStoredNetwork(for: walletSolana)
        #expect(sut.userTokens == [.blockchain(storedNetwork), makePumpToken(network: storedNetwork)])
    }
}

// MARK: - Helpers

private extension CommonUserTokensManagerSupportedBlockchainsTests {
    func makePumpToken(network: BlockchainNetwork) -> TokenItem {
        let token = Token(
            name: "Pump",
            symbol: "PUMP",
            contractAddress: "pumpCmXqMfrsAkQ5r49WcJnRayYRqmXz6ae8H7H9Dfn",
            decimalCount: 6,
            id: "pump-fun"
        )

        return .token(token, network)
    }

    func makeStoredNetwork(for blockchain: Blockchain) throws -> BlockchainNetwork {
        let basePath = try #require(blockchain.derivationPath(for: derivationStyle))
        let derivationPath = try AccountDerivationPathHelper(blockchain: blockchain).makeDerivationPath(
            from: basePath,
            forAccountWithIndex: AccountModelUtils.mainAccountDerivationIndex
        )

        return BlockchainNetwork(blockchain, derivationPath: derivationPath)
    }

    func makeSUT(supportedBlockchains: Set<Blockchain>) throws -> CommonUserTokensManager {
        let derivationIdentity = CryptoAccountDerivationIdentity(
            derivationIndex: AccountModelUtils.mainAccountDerivationIndex,
            type: .crypto
        )
        let icon = AccountModel.CompositeIcon(
            name: try #require(AccountModel.CompositeIcon.Name.allCases.randomElement()),
            color: try #require(AccountModel.CompositeIcon.Color.allCases.randomElement())
        )
        let account = StoredCryptoAccount(
            config: CryptoAccountPersistentConfig(derivationIdentity: derivationIdentity, name: .empty, icon: icon),
            tokenListAppearance: .default,
            tokens: []
        )
        let derivationPathBuilder = AccountDerivationPathBuilderFactory.makeBuilder(
            forAccountWith: derivationIdentity,
            derivationStyle: derivationStyle
        )
        let config = UserWalletConfigStub(supportedBlockchains: supportedBlockchains)

        return CommonUserTokensManager(
            userWalletId: UserWalletId(value: .randomData(count: 32)),
            configProvider: CommonUserWalletConfigProvider(config: config),
            userTokensRepository: UserTokensRepositoryStub(cryptoAccount: account),
            derivationPathBuilder: derivationPathBuilder,
            existingCurves: EllipticCurve.allCases,
            persistentBlockchains: [],
            shouldLoadExpressAvailability: false,
            hardwareLimitationsUtil: HardwareLimitationsUtil(config: config)
        )
    }
}
