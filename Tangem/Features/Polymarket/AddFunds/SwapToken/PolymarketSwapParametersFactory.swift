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

    func make(depositTarget: PolymarketAccountFundsInteractor.DepositTarget) -> PredefinedSwapParameters {
        let receiveToken = PolymarketDepositReceiveTokenFactory(
            userWalletInfo: userWalletInfo,
            accountModel: accountModel,
            depositTarget: depositTarget
        )
        .makeReceiveToken()

        let sourceResolver = PolymarketDepositSourceResolver(
            userWalletInfo: userWalletInfo,
            walletModelsProvider: walletModelsProvider,
            depositCurrency: receiveToken.tokenItem.expressCurrency,
            availabilityChecker: CommonFundingSourceAvailabilityChecker(userWalletInfo: userWalletInfo)
        )

        return .to(
            receiveToken,
            sourceResolver: sourceResolver,
            configuration: SwapFlowConfiguration(
                isPairReversalEnabled: false,
                sourceTokenSelection: .unrestricted,
                receiveTokenSelection: .followsSource(
                    PolymarketDepositDestinationResolver(destination: receiveToken)
                ),
                summaryTitle: Localization.commonAddFunds
            )
        )
    }

    func make(withdrawingFrom source: PolymarketWithdrawSource, receiveToken: SendReceiveToken?) -> PredefinedSwapParameters {
        let sourceToken = PolymarketWithdrawSwapableTokenFactory(userWalletInfo: userWalletInfo, source: source)
            .makeSwapableToken()

        return .from(
            sourceToken,
            pair: .fixed(receiveOrUserSelection: receiveToken),
            configuration: SwapFlowConfiguration(
                isPairReversalEnabled: false,
                sourceTokenSelection: .restricted(
                    walletsProvider: PolymarketWithdrawSourceWalletsProvider(
                        userWalletInfo: userWalletInfo,
                        source: source
                    ),
                    // A markets token can never be the prediction account.
                    allowsMarketsTokens: false
                ),
                receiveTokenSelection: .selectable(
                    .restricted(
                        walletsProvider: FilteredTokenSelectorWalletsProvider(
                            base: .standardAccountsOnly(),
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
