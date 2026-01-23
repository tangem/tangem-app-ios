//
//  NewAuthViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization
import TangemUIUtils
import TangemAssets
import class TangemSdk.BiometricsUtil

final class NewAuthViewModel: ObservableObject {
    @Published var state: State?
    @Published var alert: AlertBinder?
    @Published var unlockingUserWalletId: UserWalletId?
    @Published var isCardScanning: Bool = false

    var allowsHitTesting: Bool {
        unlockingUserWalletId == nil && isCardScanning == false
    }

    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private var isBiometricsUtilAvailable: Bool {
        BiometricsUtil.isAvailable && AppSettings.shared.useBiometricAuthentication
    }

    private var analyticsCardScanSourceParameterValue: Analytics.ParameterValue {
        Analytics.CardScanSource.auth.cardWasScannedParameterValue
    }

    private var analyticsContextParams: Analytics.ContextParams { .empty }

    private let signInAnalyticsLogger = SignInAnalyticsLogger()
    private let unlockOnAppear: Bool
    private weak var coordinator: NewAuthRoutable?

    init(unlockOnAppear: Bool, coordinator: NewAuthRoutable) {
        self.unlockOnAppear = unlockOnAppear
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension NewAuthViewModel {
    func onFirstAppear() {
        logScreenOpenedAnalytics()
        setupInitialState()
    }

    func onAppear() {
        incomingActionManager.becomeFirstResponder(self)
    }

    func onDisappear() {
        incomingActionManager.resignFirstResponder(self)
    }

    func onScanTroubleshootingDialogDismiss(for userWalletID: UserWalletId) {
        state?.hideScanTroubleshootingDialog(for: userWalletID)
    }
}

// MARK: - States

private extension NewAuthViewModel {
    func setup(state: State) {
        runTask(in: self) { @MainActor viewModel in
            viewModel.state = state
        }
    }

    func setupInitialState() {
        if unlockOnAppear, isBiometricsUtilAvailable {
            setup(state: makeLockedState())
            unlockWithBiometry()
        } else {
            setup(state: makeWalletsState())
            unlockSingleProtectedMobileWalletIfNeeded()
        }
    }

    func makeLockedState() -> State {
        return .locked
    }

    func makeWalletsState() -> State {
        let addWalletButton = Button(
            title: Localization.authInfoAddWalletTitle,
            action: weakify(self, forFunction: NewAuthViewModel.addWallet)
        )

        let wallets = userWalletRepository.models.map(makeWalletItem)

        let biometricsUnlockButton: Button?
        if isBiometricsUtilAvailable {
            biometricsUnlockButton = Button(
                title: Localization.userWalletListUnlockAllWith(BiometricsUtil.biometryType.name),
                action: weakify(self, forFunction: NewAuthViewModel.onUnlockWithBiometryTap)
            )
        } else {
            biometricsUnlockButton = nil
        }

        let stateItem = WalletsStateItem(
            addWalletButton: addWalletButton,
            biometricsUnlockButton: biometricsUnlockButton,
            wallets: wallets
        )

        return .wallets(stateItem)
    }

    func makeWalletItem(userWalletModel: UserWalletModel) -> WalletItem {
        let description = userWalletModel.config.cardSetLabel
        let unlocker = UserWalletModelUnlockerFactory.makeUnlocker(userWalletModel: userWalletModel)
        let isProtected = !unlocker.canUnlockAutomatically
        return WalletItem(
            id: userWalletModel.userWalletId,
            title: userWalletModel.name,
            description: description,
            imageProvider: userWalletModel.walletImageProvider,
            isProtected: isProtected,
            scanTroubleshootingDialog: nil,
            isUnlocking: { userWalletId in
                userWalletModel.userWalletId == userWalletId
            },
            action: { [weak self] in
                self?.unlock(userWalletModel: userWalletModel)
            }
        )
    }
}

// MARK: - Unlocking

private extension NewAuthViewModel {
    func unlock(userWalletModel: UserWalletModel) {
        runTask(in: self) { viewModel in
            let unlocker = UserWalletModelUnlockerFactory.makeUnlocker(userWalletModel: userWalletModel)

            viewModel.signInAnalyticsLogger.logSignInButtonWalletEvent(
                signInType: unlocker.analyticsSignInType,
                userWalletModel: userWalletModel
            )

            await viewModel.startUnlocking(userWalletId: userWalletModel.userWalletId)
            let unlockResult = await unlocker.unlock()
            await viewModel.finishUnlocking()

            if case .success = unlockResult, unlocker.analyticsSignInType == .card {
                viewModel.logSuccessScanCardToUnlockAnalytics(userWalletModel: userWalletModel)
            }

            await viewModel.handleUnlock(
                result: unlockResult,
                userWalletModel: userWalletModel,
                signInType: unlocker.analyticsSignInType
            )
        }
    }

    @MainActor
    func startUnlocking(userWalletId: UserWalletId) {
        unlockingUserWalletId = userWalletId
    }

    @MainActor
    func finishUnlocking() {
        unlockingUserWalletId = nil
    }

    func handleUnlock(result: UserWalletModelUnlockerResult, userWalletModel: UserWalletModel, signInType: Analytics.SignInType) async {
        switch result {
        case .success(let userWalletId, let encryptionKey):
            do {
                let unlockMethod = UserWalletRepositoryUnlockMethod.encryptionKey(userWalletId: userWalletId, encryptionKey: encryptionKey)
                let userWalletModel = try await userWalletRepository.unlock(with: unlockMethod)
                signInAnalyticsLogger.logSignInEvent(signInType: signInType, userWalletModel: userWalletModel)
                await openMain(userWalletModel: userWalletModel)
            } catch {
                incomingActionManager.discardIncomingAction()
                await runOnMain {
                    alert = error.alertBinder
                }
            }

        case .biometrics(let context):
            do {
                let unlockMethod = UserWalletRepositoryUnlockMethod.biometrics(context)
                let userWalletModel = try await userWalletRepository.unlock(with: unlockMethod)
                signInAnalyticsLogger.logSignInEvent(signInType: signInType, userWalletModel: userWalletModel)
                await openMain(userWalletModel: userWalletModel)
            } catch {
                incomingActionManager.discardIncomingAction()
                await runOnMain {
                    alert = error.alertBinder
                }
            }

        case .scanTroubleshooting:
            await openTroubleshooting(userWalletModel: userWalletModel)

        case .userWalletNeedsToDelete:
            userWalletRepository.delete(userWalletId: userWalletModel.userWalletId)
            setup(state: makeWalletsState())

        case .error(let error) where error.isCancellationError:
            break

        case .error(let error):
            await runOnMain {
                alert = error.alertBinder
            }
        }
    }

    /// Returns wallet if it is single mobile protected wallet in repository.
    func singleProtectedMobileWallet() -> UserWalletModel? {
        guard
            userWalletRepository.models.count == 1,
            let userWalletModel = userWalletRepository.models.first
        else {
            return nil
        }

        let unlocker = UserWalletModelUnlockerFactory.makeUnlocker(userWalletModel: userWalletModel)

        guard unlocker.canShowUnlockUIAutomatically else {
            return nil
        }

        return userWalletModel
    }
}

// MARK: - Biometrics unlocking

private extension NewAuthViewModel {
    func onUnlockWithBiometryTap() {
        logUnlockAllWithBiometricsAnalytics()
        unlockWithBiometry()
    }

    func unlockWithBiometry() {
        runTask(in: self) { viewModel in
            do {
                let context = try await UserWalletBiometricsUnlocker().unlock()
                let userWalletModel = try await viewModel.userWalletRepository.unlock(with: .biometrics(context))

                viewModel.signInAnalyticsLogger.logSignInEvent(signInType: .biometrics, userWalletModel: userWalletModel)

                await viewModel.openMain(userWalletModel: userWalletModel)
            } catch {
                await viewModel.handleUnlockWithBiometryResult(error: error)
            }
        }
    }

    func handleUnlockWithBiometryResult(error: Error) async {
        incomingActionManager.discardIncomingAction()

        await runOnMain {
            switch state {
            case .locked:
                setup(state: makeWalletsState())
                if !error.isCancellationError {
                    alert = error.alertBinder
                } else {
                    unlockSingleProtectedMobileWalletIfNeeded()
                }
            case .wallets:
                if !error.isCancellationError {
                    alert = error.alertBinder
                }
            case .none:
                break
            }
        }
    }

    func unlockSingleProtectedMobileWalletIfNeeded() {
        guard let userWalletModel = singleProtectedMobileWallet() else {
            return
        }
        unlock(userWalletModel: userWalletModel)
    }
}

// MARK: - Card unlocking

private extension NewAuthViewModel {
    func unlockWithCardTryAgain(userWalletModel: UserWalletModel) {
        logScanCardTryAgainAnalytics()
        unlock(userWalletModel: userWalletModel)
    }
}

// MARK: - Card scanning

private extension NewAuthViewModel {
    func scanCard() {
        logScanCardTapAnalytics()

        isCardScanning = true

        runTask(in: self) { viewModel in
            let cardScanner = CardScannerFactory().makeDefaultScanner()
            let userWalletCardScanner = UserWalletCardScanner(scanner: cardScanner)
            let result = await userWalletCardScanner.scanCard()

            switch result {
            case .error(let error) where error.isCancellationError:
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isCardScanning = false
                }

            case .error(let error):
                viewModel.logScanCardAnalytics(error: error)
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isCardScanning = false
                    viewModel.alert = error.alertBinder
                }

            case .onboarding(let input, _):
                viewModel.logScanCardOnboardingAnalytics(cardInput: input.cardInput)
                viewModel.incomingActionManager.discardIncomingAction()

                await MainActor.run {
                    viewModel.isCardScanning = false
                    viewModel.openOnboarding(input: input)
                }

            case .scanTroubleshooting:
                viewModel.logScanCardTroubleshootingAnalytics()
                viewModel.incomingActionManager.discardIncomingAction()

                await MainActor.run {
                    viewModel.isCardScanning = false
                    viewModel.openTroubleshooting()
                }

            case .success(let cardInfo):
                viewModel.logScanCardSuccessAnalytics(cardInfo: cardInfo)

                do {
                    if let newUserWalletModel = CommonUserWalletModelFactory().makeModel(
                        walletInfo: .cardWallet(cardInfo),
                        keys: .cardWallet(keys: cardInfo.card.wallets)
                    ) {
                        try viewModel.userWalletRepository.add(userWalletModel: newUserWalletModel)

                        await MainActor.run {
                            viewModel.isCardScanning = false
                            viewModel.openMain(userWalletModel: newUserWalletModel)
                        }
                    } else {
                        throw UserWalletRepositoryError.cantUnlockWallet
                    }
                } catch {
                    viewModel.incomingActionManager.discardIncomingAction()

                    await runOnMain {
                        viewModel.isCardScanning = false
                        viewModel.alert = error.alertBinder
                    }
                }
            }
        }
    }

