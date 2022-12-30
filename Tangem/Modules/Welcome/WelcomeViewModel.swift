//
//  WelcomeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSdk

class WelcomeViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable

    @Published var showTroubleshootingView: Bool = false
    @Published var isScanningCard: Bool = false
    @Published var error: AlertBinder?
    @Published var storiesModel: StoriesViewModel = .init()

    // This screen seats on the navigation stack permanently. We should preserve the navigationBar state to fix the random hide/disappear events of navigationBar on iOS13 on other screens down the navigation hierarchy.
    @Published var navigationBarHidden: Bool = false

    private var storiesModelSubscription: AnyCancellable? = nil
    private var shouldScanOnAppear: Bool = false

    private unowned let coordinator: WelcomeRoutable

    init(shouldScanOnAppear: Bool, coordinator: WelcomeRoutable) {
        self.shouldScanOnAppear = shouldScanOnAppear
        self.coordinator = coordinator
        userWalletRepository.delegate = self
        self.storiesModelSubscription = storiesModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.objectWillChange.send()
            })
    }

    func scanCard() {
        isScanningCard = true
        Analytics.log(.buttonScanCard)

        userWalletRepository.unlock(with: .card(userWallet: nil)) { [weak self] result in
            self?.isScanningCard = false

            guard
                let self,
                let result
            else {
                return
            }

            switch result {
            case .troubleshooting:
                self.showTroubleshootingView = true
            case .onboarding(let input):
                self.openOnboarding(with: input)
            case .error(let error):
                self.error = error.alertBinder
            case .success(let cardModel):
                self.openMain(with: cardModel)
            }
        }
    }

    func tryAgain() {
        scanCard()
    }

    func requestSupport() {
        Analytics.log(.buttonRequestSupport)
        failedCardScanTracker.resetCounter()
        openMail()
    }

    func orderCard() {
        // For some reason the button can be tapped even after we've this flag to FALSE to disable it
        guard !isScanningCard else { return }

        openShop()
        Analytics.log(.getACard, params: [.source: Analytics.ParameterValue.welcome.rawValue])
        Analytics.log(.buttonBuyCards)
    }

    func onAppear() {
        navigationBarHidden = true
        Analytics.log(.introductionProcessOpened)
    }

    func onDidAppear() {
        if shouldScanOnAppear {
            DispatchQueue.main.async {
                self.scanCard()
            }
        }
    }

    func onDisappear() {
        navigationBarHidden = false
    }
}

// MARK: - Navigation
extension WelcomeViewModel {
    func openMail() {
        coordinator.openMail(with: failedCardScanTracker, recipient: EmailConfig.default.recipient)
    }

    func openTokensList() {
        // For some reason the button can be tapped even after we've this flag to FALSE to disable it
        guard !isScanningCard else { return }

        Analytics.log(.buttonTokensList)
        coordinator.openTokensList()
    }

    func openShop() {
        coordinator.openShop()
    }

    func openOnboarding(with input: OnboardingInput) {
        coordinator.openOnboarding(with: input)
    }

    func openMain(with cardModel: CardViewModel) {
        coordinator.openMain(with: cardModel)
    }
}

extension WelcomeViewModel: UserWalletRepositoryDelegate {
    func showTOS(at url: URL, _ completion: @escaping (Bool) -> Void) {
        coordinator.openDisclaimer(at: url, completion)
    }
}

extension WelcomeViewModel: WelcomeViewLifecycleListener {
    func resignActve() {
        storiesModel.resignActve()
    }

    func becomeActive() {
        storiesModel.becomeActive()
    }
}
