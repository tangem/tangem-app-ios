//
//  PolymarketDepositSwapPredefinedParametersBuilderTests.swift
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

@Suite(.timeLimit(.minutes(1)))
struct PolymarketDepositSwapPredefinedParametersBuilderTests {
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
        let parameters = makeSUT().make()
        let receive = try #require(parameters.receive.initialReceive.value)

        #expect(receive.destination?.destination.transactionAddress == Self.fundingAddress)
        #expect(receive.destination?.destinationTag == nil)
    }

    @Test("The receive side is USDC on Polygon shown in dollars, as Tangem Pay shows its own, not the pUSD the account holds")
    func receiveSideIsUSDCPresentedInDollars() throws {
        let parameters = makeSUT().make()
        let receive = try #require(parameters.receive.initialReceive.value)
        let presentation = try #require(receive.presentation)

        #expect(receive.tokenItem == PolymarketUtilities.usdcTokenItem)
        #expect(presentation.balanceDenomination == .fiat)
        #expect(presentation.currencySymbol == AppConstants.usdCurrencyCode)
    }

    @Test("The source side is preselected by the shared funding rules instead of being left empty")
    func sourceIsPreselected() {
        #expect(makeSUT().make().source is PolymarketDepositSourceResolver)
    }

    @Test("Neither side of the pair can be swapped away from the deposit")
    func pairIsLocked() {
        let config = makeSUT().make().configuration

        #expect(config.isPairReversalEnabled == false)
        #expect(config.receiveTokenSelection.isSelectionEnabled == false)
    }

    @Test("An ordinary crypto token survives the filter that keeps the payment account out")
    func cryptoTokensRemainDepositSources() throws {
        let config = makeSUT().make().configuration
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

private extension PolymarketDepositSwapPredefinedParametersBuilderTests {
    func makeSUT(
        otherTargets: [PolymarketAccountFundsInteractor.DepositTarget] = [],
        supportedBlockchains: Set<Blockchain> = [PolymarketUtilities.blockchain]
    ) -> PolymarketDepositSwapPredefinedParametersBuilder {
        PolymarketDepositSwapPredefinedParametersBuilder(
            userWalletModel: PolymarketDepositUserWalletModelStub(supportedBlockchains: supportedBlockchains),
            accountModel: PolymarketAccountModelStub(state: .active),
            defaultTarget: Self.depositTarget,
            otherTargets: otherTargets
        )
    }

    func multiNetworkDestinationResolver() throws -> any SwapDestinationTokenResolver {
        let parameters = makeSUT(
            otherTargets: [Self.baseDepositTarget],
            supportedBlockchains: [PolymarketUtilities.blockchain, .base(testnet: false)]
        )
        .make()

        return try #require(parameters.configuration.receiveTokenSelection.destinationResolver)
    }
}

// MARK: - Stubs

private final class PolymarketDepositUserWalletModelStub: UserWalletModelMock {
    private let supportedBlockchains: Set<Blockchain>

    init(supportedBlockchains: Set<Blockchain>) {
        self.supportedBlockchains = supportedBlockchains
    }

    override var config: UserWalletConfig { UserWalletConfigStub(supportedBlockchains: supportedBlockchains) }
}
