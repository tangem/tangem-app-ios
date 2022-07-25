//
//  TokenDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//
import SwiftUI
import BlockchainSdk
import Combine

class TokenDetailsViewModel: ObservableObject {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var alert: AlertBinder? = nil
    @Published var showTradeSheet: Bool = false
    @Published var isRefreshing: Bool = false

    let card: CardViewModel

    var wallet: Wallet? {
        return walletModel?.wallet
    }

    var walletModel: WalletModel? {
        return card.walletModels?.first(where: { $0.blockchainNetwork == blockchainNetwork })
    }

    var incomingTransactions: [PendingTransaction] {
        walletModel?.incomingPendingTransactions.filter { $0.amountType == amountType } ?? []
    }

    var outgoingTransactions: [PendingTransaction] {
        walletModel?.outgoingPendingTransactions.filter { $0.amountType == amountType } ?? []
    }

    var canBuyCrypto: Bool {
        card.canExchangeCrypto && buyCryptoUrl != nil
    }

    var canSellCrypto: Bool {
        card.canExchangeCrypto && sellCryptoUrl != nil
    }

    var buyCryptoUrl: URL? {
        if let wallet = wallet {

            if blockchainNetwork.blockchain.isTestnet {
                return blockchainNetwork.blockchain.testnetFaucetURL
            }

            let address = wallet.address
            switch amountType {
            case .coin:
                return exchangeService.getBuyUrl(currencySymbol: blockchainNetwork.blockchain.currencySymbol, amountType: amountType, blockchain: blockchainNetwork.blockchain, walletAddress: address)
            case .token(let token):
                return exchangeService.getBuyUrl(currencySymbol: token.symbol, amountType: amountType, blockchain: blockchainNetwork.blockchain, walletAddress: address)
            case .reserve:
                break
            }
        }
        return nil
    }

    var buyCryptoCloseUrl: String {
        exchangeService.successCloseUrl.removeLatestSlash()
    }

    var sellCryptoRequestUrl: String {
        exchangeService.sellRequestUrl.removeLatestSlash()
    }

    var sellCryptoUrl: URL? {
        if let wallet = wallet {

            let address = wallet.address
            switch amountType {
            case .coin:
                return exchangeService.getSellUrl(currencySymbol: blockchainNetwork.blockchain.currencySymbol, amountType: amountType, blockchain: blockchainNetwork.blockchain, walletAddress: address)
            case .token(let token):
                return exchangeService.getSellUrl(currencySymbol: token.symbol, amountType: amountType, blockchain: blockchainNetwork.blockchain, walletAddress: address)
            case .reserve:
                break
            }
        }

        return nil
    }

    var canSend: Bool {
        guard card.canSign else {
            return false
        }

        return wallet?.canSend(amountType: self.amountType) ?? false
    }

    var sendBlockedReason: String? {
        guard let wallet = walletModel?.wallet,
              let currentAmount = wallet.amounts[amountType], amountType.isToken else { return nil }

        if wallet.hasPendingTx && !wallet.hasPendingTx(for: amountType) { // has pending tx for fee
            return String(format: "token_details_send_blocked_tx_format".localized, wallet.amounts[.coin]?.currencySymbol ?? "")
        }

        if !wallet.hasPendingTx && !canSend && !currentAmount.isZero { // no fee
            return String(format: "token_details_send_blocked_fee_format".localized, wallet.blockchain.displayName, wallet.blockchain.displayName)
        }

        return nil
    }

    var title: String {
        if let token = amountType.token {
            return token.name
        } else {
            return wallet?.blockchain.displayName ?? ""
        }
    }

    var tokenSubtitle: String? {
        if amountType.token == nil {
            return nil
        }

        return "wallet_currency_subtitle".localized(blockchainNetwork.blockchain.displayName)
    }

    @Published var solanaRentWarning: String? = nil
    @Published var showExplorerURL: URL? = nil

    let amountType: Amount.AmountType
    let blockchainNetwork: BlockchainNetwork

    private let dismissalRequestSubject = PassthroughSubject<Void, Never>()
    private var bag = Set<AnyCancellable>()
    private var rentWarningSubscription: AnyCancellable?
    private var refreshCancellable: AnyCancellable? = nil
    private lazy var testnetBuyCryptoService: TestnetBuyCryptoService = .init()
    private unowned let coordinator: TokenDetailsRoutable

    private var currencySymbol: String {
        amountType.token?.symbol ?? blockchainNetwork.blockchain.currencySymbol
    }

    init(cardModel: CardViewModel, blockchainNetwork: BlockchainNetwork, amountType: Amount.AmountType, coordinator: TokenDetailsRoutable) {
        self.card = cardModel
        self.blockchainNetwork = blockchainNetwork
        self.amountType = amountType
        self.coordinator = coordinator

        bind()
    }

