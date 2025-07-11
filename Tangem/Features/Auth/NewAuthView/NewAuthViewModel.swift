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
import TangemLocalization
import TangemUIUtils
import TangemAssets
import class TangemSdk.BiometricsUtil

final class NewAuthViewModel: ObservableObject {
    @Published var state: State?
    @Published var error: AlertBinder?
    @Published var actionSheet: ActionSheetBinder?

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
    func onDidLoad() {
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

        if !unlockOnAppear {
            DispatchQueue.main.async { [weak self] in
                self?.unlockWithBiometry()
            }
            return makeLockedState()
        } else {
            if let singleWallet = singleSecureHotWallet() {
                DispatchQueue.main.async { [weak self] in
                    self?.openHotAccessCode(userWalletId: singleWallet.userWalletId)
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
            title: "Add Wallet",
            action: weakify(self, forFunction: NewAuthViewModel.openAddWallet)
        )

        let info = InfoItem(
            title: "Welcome back!",
            description: "Select a wallet to log in"
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
        return [ // remove !!!
            WalletItem(
                name: "Cold wallet",
                description: "3 cards",
                isSecured: true,
                icon: Assets.Cards.babyDogeDouble,
                action: { [weak self] in
                    self?.onUnlockWithCardTap()
                }
            ),
            WalletItem(
                name: "Hot wallet",
                description: "Phone Wallet",
                isSecured: false,
                icon: Assets.Cards.walletDouble,
                action: { [weak self] in
                    self?.openHotAccessCode(userWalletId: UserWalletId(value: Data()))
                }
            ),
        ]
        // [REDACTED_TODO_COMMENT]
        return []
    }

    /// Check if there are only unsecure hot wallets, meaning there are no secure hot wallets or cold wallets.
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
        userWalletRepository.unlock(with: .biometry) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleUnlock(result: result)
            }
        }
    }

    func onUnlockWithCardTap() {
        Analytics.beginLoggingCardScan(source: .auth)
        unlockWithCard()
    }

    func unlockWithCard() {
        // [REDACTED_TODO_COMMENT]
        userWalletRepository.unlock(with: .card(userWalletId: nil, scanner: CardScannerFactory().makeDefaultScanner())) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleUnlock(result: result)
            }
        }
    }

    func handleUnlock(result: UserWalletRepositoryResult?) {
        if result?.isSuccess != true {
            incomingActionManager.discardIncomingAction()
        }

        guard let result else { return }

        switch result {
        case .success(let model), .partial(let model, _):
            openMain(with: model)
        case .error(let error):
            handleUnlock(resultError: error)
        case .troubleshooting:
            openTroubleshooting()
        case .onboarding(let input):
            openOnboarding(with: input)
        }
    }

    func handleUnlock(resultError: Error) {
        switch state {
        case .locked:
            state = makeUnlockedState()
        case .unlocked:
            if resultError.isCancellationError {
                return
            }
            error = resultError.alertBinder
        case .none:
            break
        }
    }

    func unlockWithCardTryAgain() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .signIn])
        unlockWithCard()
    }
}

// MARK: - Navigation

private extension NewAuthViewModel {
    func openMain(with model: UserWalletModel) {
        coordinator?.openMain(with: model)
    }

    func openAddWallet() {
        let sheet = ActionSheet(
            title: Text("Add Wallet"),
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

    func openHotAccessCode(userWalletId: UserWalletId) {
        coordinator?.openHotAccessCode(with: userWalletId)
    }

    func openOnboarding(with input: OnboardingInput) {
        coordinator?.openOnboarding(with: input)
    }

    func openTroubleshooting() {
        let sheet = ActionSheet(
            title: Text(Localization.alertTroubleshootingScanCardTitle),
            message: Text(Localization.alertTroubleshootingScanCardMessage),
            buttons: [
                .default(
                    Text(Localization.alertButtonTryAgain),
                    action: weakify(self, forFunction: NewAuthViewModel.unlockWithCardTryAgain)
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