    func scanCardTryAgain() {
        logScanCardTryAgainAnalytics()
        scanCard()
    }
}

// MARK: - Private methods

private extension NewAuthViewModel {
    func addWallet() {
        logAddWalletTapAnalytics()
        scanCard()
    }
}

// MARK: - Navigation

@MainActor
private extension NewAuthViewModel {
    func openMain(userWalletModel: UserWalletModel) {
        coordinator?.openMain(with: userWalletModel)
    }

    func openOnboarding(input: OnboardingInput) {
        coordinator?.openOnboarding(with: input)
    }

    func openTroubleshooting(userWalletModel: UserWalletModel) {
        logScanCardTroubleshootingAnalytics()

        let tryAgainButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonTryAgain) { [weak self] in
            self?.unlockWithCardTryAgain(userWalletModel: userWalletModel)
        }

        let readMoreButton = ConfirmationDialogViewModel.Button(title: Localization.commonReadMore) { [weak self] in
            self?.openScanCardManual()
        }

        let requestSupportButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonRequestSupport) { [weak self] in
            self?.openSupportRequest()
        }

        let confirmationDialog = ConfirmationDialogViewModel(
            title: Localization.alertTroubleshootingScanCardTitle,
            subtitle: Localization.alertTroubleshootingScanCardMessage,
            buttons: [
                tryAgainButton,
                readMoreButton,
                requestSupportButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )

        state?.show(scanTroubleshootingDialog: confirmationDialog, for: userWalletModel.userWalletId)
    }

    func openTroubleshooting() {
        logScanCardTroubleshootingAnalytics()

        let tryAgainButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonTryAgain) { [weak self] in
            self?.scanCardTryAgain()
        }

        let readMoreButton = ConfirmationDialogViewModel.Button(title: Localization.commonReadMore) { [weak self] in
            self?.openScanCardManual()
        }

        let requestSupportButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonRequestSupport) { [weak self] in
            self?.openSupportRequest()
        }

        confirmationDialog = ConfirmationDialogViewModel(
            title: Localization.alertTroubleshootingScanCardTitle,
            subtitle: Localization.alertTroubleshootingScanCardMessage,
            buttons: [
                tryAgainButton,
                readMoreButton,
                requestSupportButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )
    }

    func openScanCardManual() {
        logCantScanTheCardAnalytics()
        coordinator?.openScanCardManual()
    }

    func openSupportRequest() {
        logScanCardRequestSupportAnalytics()
        failedCardScanTracker.resetCounter()
        coordinator?.openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient)
    }
}

