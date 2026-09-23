//
//  PolymarketSwapParametersFactoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@Suite
struct PolymarketSwapParametersFactoryTests {
    private static let fundingAddress = "0xC8C0C4575EBdd47fF173ba56962e9827440dabfa"

    private static let baseFundingAddress = "0x1F0f1B6b2eC7A0aC4F0d1b7F9b1E3aD5c2B4A6e8"

    private static let depositTarget = PolymarketAccountFundsInteractor.DepositTarget(
        entry: PolymarketDepositAssetCatalog.usdcOnPolygon,
        tokenItem: PolymarketUtilities.usdcTokenItem,
        minCheckoutUSD: 2,
        fundingAddress: fundingAddress
    )

    private static let baseDepositTarget = PolymarketAccountFundsInteractor.DepositTarget(
        entry: PolymarketDepositAssetCatalog.usdcOnBase,
        tokenItem: PolymarketDepositAssetCatalog.usdcOnBase.makeTokenItem(
            supportedBlockchains: [.base(testnet: false)]
        )!,
        minCheckoutUSD: 2,
        fundingAddress: baseFundingAddress
    )

    private static let walletUSDCOnBase = TokenItem.accountToken(
        symbol: "USDC",
        contract: PolymarketDepositAssetCatalog.usdcOnBase.contractAddress,
        blockchain: .base(testnet: false)
    )

    @Test("The receive side is addressed to the funding address the bridge issued")
    func receiveTokenCarriesFundingAddress() throws {
        let parameters = try #require(makeSUT().make(depositTargets: [Self.depositTarget]))
        let receive = try #require(receiveToken(from: parameters))

        #expect(receive.destination?.destination.transactionAddress == Self.fundingAddress)
        #expect(receive.destination?.destinationTag == nil)
    }

    @Test("The account's balance is shown in its own units, not converted to fiat")
    func balanceIsDenominatedInTheAccountToken() throws {
        let parameters = try #require(makeSUT().make(depositTargets: [Self.depositTarget]))
        let receive = try #require(receiveToken(from: parameters))
        let presentation = try #require(receive.presentation)

        #expect(presentation.balanceDenomination == .token)
    }

    @Test("The receive side is the token the bridge accepts, not the pUSD the account holds")
    func receiveTokenIsUSDCOnPolygon() throws {
        let parameters = try #require(makeSUT().make(depositTargets: [Self.depositTarget]))
        let receive = try #require(receiveToken(from: parameters))

        #expect(receive.tokenItem == PolymarketUtilities.usdcTokenItem)
    }

    @Test("Without a single deposit target there is nothing to open the swap with")
    func noParametersWithoutTargets() {
        #expect(makeSUT().make(depositTargets: []) == nil)
    }

    @Test("Neither side of the pair can be swapped away from the deposit")
    func pairIsLocked() throws {
        let parameters = try #require(makeSUT().make(depositTargets: [Self.depositTarget]))
        let config = try #require(configuration(from: parameters))

        #expect(config.isPairReversalEnabled == false)
        #expect(config.receiveTokenSelection.isSelectionEnabled == false)
    }

    @Test("The source side is preselected by the shared funding rules instead of being left empty")
    func sourceIsPreselected() throws {
        let parameters = try #require(makeSUT().make(depositTargets: [Self.depositTarget]))

        #expect(sourceResolver(from: parameters) is PolymarketDepositSourceResolver)
    }

    @Test("An ordinary crypto token survives the filter that keeps the payment account out")
    func cryptoTokensRemainDepositSources() throws {
        let parameters = try #require(makeSUT().make(depositTargets: [Self.depositTarget]))
        let config = try #require(configuration(from: parameters))
        let provider = try #require(config.sourceTokenSelection.walletsProvider as? FilteredTokenSelectorWalletsProvider)

        #expect(provider.isIncluded(CampaignsFixtures.makeTokenSelectorItem()))
        #expect(config.sourceTokenSelection.allowsMarketsTokens)
    }

    @Test("A source holding the same USDC on another network is met there, so the pair is a transfer")
    func destinationFollowsSourceNetwork() throws {
        let resolver = try multiNetworkDestinationResolver()

        let resolved = resolver.resolveDestination(for: SwapableTokenStub(tokenItem: Self.walletUSDCOnBase))

        #expect(resolved.tokenItem.expressCurrency == Self.walletUSDCOnBase.expressCurrency)
        #expect(resolved.destination?.destination.transactionAddress == Self.baseFundingAddress)
    }

    @Test("A source in a network no target lives in falls back to the first target the catalog names")
    func foreignSourceFallsBackToTheFirstTarget() throws {
        let resolver = try multiNetworkDestinationResolver()

        let resolved = resolver.resolveDestination(for: SwapableTokenStub(blockchain: .bitcoin(testnet: false)))

        #expect(resolved.tokenItem == PolymarketUtilities.usdcTokenItem)
        #expect(resolved.destination?.destination.transactionAddress == Self.fundingAddress)
    }
}

// MARK: - Fixtures

private extension PolymarketSwapParametersFactoryTests {
    func makeSUT(supportedBlockchains: Set<Blockchain> = [PolymarketUtilities.blockchain]) -> PolymarketSwapParametersFactory {
        PolymarketSwapParametersFactory(
            userWalletInfo: UserWalletInfo(
                name: "Test",
                id: UserWalletId(value: Data([0x01])),
                config: UserWalletConfigStub(supportedBlockchains: supportedBlockchains),
                backupState: .valid,
                refcode: nil,
                signerFactory: TangemSignerFactory(),
                emailDataProvider: EmailDataProviderStub()
            ),
            walletModelsProvider: MainScreenUIOrderedWalletModelsProvider(userWalletModel: UserWalletModelMock()),
            accountModel: PolymarketAccountModelStub(state: .active)
        )
    }

    func receiveToken(from parameters: PredefinedSwapParameters) -> SendReceiveToken? {
        guard case .to(let token, _, _) = parameters else { return nil }
        return token
    }

    func sourceResolver(from parameters: PredefinedSwapParameters) -> (any SwapSourceTokenResolver)? {
        guard case .to(_, let resolver, _) = parameters else { return nil }
        return resolver
    }

    func configuration(from parameters: PredefinedSwapParameters) -> SwapFlowConfiguration? {
        guard case .to(_, _, let configuration) = parameters else { return nil }
        return configuration
    }

    func multiNetworkDestinationResolver() throws -> any SwapDestinationTokenResolver {
        let factory = makeSUT(supportedBlockchains: [PolymarketUtilities.blockchain, .base(testnet: false)])
        let parameters = try #require(factory.make(depositTargets: [Self.depositTarget, Self.baseDepositTarget]))

        return try #require(configuration(from: parameters)?.receiveTokenSelection.destinationResolver)
    }
}
