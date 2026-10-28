//
//  PolymarketWithdrawSwapPredefinedParametersBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPolymarket

struct PolymarketWithdrawSwapPredefinedParametersBuilder: SwapPredefinedParametersBuilder {
    let userWalletInfo: UserWalletInfo
    let source: PolymarketWithdrawSource
    let receiveToken: SendReceiveToken?

    func make() -> PredefinedSwapParameters {
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

// MARK: - Private

private extension PolymarketWithdrawSwapPredefinedParametersBuilder {
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