    func onAppear() {
        rentWarningSubscription = walletModel?
            .$state
            .filter { !$0.isLoading }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateRentWarning()
            }
    }

    func onRemove() {
        guard let walletModel = walletModel else {
            assertionFailure("walletModel isn't found")
            return
        }

        if walletModel.canRemove(amountType: amountType) {
            showWarningDeleteAlert()
        } else {
            showUnableToHideAlert()
        }
    }

    func tradeCryptoAction() {
        showTradeSheet = true
    }

    func processSellCryptoRequest(_ request: String) {
        if let request = exchangeService.extractSellCryptoRequest(from: request) {
            openSendToSell(with: request)
        }
    }

    func sendAnalyticsEvent(_ event: Analytics.Event) {
        switch event {
        case .userBoughtCrypto:
            Analytics.log(event: event, with: [.currencyCode: blockchainNetwork.blockchain.currencySymbol])
        default:
            break
        }
    }

    private func bind() {
        print("🔗 Token Details view model updates binding")
        card.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)

        walletModel?.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)

        $showExplorerURL
            .compactMap { $0 }
            .sink { [unowned self] url in
                self.openExplorer(at: url)
                self.showExplorerURL = nil
            }
            .store(in: &bag)

        dismissalRequestSubject
            .sink { [unowned self] _ in
                self.dismiss()
            }
            .store(in: &bag)
    }

    func onRefresh(_ done: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.isRefreshing = true
        }
        refreshCancellable = walletModel?
            .update(silent: true)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("♻️ Token wallet model loading state changed")
                withAnimation(.default.delay(0.2)) {
                    self.isRefreshing = false
                    done()
                }
            } receiveValue: { _ in

            }
    }

    private func updateRentWarning() {
        guard let rentProvider = walletModel?.walletManager as? RentProvider else {
            return
        }

        rentProvider.rentAmount()
            .zip(rentProvider.minimalBalanceForRentExemption())
            .receive(on: RunLoop.main)
            .sink { _ in

            } receiveValue: { [weak self] (rentAmount, minimalBalanceForRentExemption) in
                guard
                    let self = self,
                    let amount = self.walletModel?.wallet.amounts[.coin],
                    amount < minimalBalanceForRentExemption
                else {
                    self?.solanaRentWarning = nil
                    return
                }
                self.solanaRentWarning = String(format: "solana_rent_warning".localized, rentAmount.description, minimalBalanceForRentExemption.description)
            }
            .store(in: &bag)
    }

    private func deleteToken() {
        guard let walletModel = walletModel else {
            assertionFailure("WalletModel didn't found")
            return
        }

        dismissalRequestSubject.send(())

        /// Added the delay to display the deletion in the main screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.card.remove(
                amountType: self.amountType,
                blockchainNetwork: walletModel.blockchainNetwork
            )
        }
    }

    private func showUnableToHideAlert() {
        let title = "token_details_unable_hide_alert_title".localized(currencySymbol)

        let message = "token_details_unable_hide_alert_message".localized([
            currencySymbol,
            walletModel?.blockchainNetwork.blockchain.displayName ?? "",
        ])

        alert = AlertBinder(alert: Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(Text("common_ok"))
        ))
    }

    private func showWarningDeleteAlert() {
        let title = "token_details_hide_alert_title".localized(currencySymbol)

        alert = warningAlert(
            title: title,
            message: "token_details_hide_alert_message".localized,
            primaryButton: .destructive(Text("token_details_hide_alert_hide")) { [weak self] in
                self?.deleteToken()
            }
        )
    }

    private func warningAlert(title: String, message: String, primaryButton: Alert.Button) -> AlertBinder {
        let alert = Alert(
            title: Text(title),
            message: Text(message.localized),
            primaryButton: primaryButton,
            secondaryButton: Alert.Button.cancel()
        )

        return AlertBinder(alert: alert)
    }
}

extension Int: Identifiable {
    public var id: Int { self }
}

// MARK: - Navigation
extension TokenDetailsViewModel {
    func openSend() {
        guard let amountToSend = self.wallet?.amounts[amountType] else { return }

        coordinator.openSend(amountToSend: amountToSend, blockchainNetwork: blockchainNetwork, cardViewModel: card)
    }

    func openSendToSell(with request: SellCryptoRequest) {
        let amount = Amount(with: blockchainNetwork.blockchain, value: request.amount)
        coordinator.openSendToSell(amountToSend: amount,
                                   destination: request.targetAddress,
                                   blockchainNetwork: blockchainNetwork,
                                   cardViewModel: card)
    }

    func openSellCrypto() {
        if card.cardInfo.card.isDemoCard {
            alert = AlertBuilder.makeDemoAlert()
            return
        }

        if let url = sellCryptoUrl {
            coordinator.openSellCrypto(at: url, sellRequestUrl: sellCryptoRequestUrl) { [weak self] response in
                self?.processSellCryptoRequest(response)
            }
        }
    }

    func openBuyCrypto() {
        if card.cardInfo.card.isDemoCard {
            alert = AlertBuilder.makeDemoAlert()
            return
        }

        guard card.isTestnet, let token = amountType.token,
              case .ethereum(testnet: true) = blockchainNetwork.blockchain else {
            if let url = buyCryptoUrl {
                coordinator.openBuyCrypto(at: url, closeUrl: buyCryptoCloseUrl) { [weak self] _ in
                    self?.sendAnalyticsEvent(.userBoughtCrypto)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self?.walletModel?.update(silent: true)
                    }
                }
            }
            return
        }

        guard let model = walletModel else { return }


        testnetBuyCryptoService.buyCrypto(.erc20Token(token, walletManager: model.walletManager, signer: card.signer))
    }

    func openBuyCryptoIfPossible() {
        if tangemApiService.geoIpRegionCode == "ru" {
            coordinator.openBankWarning {
                self.openBuyCrypto()
            } declineCallback: {
                self.coordinator.openP2PTutorial()
            }
        } else {
            openBuyCrypto()
        }
    }

    func openPushTx(for index: Int) {
        guard let tx =  wallet?.pendingOutgoingTransactions[index] else { return }

        coordinator.openPushTx(for: tx, blockchainNetwork: blockchainNetwork, card: card)
    }

    func openExplorer(at url: URL) {
        coordinator.openExplorer(at: url, blockchainDisplayName: blockchainNetwork.blockchain.displayName)
    }

    func dismiss() {
        coordinator.dismiss()
    }
}
