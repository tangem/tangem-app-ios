//
//  AppCoordinator+WelcomeRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

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
        if input.successCallback == nil {
            var input = input
            input.successCallback = { [weak self] in
                self?.pushedOnboardingCoordinator = nil
            }
        }
        
        let coordinator = OnboardingCoordinator()
        coordinator.start(with: input)
        pushedOnboardingCoordinator = coordinator
    }
    
    func openMain(with cardModel: CardViewModel) {
        mainViewModel = MainViewModel(cardModel: cardModel, coordinator: self)
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