// MARK: - Analytics

private extension NewAuthViewModel {
    func logScreenOpenedAnalytics() {
        let walletsCount = userWalletRepository.models.count
        Analytics.log(
            event: .signInScreenOpened,
            params: [.walletCount: String(walletsCount)],
            contextParams: analyticsContextParams
        )
    }

    func logSuccessScanCardToUnlockAnalytics(userWalletModel: UserWalletModel) {
        Analytics.log(
            .cardWasScanned,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: .custom(userWalletModel.analyticsContextData)
        )
    }

    func logUnlockAllWithBiometricsAnalytics() {
        Analytics.log(.signInButtonUnlockAllWithBiometrics, contextParams: analyticsContextParams)
    }

    func logAddWalletTapAnalytics() {
        Analytics.log(
            .buttonAddWallet,
            params: [.source: .signIn],
            contextParams: analyticsContextParams
        )
    }

    func logScanCardTapAnalytics() {
        Analytics.log(
            Analytics.CardScanSource.auth.cardScanButtonEvent,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: analyticsContextParams
        )
    }

    func logScanCardAnalytics(error: Error) {
        Analytics.logScanError(
            error,
            source: .signIn,
            contextParams: analyticsContextParams
        )
        Analytics.logVisaCardScanErrorIfNeeded(error, source: .signIn)
    }

