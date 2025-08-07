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
    @Published var alert: AlertBinder?
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
        setup(state: makeInitialState())
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
    func setup(state: State) {
        self.state = state
    }

    func makeInitialState() -> State {
        if unlockOnAppear {
            unlockWithBiometry()
            return makeLockedState()
        } else {
            return makeWalletsState()
        }
    }

    func makeLockedState() -> State {
        return .locked
    }

    func makeWalletsState() -> State {
        let addWallet = AddWalletItem(
            title: Localization.authInfoAddWalletTitle,
            action: weakify(self, forFunction: NewAuthViewModel.openAddWallet)
        )

        let info = InfoItem(
            title: Localization.welcomeUnlockTitle,
            description: Localization.authInfoSubtitle
        )

        let wallets = userWalletRepository.models.map(makeWalletItem)

        let unlock: UnlockItem?
        if BiometricsUtil.isAvailable {
            unlock = UnlockItem(
                title: Localization.userWalletListUnlockAllWith(BiometricAuthorizationUtils.biometryType.name),
                action: weakify(self, forFunction: NewAuthViewModel.onUnlockWithBiometryTap)
            )
        } else {
            unlock = nil
        }

        let stateItem = WalletsStateItem(
            addWallet: addWallet,
            info: info,
            wallets: wallets,
            unlock: unlock
        )

        return .wallets(stateItem)
    }

    func makeWalletItem(userWalletModel: UserWalletModel) -> WalletItem {
        let description = userWalletModel.config.cardSetLabel ?? .empty
        let unlocker = UserWalletModelUnlockerFactory.makeUnlocker(userWalletModel: userWalletModel)
        let isProtected = !unlocker.canUnlockAutomatically
        return WalletItem(
            title: userWalletModel.name,
            description: description,
            imageProvider: userWalletModel.walletImageProvider,
            isProtected: isProtected,
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
            Analytics.beginLoggingCardScan(source: .auth)
            let unlockResult = await unlocker.unlock()
            await viewModel.handleUnlock(result: unlockResult, userWalletModel: userWalletModel)
        }
    }

    func handleUnlock(result: UserWalletModelUnlockerResult, userWalletModel: UserWalletModel) async {
        switch result {
        case .success(let userWalletId, let encryptionKey):
            do {
                let unlockMethod = UserWalletRepositoryUnlockMethod.encryptionKey(userWalletId: userWalletId, encryptionKey: encryptionKey)
                let userWalletModel = try await userWalletRepository.unlock(with: unlockMethod)
                await openMain(userWalletModel: userWalletModel)
            } catch {
                incomingActionManager.discardIncomingAction()
                await runOnMain {
                    alert = error.alertBinder
                }
            }

        case .bioSelected:
            unlockWithBiometry()

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

    /// Returns wallet if it is single hot protected wallet in repository.
    func singleProtectedHotWallet() -> UserWalletModel? {
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
        Analytics.log(.buttonBiometricSignIn)
        unlockWithBiometry()
    }

    func unlockWithBiometry() {
        runTask(in: self) { viewModel in
            do {
                let context = try await UserWalletBiometricsUnlocker().unlock()
                let userWalletModel = try await viewModel.userWalletRepository.unlock(with: .biometrics(context))
                await viewModel.openMain(userWalletModel: userWalletModel)
            } catch {
                viewModel.incomingActionManager.discardIncomingAction()
                await viewModel.handleUnlockWithBiometryResult(error: error)
            }
        }
    }

    func handleUnlockWithBiometryResult(error: Error) async {
        incomingActionManager.discardIncomingAction()

        await runOnMain {
            isScanning = false

            switch state {
            case .locked:
                setup(state: makeWalletsState())
                if let userWalletModel = singleProtectedHotWallet() {
                    unlock(userWalletModel: userWalletModel)
                }
            case .wallets:
                alert = error.alertBinder
            case .none:
                break
            }
        }
    }
}

// MARK: - Card unlocking

private extension NewAuthViewModel {
    func unlockWithCardTryAgain(userWalletModel: UserWalletModel) {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .signIn])
        unlock(userWalletModel: userWalletModel)
    }
}

// MARK: - Navigation

@MainActor
private extension NewAuthViewModel {
    func openMain(userWalletModel: UserWalletModel) {
        coordinator?.openMain(with: userWalletModel)
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

    func openOnboarding(with input: OnboardingInput) {
        coordinator?.openOnboarding(with: input)
    }

    func openTroubleshooting(userWalletModel: UserWalletModel) {
        let sheet = ActionSheet(
            title: Text(Localization.alertTroubleshootingScanCardTitle),
            message: Text(Localization.alertTroubleshootingScanCardMessage),
            buttons: [
                .default(
                    Text(Localization.alertButtonTryAgain),
                    action: { [weak self] in
                        self?.unlockWithCardTryAgain(userWalletModel: userWalletModel)
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
        case wallets(WalletsStateItem)

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.locked, .locked): true
            case (.wallets, .wallets): true
            default: false
            }
        }
    }

    struct WalletsStateItem {
        let addWallet: AddWalletItem
        let info: InfoItem
        let wallets: [WalletItem]
        let unlock: UnlockItem?
    }

    struct WalletItem: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let imageProvider: WalletImageProviding
        let isProtected: Bool
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
