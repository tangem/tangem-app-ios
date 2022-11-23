//
//  AuthViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk
import Combine

final class AuthViewModel: ObservableObject {
    // MARK: - ViewState
    @Published var showTroubleshootingView: Bool = false
    @Published var isScanningCard: Bool = false
    @Published var error: AlertBinder?

    // This screen seats on the navigation stack permanently. We should preserve the navigationBar state to fix the random hide/disappear events of navigationBar on iOS13 on other screens down the navigation hierarchy.
    @Published var navigationBarHidden: Bool = false

    var unlockWithBiometryLocalizationKey: LocalizedStringKey {
        switch BiometricAuthorizationUtils.biometryType {
        case .faceID:
            return "welcome_unlock_face_id"
        case .touchID:
            return "welcome_unlock_touch_id"
        case .none:
            return ""
        @unknown default:
            return ""
        }
    }

    // MARK: - Dependencies
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private unowned let coordinator: AuthRoutable

    private var bag: Set<AnyCancellable> = []

    init(
        coordinator: AuthRoutable
    ) {
        self.coordinator = coordinator
        userWalletRepository.delegate = self

        userWalletRepository
            .eventProvider
            .sink { [weak self] event in
                if case .selected = event,
                   let selectedModel = self?.userWalletRepository.selectedModel {
                    self?.updateMain(with: selectedModel)
                }
            }
            .store(in: &bag)
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
        navigationBarHidden = true
    }

    func onDidAppear() {
        DispatchQueue.main.async {
            self.unlockWithBiometry()
        }
    }

    func onDisappear() {
        navigationBarHidden = false
    }

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

    private func updateMain(with cardModel: CardViewModel) {
        coordinator.updateMain(with: cardModel)
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

extension AuthViewModel: UserWalletRepositoryDelegate {
    func showTOS(at url: URL, _ completion: @escaping (Bool) -> Void) {
        coordinator.openDisclaimer(at: url, completion)
    }
}
