//
//  SingleTokenNavigationRouter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemExpress

protocol SingleTokenRoutable {
    func openReceive(walletModel: any WalletModel)
    func openSend(walletModel: any WalletModel)
    func openExchange(walletModel: any WalletModel)
    func openStaking(walletModel: any WalletModel)
    func openSell(for walletModel: any WalletModel)
    func openSendToSell(with request: SellCryptoRequest, for walletModel: any WalletModel)
    func openExplorer(at url: URL, for walletModel: any WalletModel)
    func openMarketsTokenDetails(for tokenItem: TokenItem)
    func openInSafari(url: URL)
    func openOnramp(walletModel: any WalletModel)
    func openPendingExpressTransactionDetails(
        pendingTransaction: PendingTransaction,
        tokenItem: TokenItem,
        pendingTransactionsManager: PendingExpressTransactionsManager
    )
}

final class SingleTokenRouter: SingleTokenRoutable {
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    private let userWalletModel: UserWalletModel
    private weak var coordinator: SingleTokenBaseRoutable?

    init(userWalletModel: UserWalletModel, coordinator: SingleTokenBaseRoutable?) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
    }

    func openReceive(walletModel: any WalletModel) {
        coordinator?.openReceiveScreen(walletModel: walletModel)
    }

    func openOnramp(walletModel: any WalletModel) {
        coordinator?.openOnramp(userWalletModel: userWalletModel, walletModel: walletModel, parameters: .none)
    }

    func openSend(walletModel: any WalletModel) {
        coordinator?.openSend(userWalletModel: userWalletModel, walletModel: walletModel)
    }

    func openExchange(walletModel: any WalletModel) {
        let input = CommonExpressModulesFactory.InputModel(userWalletModel: userWalletModel, initialWalletModel: walletModel)
        coordinator?.openExpress(input: input)
    }

    func openStaking(walletModel: any WalletModel) {
        sendAnalyticsEvent(.stakingClicked, for: walletModel)
        guard let stakingManager = walletModel.stakingManager else {
            return
        }

        coordinator?.openStaking(
            options: .init(
                userWalletModel: userWalletModel,
                walletModel: walletModel,
                manager: stakingManager
            )
        )
    }

    func openSell(for walletModel: any WalletModel) {
        let sellUtility = buildSellCryptoUtility(for: walletModel)
        guard let url = sellUtility.sellURL else {
            return
        }

        coordinator?.openSellCrypto(at: url) { [weak self] response in
            if let request = sellUtility.extractSellCryptoRequest(from: response) {
                self?.openSendToSell(with: request, for: walletModel)
            }
        }
    }

    func openSendToSell(with request: SellCryptoRequest, for walletModel: any WalletModel) {
        coordinator?.openSendToSell(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            sellParameters: .init(amount: request.amount, destination: request.targetAddress, tag: request.tag)
        )
    }

    func openExplorer(at url: URL, for walletModel: any WalletModel) {
        sendAnalyticsEvent(.buttonExplore, for: walletModel)
        coordinator?.openInSafari(url: url)
    }

    func openMarketsTokenDetails(for tokenItem: TokenItem) {
        guard let tokenId = getTokenItemId(for: tokenItem) else {
            return
        }

        let quoteData = quotesRepository.quote(for: tokenId)
        let model = MarketsTokenModel(
            id: tokenId,
            name: tokenItem.name,
            symbol: tokenItem.currencySymbol,
            currentPrice: quoteData?.price,
            priceChangePercentage: MarketsTokenQuoteHelper().makePriceChangeIntervalsDictionary(from: quoteData) ?? [:],
            marketRating: nil,
            marketCap: nil,
            isUnderMarketCapLimit: nil,
            stakingOpportunities: nil
        )

        coordinator?.openMarketsTokenDetails(tokenModel: model)
    }

    func openInSafari(url: URL) {
        coordinator?.openInSafari(url: url)
    }

    func openPendingExpressTransactionDetails(pendingTransaction: PendingTransaction, tokenItem: TokenItem, pendingTransactionsManager: any PendingExpressTransactionsManager) {
        coordinator?.openPendingExpressTransactionDetails(
            pendingTransaction: pendingTransaction,
            tokenItem: tokenItem,
            userWalletModel: userWalletModel,
            pendingTransactionsManager: pendingTransactionsManager
        )
    }

    private func getTokenItemId(for tokenItem: TokenItem) -> TokenItemId? {
        guard tokenItem.isBlockchain, tokenItem.blockchain.isL2EthereumNetwork else {
            return tokenItem.id
        }

        return Blockchain.ethereum(testnet: false).coinId
    }
}

// MARK: - Utilities functions

extension SingleTokenRouter {
    private func sendAnalyticsEvent(_ event: Analytics.Event, for walletModel: any WalletModel) {
        Analytics.log(event: event, params: [.token: walletModel.tokenItem.currencySymbol])
    }

    private func buildSellCryptoUtility(for walletModel: any WalletModel) -> SellCryptoUtility {
        SellCryptoUtility(
            blockchain: walletModel.tokenItem.blockchain,
            address: walletModel.defaultAddressString,
            amountType: walletModel.tokenItem.amountType
        )
    }
}