    func logCantScanTheCardAnalytics() {
        Analytics.log(
            .cantScanTheCardButtonBlog,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: analyticsContextParams
        )
    }

    func logScanCardOnboardingAnalytics(cardInput: OnboardingInput.CardInput) {
        Analytics.log(
            .cardWasScanned,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: cardInput.getContextParams()
        )
    }

    func logScanCardSuccessAnalytics(cardInfo: CardInfo) {
        Analytics.log(
            .cardWasScanned,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: .custom(cardInfo.analyticsContextData)
        )
    }

    func logScanCardTryAgainAnalytics() {
        Analytics.log(
            .cantScanTheCardTryAgainButton,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: analyticsContextParams
        )
    }

    func logScanCardTroubleshootingAnalytics() {
        Analytics.log(
            .cantScanTheCard,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: analyticsContextParams
        )
    }

    func logScanCardRequestSupportAnalytics() {
        Analytics.log(
            .requestSupport,
            params: [.source: analyticsCardScanSourceParameterValue],
            contextParams: analyticsContextParams
        )
    }
}

// MARK: - IncomingActionResponder

extension NewAuthViewModel: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        switch action {
        case .start:
            return true
        default:
            return false
        }
    }
}

// MARK: - Types

extension NewAuthViewModel {
    enum State: Equatable {
        case locked
        case wallets(WalletsStateItem)

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.locked, .locked): true
            case (.wallets, .wallets): true
            default: false
            }
        }

        mutating func show(scanTroubleshootingDialog dialog: ConfirmationDialogViewModel, for userWalletID: UserWalletId) {
            update(scanTroubleshootingDialog: dialog, for: userWalletID)
        }

        mutating func hideScanTroubleshootingDialog(for userWalletID: UserWalletId) {
            update(scanTroubleshootingDialog: nil, for: userWalletID)
        }

        private mutating func update(scanTroubleshootingDialog: ConfirmationDialogViewModel?, for userWalletID: UserWalletId) {
            guard
                case .wallets(var walletsStateItem) = self,
                let walletIndex = walletsStateItem.wallets.firstIndex(where: { $0.id == userWalletID })
            else {
                return
            }

            walletsStateItem.wallets[walletIndex].scanTroubleshootingDialog = scanTroubleshootingDialog
            self = .wallets(walletsStateItem)
        }
    }

    struct WalletsStateItem {
        let title = Localization.welcomeUnlockTitle
        let description = Localization.authInfoSubtitle
        let addWalletButton: Button
        let biometricsUnlockButton: Button?
        var wallets: [WalletItem]
    }

    struct WalletItem: Identifiable {
        let id: UserWalletId
        let title: String
        let description: String
        let imageProvider: WalletImageProviding
        let isProtected: Bool

        var scanTroubleshootingDialog: ConfirmationDialogViewModel?

        let isUnlocking: (UserWalletId?) -> Bool
        let action: () -> Void
    }

    struct Button {
        let title: String
        let action: () -> Void
    }
}
