//
//  AppCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import BlockchainSdk

class AppCoordinator: NSObject, CoordinatorObject {
    //MARK: - Injected
    @Injected(\.walletConnectServiceProvider) private var walletConnectServiceProvider: WalletConnectServiceProviding
    
    //MARK: - Child coordinators
    @Published var pushedOnboardingCoordinator: OnboardingCoordinator? = nil
    @Published var modalOnboardingCoordinator: OnboardingCoordinator? = nil
    @Published var shopCoordinator: ShopCoordinator? = nil
    @Published var tokenListCoordinator: TokenListCoordinator? = nil
    @Published var sendCoordinator: SendCoordinator? = nil
    @Published var pushTxCoordinator: PushTxCoordinator? = nil
    
    //MARK: - Child view models
    @Published var welcomeViewModel: WelcomeViewModel!
    @Published var mailViewModel: MailViewModel? = nil
    @Published var disclaimerViewModel: DisclaimerViewModel? = nil
    @Published var mainViewModel: MainViewModel? = nil
    @Published var detailsViewModel: DetailsViewModel? = nil
    @Published var modalWebViewModel: WebViewContainerViewModel? = nil
    @Published var pushedWebViewModel: WebViewContainerViewModel? = nil
    @Published var tokenDetailsViewModel: TokenDetailsViewModel? = nil
    @Published var currencySelectViewModel: CurrencySelectViewModel? = nil
    @Published var addressQrBottomSheetContentViewVodel: AddressQrBottomSheetContentViewVodel? = nil
    
    //MARK: - Other view bindings
    @Published var safariURL: URL? = nil
    
    //MARK: - Helpers
    @Published var modalOnboardingCoordinatorKeeper: Bool = false
    @Published var qrBottomSheetKeeper: Bool = false
    
    var dismissAction: () -> Void = {}
    
    //MARK: - Private
    private let servicesManager: ServicesManager = .init()
    private var deferredIntents: [NSUserActivity] = []
    private var deferredIntentWork: DispatchWorkItem?
    private var welcomeLifecycleSubscription: AnyCancellable? = nil
    
    override init() {
        servicesManager.initialize()
    }
    
    func start(with options: UIScene.ConnectionOptions? = nil) {
        welcomeViewModel = .init(coordinator: self)
        subscribeToWelcomeLifecycle()
        
        if let options = options {
            handle(contexts: options.urlContexts)
            handle(activities: options.userActivities)
        }
    }
    
    func hideQrBottomSheet() {
        qrBottomSheetKeeper.toggle()
    }
    
    private func popToRoot() {
        welcomeLifecycleSubscription = nil
        
        pushTxCoordinator = nil
        sendCoordinator = nil
        pushedOnboardingCoordinator = nil
        modalOnboardingCoordinator = nil
        shopCoordinator = nil
        tokenListCoordinator = nil
        
        detailsViewModel = nil
        mailViewModel = nil
        disclaimerViewModel = nil
        mainViewModel = nil
        
        start()
    }
    
    private func subscribeToWelcomeLifecycle() {
        let p1 = $mailViewModel.dropFirst().map { $0 == nil ? true : false }
        let p2 = $disclaimerViewModel.dropFirst().map { $0 == nil ? true : false }
        let p3 = $shopCoordinator.dropFirst().map { $0 == nil ? true : false }
        let p4 = $modalOnboardingCoordinator.dropFirst().map { $0 == nil ? true : false }
        
        welcomeLifecycleSubscription = p1.merge(with: p2, p3, p4)
            .sink {[unowned self] viewDismissed in
                if viewDismissed {
                    self.welcomeViewModel.becomeActive()
                } else {
                    self.welcomeViewModel.resignActve()
                }
            }
    }
}

//MARK: - UIWindowSceneDelegate
extension AppCoordinator: UIWindowSceneDelegate {
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handle(activities: [userActivity])
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        deferredIntentWork = DispatchWorkItem { [weak self] in
            self?.deferredIntents.forEach {
                switch $0.activityType {
                case String(describing: ScanTangemCardIntent.self):
                    //todo: test
                    self?.welcomeViewModel?.scanCard()
                default:
                    break
                }
            }
            self?.deferredIntents.removeAll()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: deferredIntentWork!)
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        deferredIntentWork?.cancel()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handle(contexts: URLContexts)
    }
    
    private func handle(activities: Set<NSUserActivity>) {
        activities.forEach {
            switch $0.activityType {
            case NSUserActivityTypeBrowsingWeb:
                guard let url = $0.webpageURL else { return }
                
                process(url)
            case String(describing: ScanTangemCardIntent.self):
                popToRoot()
                deferredIntents.append($0)
            default: return
            }
        }
    }
    
    private func handle(contexts: Set<UIOpenURLContext>) {
        if let url = contexts.first?.url {
            process(url)
        }
    }
    
    private func process(_ url: URL) {
        handle(url: url)
        walletConnectServiceProvider.service.handle(url: url)
    }
}

