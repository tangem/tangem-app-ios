//
//  PolymarketSwapParametersFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPolymarket

struct PolymarketSwapParametersFactory {
    let userWalletInfo: UserWalletInfo
    let walletModelsProvider: MainScreenUIOrderedWalletModelsProvider
    let accountModel: any PolymarketAccountModel

    func make(depositTargets: [PolymarketAccountFundsInteractor.DepositTarget]) -> PredefinedSwapParameters? {
        let candidates = depositTargets.map { depositTarget in
            PolymarketDepositReceiveTokenFactory(
                userWalletInfo: userWalletInfo,
                accountModel: accountModel,
                depositTarget: depositTarget
            )
            .makeReceiveToken()
        }

        guard let defaultDestination = candidates.first else {
            return nil
        }

        let sourceResolver = PolymarketDepositSourceResolver(
            userWalletInfo: userWalletInfo,
            walletModelsProvider: walletModelsProvider,
            depositCurrencies: Set(candidates.map(\.tokenItem.expressCurrency)),
            availabilityChecker: CommonFundingSourceAvailabilityChecker(userWalletInfo: userWalletInfo)
        )

        return PredefinedSwapParameters(
            userWalletInfo: defaultDestination.userWalletInfo,
            source: sourceResolver,
            receive: .resolved(defaultDestination),
            configuration: SwapFlowConfiguration(
                isPairReversalEnabled: false,
                sourceTokenSelection: .selectable(.filtered(isIncluded: { !$0.isPayAccount })),
                receiveTokenSelection: .followsSource(
                    AccountFundingDestinationResolver(candidates: candidates, defaultDestination: defaultDestination)
                ),
                summaryTitle: Localization.commonAddFunds
            )
        )
    }

    func make(withdrawingFrom source: PolymarketWithdrawSource, receiveToken: SendReceiveToken?) -> PredefinedSwapParameters {
        let sourceToken = PolymarketWithdrawSwapableTokenFactory(userWalletInfo: userWalletInfo, source: source)
            .makeSwapableToken()

        let receive: any SwapReceiveTokenResolver = if let receiveToken {
            .resolved(receiveToken)
        } else {
            .userSelection
        }

        return PredefinedSwapParameters(
            userWalletInfo: sourceToken.userWalletInfo,
            source: .resolved(sourceToken),
            receive: receive,
            configuration: SwapFlowConfiguration(
                isPairReversalEnabled: false,
                sourceTokenSelection: .fixed,
                receiveTokenSelection: .selectable(
                    .restricted(
                        walletsProvider: FilteredTokenSelectorWalletsProvider(
                            base: .cryptoJointAccounts(),
                            isIncluded: { item in
                                guard case .crypto = item.kind else {
                                    return false
                                }

                                return item.tokenItem.expressCurrency == PolymarketUtilities.usdcTokenItem.expressCurrency
                            }
                        ),
                        allowsMarketsTokens: false
                    )
                ),
                summaryTitle: Localization.predictionMainWithdraw,
                offeredReceiveTokens: [walletUSDCTokenItem].compactMap { $0 }
            )
        )
    }
}

// MARK: - Private implementation

private extension PolymarketSwapParametersFactory {
    var walletUSDCTokenItem: TokenItem? {
        let usdc = PolymarketUtilities.usdcTokenItem

        guard let id = usdc.id else {
            return nil
        }

        let network = NetworkModel(
            networkId: PolymarketUtilities.blockchain.networkId,
            contractAddress: PolymarketUtilities.usdcContractAddress,
            decimalCount: usdc.decimalCount
        )

        return TokenItemMapper(supportedBlockchains: userWalletInfo.config.supportedBlockchains)
            .mapToTokenItem(id: id, name: usdc.name, symbol: usdc.currencySymbol, network: network)
    }
}
