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
            return makeWalletsState()
        }
    }

    func setupWalletsState() {
        state = makeWalletsState()
    }

    func makeDefaultState() -> State {
        return .locked
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

        let wallets = makeWalletItems()

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
}

// MARK: - Helpers

private extension NewAuthViewModel {
    func makeWalletItems() -> [WalletItem] {
        userWalletRepository.models.map(makeWalletItem)
    }

    func makeWalletItem(userWalletModel: UserWalletModel) -> WalletItem {
        let description = walletItemDescription(userWalletModel: userWalletModel)
        let action = walletItemAction(userWalletModel: userWalletModel)
        let statusUtil = HotStatusUtil(userWalletModel: userWalletModel)
        return WalletItem(
            title: userWalletModel.name,
            description: description,
            imageProvider: userWalletModel.walletImageProvider,
            isSecured: statusUtil.isAccessCodeSet,
            action: action
        )
    }

    func walletItemDescription(userWalletModel: UserWalletModel) -> String {
        let statusUtil = HotStatusUtil(userWalletModel: userWalletModel)

        if statusUtil.isUserWalletHot {
            return "Phone Wallet"
        } else {
            let cardsCount = userWalletModel.config.cardsCount
            return "\(cardsCount) cards"
        }
    }

    func walletItemAction(userWalletModel: UserWalletModel) -> WalletItemAction {
        let statusUtil = HotStatusUtil(userWalletModel: userWalletModel)

        if statusUtil.isUserWalletHot {
            if statusUtil.isAccessCodeSet {
                return { [weak self] in
                    self?.openHotAccessCode(userWalletModel: userWalletModel)
                }
            } else {
                return { [weak self] in
                    self?.openMain(with: userWalletModel)
                }
            }
        } else {
            return { [weak self] in
                self?.unlockWithCard(userWalletModel: userWalletModel)
            }
        }
    }

    /// Check if there are only unsecure hot wallets, meaning there are no secure hot wallets or any cold wallets.
    func haveOnlyUnsecureHotWallets() -> Bool {
        let coldUserWallets = userWalletRepository.models.filter {
            let statusUtil = HotStatusUtil(userWalletModel: $0)
            return !statusUtil.isUserWalletHot
        }

        guard coldUserWallets.isEmpty else {
            return false
        }

        let secureUserWallets = userWalletRepository.models.filter {
            let statusUtil = HotStatusUtil(userWalletModel: $0)
            return statusUtil.isAccessCodeSet
        }

        return secureUserWallets.isEmpty
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
                let userWalletModel = try viewModel.userWalletRepository.unlock(with: .biometrics(context))

                await runOnMain {
                    viewModel.openMain(with: userWalletModel)
                }
            } catch {
                viewModel.incomingActionManager.discardIncomingAction()
                await runOnMain {
                    viewModel.setupWalletsState()
                }
            }
        }
    }

    func unlockWithCard(userWalletModel: UserWalletModel) {
        isScanning = true
        Analytics.beginLoggingCardScan(source: .auth)

        runTask(in: self) { viewModel in
            let cardScanner = CardScannerFactory().makeDefaultScanner()
            let userWalletCardScanner = UserWalletCardScanner(scanner: cardScanner)

            let result = await userWalletCardScanner.scanCard()
            await runOnMain {
                viewModel.handleUnlockWithCard(result: result, userWalletModel: userWalletModel)
            }
        }
    }

    func handleUnlockWithCard(result: UserWalletCardScanner.Result, userWalletModel: UserWalletModel) {
        isScanning = false

        switch result {
        case .scanTroubleshooting:
            Analytics.log(.cantScanTheCard, params: [.source: .signIn])
            incomingActionManager.discardIncomingAction()
            openTroubleshooting(userWalletModel: userWalletModel)

        case .onboarding:
            // [REDACTED_TODO_COMMENT]
            incomingActionManager.discardIncomingAction()

        case .error(let error) where error.isCancellationError:
            incomingActionManager.discardIncomingAction()

        case .error(let error):
            Analytics.logScanError(error, source: .signIn)
            Analytics.logVisaCardScanErrorIfNeeded(error, source: .signIn)
            incomingActionManager.discardIncomingAction()
            self.error = error.alertBinder

        case .success(let cardInfo):
            do {
                try userWalletRepository.unlock(userWalletId: userWalletModel.userWalletId, method: .card(cardInfo))
                openMain(with: userWalletModel)
            } catch {
                incomingActionManager.discardIncomingAction()
                self.error = error.alertBinder
            }
        }
    }

    func unlockWithCardTryAgain(userWalletModel: UserWalletModel) {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .signIn])
        unlockWithCard(userWalletModel: userWalletModel)
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
        let isSecured: Bool
        let action: WalletItemAction
    }

    typealias WalletItemAction = () -> Void

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
