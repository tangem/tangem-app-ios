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
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    @Published private var decimalValue: DecimalNumberTextField.DecimalValue? = nil
    @Published var toggle: Bool = false
    var sendAmountContainerViewModel: SendAmountContainerViewModel!

    @Published var showTroubleshootingView: Bool = false
    @Published var isScanningCard: Bool = false
    @Published var error: AlertBinder?
    @Published var storiesModel: StoriesViewModel = .init()

    private var storiesModelSubscription: AnyCancellable?
    private var shouldScanOnAppear: Bool = false

    private unowned let coordinator: WelcomeRoutable

    var bag: Set<AnyCancellable> = []

    var alter = CurrentValueSubject<String, Never>("0,00")
    var c = CurrentValueSubject<Error?, Never>(nil)

    init(shouldScanOnAppear: Bool, coordinator: WelcomeRoutable) {
        self.shouldScanOnAppear = shouldScanOnAppear
        self.coordinator = coordinator

        sendAmountContainerViewModel = .init(
            walletName: "Family Wallet",
            balance: "2 130,88 USDT (2 129,92 $)",
            tokenIconName: "tether",
            tokenIconURL: TokenIconURLBuilder().iconURL(id: "tether"),
            tokenIconCustomTokenColor: nil,
            tokenIconBlockchainIconName: "ethereum.fill",
            isCustomToken: false,
            amountFractionDigits: 2,
            amountAlternativePublisher: alter.eraseToAnyPublisher(),
            decimalValue: .init(get: {
                self.decimalValue
            }, set: { newValue in
                self.decimalValue = newValue

                let v = newValue?.value ?? 0
                let alternative = "\(v * 10) $"
                self.alter.send(alternative)

                if let newValue, newValue.value > 1000 {
                    self.c.send("Error!")
                } else {
                    self.c.send(nil)
                }
            }),
            errorPublisher: c.eraseToAnyPublisher() // .just(output: nil)
        )

        storiesModelSubscription = storiesModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.objectWillChange.send()
            })

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.decimalValue = .external(3)
        }

        $decimalValue
            .sink { v in
                print(v)
            }
            .store(in: &bag)
    }

    func scanCardTapped() {
        scanCard()
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
        Analytics.log(.buttonBuyCards)
    }

    func onAppear() {
        Analytics.log(.introductionProcessOpened)
        incomingActionManager.becomeFirstResponder(self)
    }

    func onDidAppear() {
        if shouldScanOnAppear {
            DispatchQueue.main.async {
                self.scanCard()
            }
        }
    }

    func onDisappear() {
        incomingActionManager.resignFirstResponder(self)
    }

    private func scanCard() {
        isScanningCard = true
        Analytics.beginLoggingCardScan(source: .welcome)

        userWalletRepository.unlock(with: .card(userWallet: nil)) { [weak self] result in
            self?.isScanningCard = false

            if result?.isSuccess != true {
                self?.incomingActionManager.discardIncomingAction()
            }

            guard
                let self, let result
            else {
                return
            }

            switch result {
            case .troubleshooting:
                showTroubleshootingView = true
            case .onboarding(let input):
                openOnboarding(with: input)
            case .error(let error):
                self.error = error.alertBinder
            case .success(let cardModel), .partial(let cardModel, _): // partial unlock is impossible in this case
                Analytics.log(event: .signedIn, params: [
                    .signInType: Analytics.ParameterValue.signInTypeCard.rawValue,
                    .walletsCount: "1", // we don't have any saved wallets, just log one,
                    .walletHasBackup: Analytics.ParameterValue.affirmativeOrNegative(for: cardModel.hasBackupCards).rawValue,
                ])
                openMain(with: cardModel)
            }
        }
    }
}

// MARK: - Navigation

extension WelcomeViewModel {
    func openMail() {
        coordinator.openMail(with: failedCardScanTracker, recipient: EmailConfig.default.recipient)
    }

    func openPromotion() {
        Analytics.log(.introductionProcessLearn)
        coordinator.openPromotion()
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

// MARK: - WelcomeViewLifecycleListener

extension WelcomeViewModel: WelcomeViewLifecycleListener {
    func resignActve() {
        storiesModel.resignActve()
    }

    func becomeActive() {
        storiesModel.becomeActive()
    }
}

// MARK: - IncomingActionResponder

extension WelcomeViewModel: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.scanCard()
        }

        switch action {
        case .start:
            return true
        case .walletConnect:
            return false
        }
    }
}
