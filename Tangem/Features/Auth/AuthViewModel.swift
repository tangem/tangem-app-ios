//
//  AuthViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import TangemLocalization
import TangemUIUtils

final class AuthViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var isScanningCard: Bool = false
    @Published var error: AlertBinder?
    @Published var actionSheet: ActionSheetBinder?

    var unlockWithBiometryButtonTitle: String {
        Localization.welcomeUnlock(BiometricAuthorizationUtils.biometryType.name)
    }

    // MARK: - Dependencies

    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private weak var coordinator: AuthRoutable?

    private var unlockOnAppear: Bool

    init(unlockOnAppear: Bool = false, coordinator: AuthRoutable) {
        self.unlockOnAppear = unlockOnAppear
        self.coordinator = coordinator
    }

    func tryAgain() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .signIn])
        unlockWithCard()
    }

    func openScanCardManual() {
        Analytics.log(.cantScanTheCardButtonBlog, params: [.source: .signIn])
        coordinator?.openScanCardManual()
    }

    func requestSupport() {
        Analytics.log(.requestSupport, params: [.source: .signIn])
        failedCardScanTracker.resetCounter()
        openMail()
    }

    func unlockWithBiometryButtonTapped() {
        Analytics.log(.buttonBiometricSignIn)
        unlockWithBiometry()
    }

    func unlockWithBiometry() {
        userWalletRepository.unlock(with: .biometry) { [weak self] result in
            DispatchQueue.main.async {
                self?.didFinishUnlocking(result)
            }
        }
    }

    func unlockWithCard() {
        isScanningCard = true
        Analytics.beginLoggingCardScan(source: .auth)

        userWalletRepository.unlock(with: .card(userWalletId: nil, scanner: CardScannerFactory().makeDefaultScanner())) { [weak self] result in
            DispatchQueue.main.async {
                self?.didFinishUnlocking(result)
            }
        }
    }

    func onAppear() {
        Analytics.log(.signInScreenOpened)
        incomingActionManager.becomeFirstResponder(self)

        if unlockOnAppear {
            DispatchQueue.main.async {
                self.unlockOnAppear = false
                self.unlockWithBiometry()
            }
        }
    }

    func onDisappear() {
        incomingActionManager.resignFirstResponder(self)
    }

    private func didFinishUnlocking(_ result: UserWalletRepositoryResult?) {
        isScanningCard = false

        if result?.isSuccess != true {
            incomingActionManager.discardIncomingAction()
        }

        guard let result else { return }

        switch result {
        case .troubleshooting:
            Analytics.log(.cantScanTheCard, params: [.source: .signIn])
            openTroubleshooting()
        case .onboarding(let input):
            openOnboarding(with: input)
        case .error(let error):
            if error.isCancellationError {
                return
            }

            Analytics.logScanError(error, source: .signIn)
            Analytics.logVisaCardScanErrorIfNeeded(error, source: .signIn)
            self.error = error.alertBinder
        case .success(let model), .partial(let model, _):
            openMain(with: model)
        }
    }
}

// MARK: - Navigation

extension AuthViewModel {
    func openTroubleshooting() {
        let sheet = ActionSheet(
            title: Text(Localization.alertTroubleshootingScanCardTitle),
            message: Text(Localization.alertTroubleshootingScanCardMessage),
            buttons: [
                .default(Text(Localization.alertButtonTryAgain), action: weakify(self, forFunction: AuthViewModel.tryAgain)),
                .default(Text(Localization.commonReadMore), action: weakify(self, forFunction: AuthViewModel.openScanCardManual)),
                .default(Text(Localization.alertButtonRequestSupport), action: weakify(self, forFunction: AuthViewModel.requestSupport)),
                .cancel(),
            ]
        )

        actionSheet = ActionSheetBinder(sheet: sheet)
    }

    func openMail() {
        coordinator?.openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient)
    }

    func openOnboarding(with input: OnboardingInput) {
        coordinator?.openOnboarding(with: input)
    }

    func openMain(with model: UserWalletModel) {
        coordinator?.openMain(with: model)
    }
}

// MARK: - IncomingActionResponder

extension AuthViewModel: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        switch action {
        case .start:
            return true
        default:
            return false
        }
    }
}
