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
import TangemFoundation

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
        runTask(in: self) { viewModel in
            do {
                let context = try await UserWalletBiometricsUnlocker().unlock()
                let userWalletModel = try viewModel.userWalletRepository.unlock(with: .biometrics(context))

                await runOnMain {
                    viewModel.openMain(with: userWalletModel)
                }
            } catch where error.isCancellationError {
                viewModel.incomingActionManager.discardIncomingAction()
            } catch {
                Analytics.logScanError(error, source: .signIn)
                Analytics.logVisaCardScanErrorIfNeeded(error, source: .signIn)
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.error = error.alertBinder
                }
            }
        }
    }

    func unlockWithCard() {
        isScanningCard = true
        Analytics.beginLoggingCardScan(source: .auth)

        runTask(in: self) { viewModel in
            let cardScanner = CardScannerFactory().makeDefaultScanner()
            let userWalletCardScanner = UserWalletCardScanner(scanner: cardScanner)
            let result = await userWalletCardScanner.scanCard()

            switch result {
            case .error(let error) where error.isCancellationError:
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanningCard = false
                }

            case .error(let error):
                Analytics.logScanError(error, source: .signIn)
                Analytics.logVisaCardScanErrorIfNeeded(error, source: .signIn)
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanningCard = false
                    viewModel.error = error.alertBinder
                }

            case .onboarding(let input):
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanningCard = false
                    viewModel.openOnboarding(with: input)
                }

            case .scanTroubleshooting:
                Analytics.log(.cantScanTheCard, params: [.source: .signIn])
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanningCard = false
                    viewModel.openTroubleshooting()
                }

            case .success(let cardInfo):
                do {
                    let userWalletModel = try viewModel.userWalletRepository.unlock(with: .card(cardInfo))

                    await runOnMain {
                        viewModel.isScanningCard = false
                        viewModel.openMain(with: userWalletModel)
                    }

                } catch {
                    viewModel.incomingActionManager.discardIncomingAction()

                    await runOnMain {
                        viewModel.isScanningCard = false
                        viewModel.error = error.alertBinder
                    }
                }
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
