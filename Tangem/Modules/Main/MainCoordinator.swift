//
//  MainCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class MainCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>
    
    //MARK: - Main view model
    @Published private(set) var mainViewModel: MainViewModel? = nil
    
    //MARK: - Child coordinators
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var pushTxCoordinator: PushTxCoordinator? = nil
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator? = nil
    @Published var detailsCoordinator: DetailsCoordinator? = nil
    @Published var tokenListCoordinator: TokenListCoordinator? = nil
    @Published var modalOnboardingCoordinator: OnboardingCoordinator? = nil
    
    //MARK: - Child view models
    @Published var pushedWebViewModel: WebViewContainerViewModel? = nil
    @Published var modalWebViewModel: WebViewContainerViewModel? = nil
    @Published var currencySelectViewModel: CurrencySelectViewModel? = nil
    @Published var mailViewModel: MailViewModel? = nil
    @Published var addressQrBottomSheetContentViewVodel: AddressQrBottomSheetContentViewVodel? = nil
    
    //MARK: - Other view bindings
    @Published var safariURL: URL? = nil
    
    //MARK: - Helpers
    @Published var qrBottomSheetKeeper: Bool = false
    @Published var modalOnboardingCoordinatorKeeper: Bool = false
    
    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }
    
    func start(with options: MainCoordinator.Options) {
        mainViewModel = MainViewModel(cardModel: options.cardModel, coordinator: self)
    }
    
    func hideQrBottomSheet() {
        qrBottomSheetKeeper.toggle()
    }
}

extension MainCoordinator {
    struct Options {
        let cardModel: CardViewModel
    }
}

extension MainCoordinator: MainRoutable {
    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action = { [weak self] in
            self?.modalOnboardingCoordinator = nil
        }
        
        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        let options = OnboardingCoordinator.Options(input: input)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }
    
    func openBuyCrypto(at url: URL, closeUrl: String, action: @escaping (String) -> Void) {
        pushedWebViewModel = WebViewContainerViewModel(url: url,
                                                       title: "wallet_button_topup".localized,
                                                       addLoadingIndicator: true,
                                                       urlActions: [
                                                        closeUrl: {[weak self] response in
                                                            self?.pushedWebViewModel = nil
                                                            action(response)
                                                        }])
    }
    
    func openSellCrypto(at url: URL, sellRequestUrl: String, action: @escaping (String) -> Void) {
        pushedWebViewModel = WebViewContainerViewModel(url: url,
                                                       title: "wallet_button_sell_crypto".localized,
                                                       addLoadingIndicator: true,
                                                       urlActions: [sellRequestUrl: action])
    }
    
    func openExplorer(at url: URL, blockchainDisplayName: String) {
        modalWebViewModel = WebViewContainerViewModel(url: url,
                                                      title: "common_explorer_format".localized(blockchainDisplayName),
                                                      withCloseButton: true)
    }
    
    func openSend(amountToSend: Amount, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel) {
        let coordinator = SendCoordinator()
        let options = SendCoordinator.Options(amountToSend: amountToSend,
                                              destination: nil,
                                              blockchainNetwork: blockchainNetwork,
                                              cardViewModel: cardViewModel)
        coordinator.start(with: options)
        self.sendCoordinator = coordinator
    }
    
    func openSendToSell(amountToSend: Amount, destination: String, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel) {
        let coordinator = SendCoordinator()
        let options = SendCoordinator.Options(amountToSend: amountToSend,
                                              destination: destination,
                                              blockchainNetwork: blockchainNetwork,
                                              cardViewModel: cardViewModel)
        coordinator.start(with: options)
        self.sendCoordinator = coordinator
    }
    
    func openPushTx(for tx: BlockchainSdk.Transaction, blockchainNetwork: BlockchainNetwork, card: CardViewModel) {
        let coordinator = PushTxCoordinator()
        let options = PushTxCoordinator.Options(tx: tx,
                                                blockchainNetwork: blockchainNetwork,
                                                cardModel: card)
        coordinator.start(with: options)
        self.pushTxCoordinator = coordinator
    }
    
    func close(newScan: Bool) {
        self.popToRoot(with: .init(newScan: newScan))
    }
    
    func openSettings(cardModel: CardViewModel) {
        let coordinator = DetailsCoordinator(popToRootAction: self.popToRootAction)
        let options = DetailsCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        coordinator.popToRootAction = self.popToRootAction
        detailsCoordinator = coordinator
    }
    
    func openTokenDetails(cardModel: CardViewModel, blockchainNetwork: BlockchainNetwork, amountType: Amount.AmountType) {
        let coordinator = TokenDetailsCoordinator()
        let options = TokenDetailsCoordinator.Options(cardModel: cardModel,
                                                      blockchainNetwork: blockchainNetwork,
                                                      amountType: amountType)
        coordinator.start(with: options)
        tokenDetailsCoordinator = coordinator
    }
    
    func openCurrencySelection(autoDismiss: Bool) {
        currencySelectViewModel = CurrencySelectViewModel()
        currencySelectViewModel?.dismissAfterSelection = autoDismiss
    }
    
    func openExternalURL(_ url: URL) {
        safariURL = url
    }
    
    func openTokensList(with cardModel: CardViewModel) {
        let dismissAction: Action = { [weak self] in
            self?.tokenListCoordinator = nil
        }
        
        let coordinator = TokenListCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .add(cardModel: cardModel))
        self.tokenListCoordinator = coordinator
    }
    
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType) {
        mailViewModel = MailViewModel(dataCollector: dataCollector, support: .tangem, emailType: emailType)
    }
    
    func openQR(shareAddress: String, address: String, qrNotice: String) {
        addressQrBottomSheetContentViewVodel = .init(shareAddress: shareAddress, address: address, qrNotice: qrNotice)
    }
}
