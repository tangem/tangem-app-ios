//
//  NewAuthViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemUIUtils
import TangemAssets
import class TangemSdk.BiometricsUtil

final class NewAuthViewModel: ObservableObject {
    @Published var state: State?
    @Published var error: AlertBinder?
    @Published var actionSheet: ActionSheetBinder?
    @Published var isScanning: Bool = false

    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

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
        state = calculateState()
    }

    func onAppear() {
        Analytics.log(.signInScreenOpened)
        incomingActionManager.becomeFirstResponder(self)
    }

    func onDisappear() {
        incomingActionManager.resignFirstResponder(self)
    }
}

// MARK: - States

private extension NewAuthViewModel {
    func calculateState() -> State {
        guard !haveOnlyUnsecureHotWallets() else {
            // [REDACTED_TODO_COMMENT]
            return makeDefaultState()
        }

        if unlockOnAppear {
            DispatchQueue.main.async { [weak self] in
                self?.unlockWithBiometry()
            }
            return makeLockedState()
        } else {
            if let singleWallet = singleSecureHotWallet() {
                DispatchQueue.main.async { [weak self] in
                    self?.openHotAccessCode(userWalletModel: singleWallet)
                }
            }
            return makeUnlockedState()
        }
    }

    func makeDefaultState() -> State {
        return .locked
    }

    func makeLockedState() -> State {
        return .locked
    }

    func makeUnlockedState() -> State {
        let addWallet = AddWalletItem(
            title: Localization.authInfoAddWalletTitle,
            action: weakify(self, forFunction: NewAuthViewModel.openAddWallet)
        )

        let info = InfoItem(
            title: Localization.welcomeUnlockTitle,
            description: Localization.authInfoSubtitle
        )

        let wallets = makeWalletsItems()

        let unlock: UnlockItem?
        if BiometricsUtil.isAvailable {
            unlock = UnlockItem(
                title: Localization.userWalletListUnlockAllWith(BiometricAuthorizationUtils.biometryType.name),
                action: weakify(self, forFunction: NewAuthViewModel.onUnlockWithBiometryTap)
            )
        } else {
            unlock = nil
        }

        let stateItem = UnlockedStateItem(
            addWallet: addWallet,
            info: info,
            wallets: wallets,
            unlock: unlock
        )

        return .unlocked(stateItem)
    }

    func makeWalletsItems() -> [WalletItem] {
        // [REDACTED_TODO_COMMENT]
        return []
    }

    /// Check if there are only unsecure hot wallets, meaning there are no secure hot wallets or any cold wallets.
    func haveOnlyUnsecureHotWallets() -> Bool {
        // [REDACTED_TODO_COMMENT]
        return false
    }

    /// Check if there are only one secure hot wallet.
    func singleSecureHotWallet() -> UserWalletModel? {
        guard
            userWalletRepository.models.count == 1,
            let wallet = userWalletRepository.models.first
        else {
            return nil
        }

        // [REDACTED_TODO_COMMENT]
        return nil
    }
}

// MARK: - Unlocking

private extension NewAuthViewModel {
    func onUnlockWithBiometryTap() {
        Analytics.log(.buttonBiometricSignIn)
        unlockWithBiometry()
    }

    func unlockWithBiometry() {
        runTask(in: self) { viewModel in
            do {
                let context = try await UserWalletBiometricsUnlocker().unlock()
                let userWalletModel = try await viewModel.userWalletRepository.unlock(with: .biometrics(context))

                await runOnMain {
                    viewModel.openMain(with: userWalletModel)
                }
            } catch {
                viewModel.incomingActionManager.discardIncomingAction()
            }
        }
    }

