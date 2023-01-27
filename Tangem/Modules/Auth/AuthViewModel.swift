//
//  AuthViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSdk

final class AuthViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var showTroubleshootingView: Bool = false
    @Published var isScanningCard: Bool = false
    @Published var error: AlertBinder?

    var unlockWithBiometryButtonTitle: String {
        Localization.welcomeUnlock(BiometricAuthorizationUtils.biometryType.name)
    }

    // MARK: - Dependencies

    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var unlockOnStart: Bool
    private unowned let coordinator: AuthRoutable

    init(
        unlockOnStart: Bool,
        coordinator: AuthRoutable
    ) {
        self.unlockOnStart = unlockOnStart
        self.coordinator = coordinator
    }

    func tryAgain() {
        unlockWithCard()
    }

    func requestSupport() {
        Analytics.log(.buttonRequestSupport)
        failedCardScanTracker.resetCounter()
        openMail()
    }

    func unlockWithBiometry() {
        Analytics.log(.buttonBiometricSignIn)
        userWalletRepository.unlock(with: .biometry) { [weak self] result in
            self?.didFinishUnlocking(result)
        }
    }

    func unlockWithCard() {
        isScanningCard = true
        Analytics.log(.buttonCardSignIn)
        userWalletRepository.unlock(with: .card(userWallet: nil)) { [weak self] result in
            self?.didFinishUnlocking(result)
        }
    }

    func onAppear() {
        Analytics.log(.signInScreenOpened)
    }

    func onDidAppear() {
        guard unlockOnStart else { return }

        unlockOnStart = false

        DispatchQueue.main.async {
            self.unlockWithBiometry()
        }
    }

    func onDisappear() {}

    private func didFinishUnlocking(_ result: UserWalletRepositoryResult?) {
        isScanningCard = false

        guard let result else { return }

        switch result {
        case .troubleshooting:
            showTroubleshootingView = true
        case .onboarding(let input):
            openOnboarding(with: input)
        case .error(let error):
            if let saltPayError = error as? SaltPayRegistratorError {
                self.error = saltPayError.alertBinder
            } else if case .userCancelled = error as? TangemSdkError {
                break
            } else {
                self.error = error.alertBinder
            }
        case .success(let cardModel):
            openMain(with: cardModel)
        }
    }
}

// MARK: - Navigation

extension AuthViewModel {
    func openMail() {
        coordinator.openMail(with: failedCardScanTracker, recipient: EmailConfig.default.recipient)
    }

    func openOnboarding(with input: OnboardingInput) {
        coordinator.openOnboarding(with: input)
    }

    func openMain(with cardModel: CardViewModel) {
        coordinator.openMain(with: cardModel)
    }
}