//MARK: - URLHandler
extension AppCoordinator: URLHandler {
    @discardableResult func handle(url: String) -> Bool {
        guard url.starts(with: "https://app.tangem.com")
                || url.starts(with: Constants.tangemDomain + "/ndef")
                || url.starts(with: Constants.tangemDomain + "/wc") else { return false }
        
        popToRoot()
        return true
    }
    
    @discardableResult func handle(url: URL) -> Bool {
        handle(url: url.absoluteString)
    }
}

//MARK: - WelcomeRoutable
extension AppCoordinator: WelcomeRoutable {
    func openOnboardingModal(with input: OnboardingInput) {
        var input = input
        input.successCallback = { [weak self] in
            self?.modalOnboardingCoordinator = nil
        }
        
        let coordinator = OnboardingCoordinator()
        coordinator.start(with: input)
        modalOnboardingCoordinator = coordinator
    }
    
    func openOnboarding(with input: OnboardingInput) {
        var input = input
        input.successCallback = { [weak self] in
            self?.openMain()
        }
        
        let coordinator = OnboardingCoordinator()
        coordinator.start(with: input)
        pushedOnboardingCoordinator = coordinator
    }
    
    func openMain() {
        mainViewModel = MainViewModel(coordinator: self)
        mainViewModel?.updateState() // [REDACTED_TODO_COMMENT]
    }
    
    func openMail(with dataCollector: EmailDataCollector) {
        mailViewModel = MailViewModel(dataCollector: dataCollector, support: .tangem, emailType: .failedToScanCard)
    }
    
    func openDisclaimer(acceptCallback: @escaping () -> Void, dismissCallback: @escaping  () -> Void) {
        disclaimerViewModel = DisclaimerViewModel(style: .sheet(acceptCallback: acceptCallback), showAccept: true, dismissCallback: dismissCallback)
    }
    
    func openTokensList() {
        let coordinator = TokenListCoordinator()
        coordinator.dismissAction = { [weak self] in self?.tokenListCoordinator = nil }
        coordinator.start(with: .show)
        self.tokenListCoordinator = coordinator
    }
    
    func openShop() {
        let coordinator = ShopCoordinator()
        coordinator.start()
        self.shopCoordinator = coordinator
    }
}


extension AppCoordinator: MainRoutable {
    func close(newScan: Bool) {
        popToRoot()
        
        if newScan {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.welcomeViewModel.scanCard()
            }
        }
    }
    
    func openSettings(cardModel: CardViewModel) {
        detailsViewModel = DetailsViewModel(cardModel: cardModel, coordinator: self)
    }
    
    func openTokenDetails(cardModel: CardViewModel, blockchainNetwork: BlockchainNetwork, amountType: Amount.AmountType) {
        tokenDetailsViewModel = TokenDetailsViewModel(cardModel: cardModel,
                                                      blockchainNetwork: blockchainNetwork,
                                                      amountType: amountType,
                                                      coordinator: self)
    }
    
    func openCurrencySelection() {
        currencySelectViewModel = CurrencySelectViewModel()
    }
    
    func openExternalURL(_ url: URL) {
        safariURL = url
    }
    
    func openTokensList(with cardModel: CardViewModel) {
        let coordinator = TokenListCoordinator()
        coordinator.dismissAction = { [weak self] in self?.tokenListCoordinator = nil }
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

extension AppCoordinator: DetailsRoutable {
}

extension AppCoordinator: TokenDetailsRoutable {
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
        coordinator.start(amountToSend: amountToSend, blockchainNetwork: blockchainNetwork, cardViewModel: cardViewModel)
        self.sendCoordinator = coordinator
    }
    
    func openSendToSell(amountToSend: Amount, destination: String, blockchainNetwork: BlockchainNetwork, cardViewModel: CardViewModel) {
        let coordinator = SendCoordinator()
        coordinator.start(amountToSend: amountToSend, destination: destination, blockchainNetwork: blockchainNetwork, cardViewModel: cardViewModel)
        self.sendCoordinator = coordinator
    }
    
    func openPushTx(for tx: BlockchainSdk.Transaction, blockchainNetwork: BlockchainNetwork, card: CardViewModel) {
        let coordinator = PushTxCoordinator()
        coordinator.start(for: tx, blockchainNetwork: blockchainNetwork, card: card)
        self.pushTxCoordinator = coordinator
    }
}