    func unlockWithCard(userWalletId: UserWalletId) {
        isScanning = true
        Analytics.beginLoggingCardScan(source: .auth)

        runTask(in: self) { viewModel in

            guard let userWalletModel = viewModel.userWalletRepository.models[userWalletId] else {
                await runOnMain {
                    viewModel.isScanning = false
                }

                return
            }

            let unlocker = UserWalletModelUnlockerFactory.makeUnlocker(userWalletModel: userWalletModel)
            let result = await unlocker.unlock()

            switch result {
            case .error(let error) where error.isCancellationError:
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                }

            case .error(let error):
                await viewModel.handleUnlockWithCard(resultError: error)

            case .scanTroubleshooting:
                Analytics.log(.cantScanTheCard, params: [.source: .introduction])
                viewModel.incomingActionManager.discardIncomingAction()

                await runOnMain {
                    viewModel.isScanning = false
                    viewModel.openTroubleshooting(userWalletId: userWalletId)
                }

            case .success(let userWalletId, let encryptionKey):
                do {
                    let unlockMethod = UserWalletRepositoryUnlockMethod.encryptionKey(userWalletId: userWalletId, encryptionKey: encryptionKey)
                    let userWalletModel = try await viewModel.userWalletRepository.unlock(with: unlockMethod)

                    await runOnMain {
                        viewModel.isScanning = false
                        viewModel.openMain(with: userWalletModel)
                    }

                } catch {
                    viewModel.incomingActionManager.discardIncomingAction()

                    await runOnMain {
                        viewModel.isScanning = false
                        viewModel.error = error.alertBinder
                    }
                }

            case .bioSelected:
                #warning("Implement")

            case .userWalletNeedsToDelete:
                #warning("Implement")
            }
        }
    }

    @MainActor
    func handleUnlockWithCard(resultError: Error) {
        isScanning = false

        Analytics.logScanError(resultError, source: .signIn)
        Analytics.logVisaCardScanErrorIfNeeded(resultError, source: .signIn)
        incomingActionManager.discardIncomingAction()

        switch state {
        case .locked:
            state = makeUnlockedState()
        case .unlocked:
            error = resultError.alertBinder
        case .none:
            break
        }
    }

    func unlockWithCardTryAgain(userWalletId: UserWalletId) {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .signIn])
        unlockWithCard(userWalletId: userWalletId)
    }
}

// MARK: - Navigation

private extension NewAuthViewModel {
    func openMain(with model: UserWalletModel) {
        coordinator?.openMain(with: model)
    }

    func openAddWallet() {
        let sheet = ActionSheet(
            title: Text(Localization.authInfoAddWalletTitle),
            buttons: [
                .default(
                    Text(Localization.homeButtonCreateNewWallet),
                    action: weakify(self, forFunction: NewAuthViewModel.openCreateWallet)
                ),
                .default(
                    Text(Localization.homeButtonAddExistingWallet),
                    action: weakify(self, forFunction: NewAuthViewModel.openImportWallet)
                ),
                .default(
                    Text(Localization.detailsBuyWallet),
                    action: weakify(self, forFunction: NewAuthViewModel.openBuyWallet)
                ),
                .cancel(),
            ]
        )

        actionSheet = ActionSheetBinder(sheet: sheet)
    }

    func openCreateWallet() {
        coordinator?.openCreateWallet()
    }

    func openImportWallet() {
        coordinator?.openImportWallet()
    }

    func openBuyWallet() {
        Analytics.log(.shopScreenOpened)
        coordinator?.openShop()
    }

    func openHotAccessCode(userWalletModel: UserWalletModel) {
        coordinator?.openHotAccessCode(with: userWalletModel)
    }

    func openOnboarding(with input: OnboardingInput) {
        coordinator?.openOnboarding(with: input)
    }

    func openTroubleshooting(userWalletId: UserWalletId) {
        let sheet = ActionSheet(
            title: Text(Localization.alertTroubleshootingScanCardTitle),
            message: Text(Localization.alertTroubleshootingScanCardMessage),
            buttons: [
                .default(
                    Text(Localization.alertButtonTryAgain),
                    action: { [weak self] in
                        self?.unlockWithCardTryAgain(userWalletId: userWalletId)
                    }
                ),
                .default(
                    Text(Localization.commonReadMore),
                    action: weakify(self, forFunction: NewAuthViewModel.openScanCardManual)
                ),
                .default(
                    Text(Localization.alertButtonRequestSupport),
                    action: weakify(self, forFunction: NewAuthViewModel.openSupportRequest)
                ),
                .cancel(),
            ]
        )

        actionSheet = ActionSheetBinder(sheet: sheet)
    }

    func openScanCardManual() {
        Analytics.log(.cantScanTheCardButtonBlog, params: [.source: .signIn])
        coordinator?.openScanCardManual()
    }

    func openSupportRequest() {
        Analytics.log(.requestSupport, params: [.source: .signIn])
        failedCardScanTracker.resetCounter()
        coordinator?.openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient)
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
        case unlocked(UnlockedStateItem)

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.locked, .locked): true
            case (.unlocked, .unlocked): true
            default: false
            }
        }
    }

    struct UnlockedStateItem {
        let addWallet: AddWalletItem
        let info: InfoItem
        let wallets: [WalletItem]
        let unlock: UnlockItem?
    }

    struct WalletItem: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let isSecured: Bool
        let icon: ImageType
        let action: () -> Void
    }

    struct AddWalletItem {
        let title: String
        let action: () -> Void
    }

    struct InfoItem {
        let title: String
        let description: String
    }

    struct UnlockItem {
        let title: String
        let action: () -> Void
    }
}
