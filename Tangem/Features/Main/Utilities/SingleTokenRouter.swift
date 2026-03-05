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
    func openYieldModule(walletModel: any WalletModel)
}

final class SingleTokenRouter: SingleTokenRoutable {
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    private let userWalletInfo: UserWalletInfo
    private weak var coordinator: SingleTokenBaseRoutable?
    private let yieldModuleNoticeInteractor: YieldModuleNoticeInteractor

    init(
        userWalletInfo: UserWalletInfo,
        coordinator: SingleTokenBaseRoutable?,
        yieldModuleNoticeInteractor: YieldModuleNoticeInteractor
    ) {
        self.userWalletInfo = userWalletInfo
        self.coordinator = coordinator
        self.yieldModuleNoticeInteractor = yieldModuleNoticeInteractor
    }

    func openReceive(walletModel: any WalletModel) {
        coordinator?.openReceiveScreen(walletModel: walletModel)
    }

    func openOnramp(walletModel: any WalletModel) {
        let input = makeSendInput(for: walletModel)
        let parameters = PredefinedOnrampParametersBuilder.makeMoonpayPromotionParametersIfActive()
        coordinator?.openOnramp(input: input, parameters: parameters)
    }

    func openSend(walletModel: any WalletModel) {
        let input = makeSendInput(for: walletModel)

        let openSendAction = { [weak self] in
            self?.coordinator?.openSend(input: input)
        }

        if yieldModuleNoticeInteractor.shouldShowYieldModuleAlert(for: walletModel.tokenItem) {
            openViaYieldNotice(tokenItem: walletModel.tokenItem, action: { openSendAction() })
        } else {
            openSendAction()
        }
    }

    func openExchange(walletModel: any WalletModel) {
        let input = ExpressDependenciesInput(
            userWalletInfo: userWalletInfo,
            source: ExpressInteractorWalletModelWrapper(
                userWalletInfo: userWalletInfo,
                walletModel: walletModel,
                expressOperationType: .swap
            ),
            destination: .loadingAndSet
        )

        if yieldModuleNoticeInteractor.shouldShowYieldModuleAlert(for: walletModel.tokenItem) {
            openViaYieldNotice(tokenItem: walletModel.tokenItem) { [weak self] in
                self?.coordinator?.openExpress(input: input)
            }
        } else {
            coordinator?.openExpress(input: input)
        }
    }

    func openStaking(walletModel: any WalletModel) {
        sendAnalyticsEvent(.stakingClicked, for: walletModel)
        guard let stakingManager = walletModel.stakingManager else {
            return
        }

        let input = makeSendInput(for: walletModel)
        coordinator?.openStaking(options: .init(sendInput: input, manager: stakingManager))
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
        let input = makeSendInput(for: walletModel)

        coordinator?.openSendToSell(
            input: input,
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
            maxYieldApy: nil,
            marketCap: nil,
            isUnderMarketCapLimit: nil,
            stakingOpportunities: nil,
            networks: nil,
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
            userWalletInfo: userWalletInfo,
            pendingTransactionsManager: pendingTransactionsManager
        )
    }

    func openYieldModule(walletModel: any WalletModel) {}

    private func getTokenItemId(for tokenItem: TokenItem) -> TokenItemId? {
        guard tokenItem.isBlockchain, tokenItem.blockchain.isL2EthereumNetwork else {
            return tokenItem.id
        }

        return Blockchain.ethereum(testnet: false).coinId
    }

    private func openViaYieldNotice(tokenItem: TokenItem, action: @escaping () -> Void) {
        let viewModel = YieldNoticeViewModel(tokenItem: tokenItem, action: action)
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - Private utilities functions

private extension SingleTokenRouter {
    func sendAnalyticsEvent(_ event: Analytics.Event, for walletModel: any WalletModel) {
        Analytics.log(event: event, params: [.token: walletModel.tokenItem.currencySymbol])
    }

    func buildSellCryptoUtility(for walletModel: any WalletModel) -> SellCryptoUtility {
        SellCryptoUtility(
            blockchain: walletModel.tokenItem.blockchain,
            address: walletModel.defaultAddressString,
            amountType: walletModel.tokenItem.amountType
        )
    }

    func makeSendInput(for walletModel: any WalletModel) -> SendInput {
        SendInput(userWalletInfo: userWalletInfo, walletModel: walletModel)
    }
}
