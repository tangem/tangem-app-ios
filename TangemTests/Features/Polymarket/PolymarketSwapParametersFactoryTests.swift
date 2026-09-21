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

    private static let depositTarget = PolymarketAccountFundsInteractor.DepositTarget(
        asset: PolymarketSupportedAsset(
            chainId: "137",
            chainName: "Polygon",
            family: .evm,
            token: PolymarketSupportedAsset.Token(
                name: "USD Coin",
                symbol: "USDC",
                address: PolymarketUtilities.usdcContractAddress,
                decimalCount: 6
            ),
            minCheckoutUSD: 2
        ),
        fundingAddress: fundingAddress
    )

    @Test("The receive side is addressed to the funding address the bridge issued")
    func receiveTokenCarriesFundingAddress() throws {
        let parameters = makeSUT().make(depositTarget: Self.depositTarget)
        let receive = try #require(receiveToken(from: parameters))

        #expect(receive.destination?.destination.transactionAddress == Self.fundingAddress)
        #expect(receive.destination?.destinationTag == nil)
    }

    @Test("The receive side is the token the bridge accepts, not the pUSD the account holds")
    func receiveTokenIsUSDCOnPolygon() throws {
        let parameters = makeSUT().make(depositTarget: Self.depositTarget)
        let receive = try #require(receiveToken(from: parameters))

        #expect(receive.tokenItem == PolymarketUtilities.usdcTokenItem)
    }

    @Test("Neither side of the pair can be swapped away from the deposit")
    func pairIsLocked() throws {
        let parameters = makeSUT().make(depositTarget: Self.depositTarget)
        let config = try #require(configuration(from: parameters))

        #expect(config.isPairReversalEnabled == false)
        #expect(config.receiveTokenSelection.isSelectionEnabled == false)
    }

    @Test("The source side is preselected by the shared funding rules instead of being left empty")
    func sourceIsPreselected() throws {
        let parameters = makeSUT().make(depositTarget: Self.depositTarget)

        #expect(sourceResolver(from: parameters) is PolymarketDepositSourceResolver)
    }

    @Test("The source list runs through a filter, and an ordinary token survives it")
    func sourceListIsFilteredAndKeepsOrdinaryTokens() throws {
        let config = try #require(configuration(from: makeSUT().make(depositTarget: Self.depositTarget)))
        let provider = try #require(config.sourceTokenSelection.walletsProvider as? FilteredTokenSelectorWalletsProvider)

        #expect(provider.isIncluded(CampaignsFixtures.makeTokenSelectorItem()))
    }

    @Test("Whatever source the user picks, the destination stays the deposit token")
    func destinationResolverIgnoresSource() throws {
        let parameters = makeSUT().make(depositTarget: Self.depositTarget)
        let config = try #require(configuration(from: parameters))
        let receive = try #require(receiveToken(from: parameters))
        let resolver = try #require(config.receiveTokenSelection.destinationResolver)

        let resolved = resolver.resolveDestination(for: SwapableTokenStub(blockchain: .polygon(testnet: false)))

        #expect(resolved.tokenItem == receive.tokenItem)
        #expect(resolved.destination?.destination.transactionAddress == Self.fundingAddress)
    }
}

// MARK: - Fixtures

private extension PolymarketSwapParametersFactoryTests {
    func makeSUT() -> PolymarketSwapParametersFactory {
        PolymarketSwapParametersFactory(
            userWalletInfo: UserWalletInfo(
                name: "Test",
                id: UserWalletId(value: Data([0x01])),
                config: UserWalletConfigStub(),
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
}
