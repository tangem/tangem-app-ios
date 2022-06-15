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

class AppCoordinator: NSObject, ObservableObject {
    //MARK: - Injected
    @Injected(\.walletConnectServiceProvider) private var walletConnectServiceProvider: WalletConnectServiceProviding
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    
    //MARK: - Child coordinators
    @Published var pushedOnboardingCoordinator: OnboardingCoordinator? = nil
    @Published var modalOnboardingCoordinator: OnboardingCoordinator? = nil
    @Published var shopCoordinator: ShopCoordinator? = nil
    @Published var tokenListCoordinator: TokenListCoordinator? = nil
    
    //MARK: - Welcome view models
    @Published var welcomeViewModel: WelcomeViewModel!
    @Published var mailViewModel: MailViewModel? = nil
    @Published var disclaimerViewModel: DisclaimerViewModel? = nil
    @Published var mainViewModel: MainViewModel? = nil
    
    //MARK: - Helpers
    @Published var modalOnboardingCoordinatorKeeper: Bool = false
    //MARK: - Private
    private let servicesManager: ServicesManager = .init()
    private var deferredIntents: [NSUserActivity] = []
    private var deferredIntentWork: DispatchWorkItem?
    private var bag: Set<AnyCancellable> = .init()
    
    func start(with options: UIScene.ConnectionOptions) {
        servicesManager.initialize()
        
        handle(contexts: options.urlContexts)
        handle(activities: options.userActivities)
        
        welcomeViewModel = .init(coordinator: self)
        subscribeToWelcomeLifecycle()
    }
    
    private func popToRoot() {
        pushedOnboardingCoordinator = nil
        modalOnboardingCoordinator = nil
        shopCoordinator = nil
        tokenListCoordinator = nil
        
        welcomeViewModel = nil
        mailViewModel = nil
        disclaimerViewModel = nil
        mainViewModel = nil
    }
    
    private func subscribeToWelcomeLifecycle() {
        let p1 = $mailViewModel.dropFirst().map { $0 == nil ? true : false }
        let p2 = $disclaimerViewModel.dropFirst().map { $0 == nil ? true : false }
        let p3 = $shopCoordinator.dropFirst().map { $0 == nil ? true : false }
        let p4 = $modalOnboardingCoordinator.dropFirst().map { $0 == nil ? true : false }
        
        p1.merge(with: p2, p3, p4)
            .sink {[unowned self] viewDismissed in
                if viewDismissed {
                    self.welcomeViewModel.becomeActive()
                } else {
                    self.welcomeViewModel.resignActve()
                }
            }
            .store(in: &bag)
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

//MARK: - WelcomeViewRoutable
extension AppCoordinator: WelcomeViewRoutable {
    func openInterrupedBackup(with input: OnboardingInput) {
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
        mainViewModel?.state = cardsRepository.lastScanResult // [REDACTED_TODO_COMMENT]
    }
    
    func openMail(with dataCollector: EmailDataCollector) {
        mailViewModel = MailViewModel(dataCollector: dataCollector, support: .tangem, emailType: .failedToScanCard)
    }
    
    func openDisclaimer(acceptCallback: @escaping () -> Void, dismissCallback: @escaping  () -> Void) {
        disclaimerViewModel = DisclaimerViewModel(style: .sheet(acceptCallback: acceptCallback), showAccept: true, dismissCallback: dismissCallback)
    }
    
    func openTokensList() {
        let coordinator = TokenListCoordinator()
        coordinator.start(with: .show)
        self.tokenListCoordinator = coordinator
    }
    
    func openShop() {
        self.shopCoordinator = ShopCoordinator()
    }
}


extension AppCoordinator: MainViewRoutable {
    func close(newScan: Bool) {
        popToRoot()
        
        if newScan {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.welcomeViewModel.scanCard()
            }
        }
    }
}
