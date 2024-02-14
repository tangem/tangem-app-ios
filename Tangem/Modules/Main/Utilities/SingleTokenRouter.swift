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
    func openReceive(walletModel: WalletModel)
    func openBuyCryptoIfPossible(walletModel: WalletModel)
    func openSend(walletModel: WalletModel)
    func openExchange(walletModel: WalletModel)
    func openSell(for walletModel: WalletModel)
    func openSendToSell(with request: SellCryptoRequest, for walletModel: WalletModel)
    func openExplorer(at url: URL, for walletModel: WalletModel)
}

class SingleTokenRouter: SingleTokenRoutable {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.keysManager) private var keysManager: KeysManager

    private let userWalletModel: UserWalletModel
    private weak var coordinator: SingleTokenBaseRoutable?

    init(userWalletModel: UserWalletModel, coordinator: SingleTokenBaseRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
    }

    func openReceive(walletModel: WalletModel) {
        sendAnalyticsEvent(.buttonReceive, for: walletModel)

        let infos = walletModel.wallet.addresses.map { address in
            ReceiveAddressInfo(
                address: address.value,
                type: address.type,
                localizedName: address.localizedName,
                addressQRImage: QrCodeGenerator.generateQRCode(from: address.value)
            )
        }
        coordinator?.openReceiveScreen(
            amountType: walletModel.amountType,
            blockchain: walletModel.blockchainNetwork.blockchain,
            addressInfos: infos
        )
    }

    func openBuyCryptoIfPossible(walletModel: WalletModel) {
        sendAnalyticsEvent(.buttonBuy, for: walletModel)
        if tangemApiService.geoIpRegionCode == LanguageCode.ru {
            coordinator?.openBankWarning { [weak self] in
                self?.openBuy(for: walletModel)
            } declineCallback: { [weak self] in
                self?.coordinator?.openP2PTutorial()
            }
        } else {
            openBuy(for: walletModel)
        }
    }

    func openSend(walletModel: WalletModel) {
        guard
            let amountToSend = walletModel.wallet.amounts[walletModel.amountType],
            // [REDACTED_TODO_COMMENT]
            let cardViewModel = userWalletModel as? CardViewModel
        else { return }

        sendAnalyticsEvent(.buttonSend, for: walletModel)
        coordinator?.openSend(
            amountToSend: amountToSend,
            blockchainNetwork: walletModel.blockchainNetwork,
            cardViewModel: cardViewModel,
            walletModel: walletModel
        )
    }

    func openExchange(walletModel: WalletModel) {
        let input = CommonExpressModulesFactory.InputModel(userWalletModel: userWalletModel, initialWalletModel: walletModel)
        coordinator?.openExpress(input: input)
    }

    func openSell(for walletModel: WalletModel) {
        sendAnalyticsEvent(.buttonSell, for: walletModel)

        let exchangeUtility = buildExchangeCryptoUtility(for: walletModel)
        guard let url = exchangeUtility.sellURL else {
            return
        }

        coordinator?.openSellCrypto(at: url, sellRequestUrl: exchangeUtility.sellCryptoCloseURL) { [weak self] response in
            if let request = exchangeUtility.extractSellCryptoRequest(from: response) {
                self?.openSendToSell(with: request, for: walletModel)
            }
        }
    }

    func openSendToSell(with request: SellCryptoRequest, for walletModel: WalletModel) {
        // [REDACTED_TODO_COMMENT]
        guard let cardViewModel = userWalletModel as? CardViewModel else {
            return
        }

        let blockchainNetwork = walletModel.blockchainNetwork
        let amount = Amount(with: blockchainNetwork.blockchain, value: request.amount)
        coordinator?.openSendToSell(
            amountToSend: amount,
            destination: request.targetAddress,
            blockchainNetwork: blockchainNetwork,
            cardViewModel: cardViewModel,
            walletModel: walletModel
        )
    }

    func openExplorer(at url: URL, for walletModel: WalletModel) {
        sendAnalyticsEvent(.buttonExplore, for: walletModel)
        coordinator?.openExplorer(at: url)
    }

    private func openBuy(for walletModel: WalletModel) {
        let blockchain = walletModel.blockchainNetwork.blockchain
        let exchangeUtility = buildExchangeCryptoUtility(for: walletModel)
        if let token = walletModel.amountType.token, blockchain == .ethereum(testnet: true) {
            TestnetBuyCryptoService().buyCrypto(.erc20Token(
                token,
                walletModel: walletModel,
                signer: userWalletModel.signer
            ))
            return
        }

        guard let url = exchangeUtility.buyURL else { return }

        coordinator?.openBuyCrypto(at: url) { [weak self] in
            self?.sendAnalyticsEvent(.tokenBought, for: walletModel)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                walletModel.update(silent: true)
            }
        }
    }
}

// MARK: - Utilities functions

extension SingleTokenRouter {
    private func sendAnalyticsEvent(_ event: Analytics.Event, for walletModel: WalletModel) {
        Analytics.log(event: event, params: [.token: walletModel.tokenItem.currencySymbol])
    }

    private func buildExchangeCryptoUtility(for walletModel: WalletModel) -> ExchangeCryptoUtility {
        return ExchangeCryptoUtility(
            blockchain: walletModel.blockchainNetwork.blockchain,
            address: walletModel.defaultAddress,
            amountType: walletModel.amountType
        )
    }
}
