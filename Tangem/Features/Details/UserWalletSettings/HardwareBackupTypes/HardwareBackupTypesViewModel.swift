//
//  HardwareBackupTypesViewModel.swift
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
import TangemMobileWalletSdk

final class HardwareBackupTypesViewModel: ObservableObject {
    @Published var isBuyAvailable = false
    @Published var alert: AlertBinder?

    let navigationTitle = Localization.hwBackupHardwareTitle

    lazy var backupItems: [BackupItem] = makeBackupItems()
    lazy var buyItem: BuyItem = makeBuyItem()

    @Injected(\.safariManager) private var safariManager: SafariManager

    private var isBackupNeeded: Bool {
        userWalletModel.config.hasFeature(.mnemonicBackup) && userWalletModel.config.hasFeature(.iCloudBackup)
    }

    private let userWalletModel: UserWalletModel
    private weak var coordinator: HardwareBackupTypesRoutable?

    init(userWalletModel: UserWalletModel, coordinator: HardwareBackupTypesRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension HardwareBackupTypesViewModel {
    func onAppear() {
        scheduleBuyAvailability()
    }
}

// MARK: - Private methods

private extension HardwareBackupTypesViewModel {
    func makeBackupItems() -> [BackupItem] {
        let createWalletItem = BackupItem(
            title: Localization.hwBackupHardwareCreateTitle,
            description: Localization.hwBackupHardwareCreateDescription,
            badge: .recommended,
            action: weakify(self, forFunction: HardwareBackupTypesViewModel.onCreateWalletTap)
        )

        let upgradeWalletItem = BackupItem(
            title: Localization.hwBackupHardwareUpgradeTitle,
            description: Localization.hwBackupHardwareUpgradeDescription,
            badge: nil,
            action: weakify(self, forFunction: HardwareBackupTypesViewModel.onUpgradeWalletTap)
        )

        return [createWalletItem, upgradeWalletItem]
    }

    func onCreateWalletTap() {
        runTask(in: self) { viewModel in
            await viewModel.openCreateHardwareWallet()
        }
    }

    func onUpgradeWalletTap() {
        runTask(in: self) { viewModel in
            if viewModel.isBackupNeeded {
                await viewModel.openMobileBackupNeeded()
            } else {
                await viewModel.upgradeMobileWallet()
            }
        }
    }

    func upgradeMobileWallet() async {
        let unlockResult = await mobileUnlock()

        switch unlockResult {
        case .successful(let context):
            await openUpgradeToHardwareWallet(context: context)
        case .canceled:
            break
        case .failed(let error):
            alert = error.alertBinder
        }
    }

    func makeBuyItem() -> BuyItem {
        BuyItem(
            title: Localization.walletAddHardwarePurchase,
            buttonTitle: Localization.walletImportBuyTitle,
            buttonAction: weakify(self, forFunction: HardwareBackupTypesViewModel.onBuyTap)
        )
    }

    func onBuyTap() {
        runTask(in: self) { viewModel in
            await viewModel.openBuyHardwareWallet()
        }
    }

    func onBackupToUpgradeComplete() {
        runTask(in: self) { viewModel in
            await viewModel.closeOnboarding()
            await viewModel.upgradeMobileWallet()
        }
    }

    func scheduleBuyAvailability() {
        guard !isBuyAvailable else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.isBuyAvailable = true
        }
    }
}

// MARK: - Mobile wallet unlocking

private extension HardwareBackupTypesViewModel {
    func mobileUnlock() async -> MobileUnlockResult {
        do {
            let authUtil = MobileAuthUtil(
                userWalletId: userWalletModel.userWalletId,
                config: userWalletModel.config,
                biometricsProvider: CommonUserWalletBiometricsProvider()
            )
            let result = try await authUtil.unlock()

            switch result {
            case .successful(let context):
                return .successful(context: context)

            case .canceled:
                return .canceled

            case .userWalletNeedsToDelete:
                assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
                return .canceled
            }

        } catch {
            return .failed(error: error)
        }
    }

    enum MobileUnlockResult {
        case successful(context: MobileWalletContext)
        case canceled
        case failed(error: Error)
    }
}

// MARK: - Navigation

@MainActor
private extension HardwareBackupTypesViewModel {
    func openCreateHardwareWallet() {
        coordinator?.openCreateHardwareWallet()
    }

    func openMobileBackupNeeded() {
        coordinator?.openMobileBackupToUpgradeNeeded(
            onBackupRequested: weakify(self, forFunction: HardwareBackupTypesViewModel.openBackupMobileWallet)
        )
    }

    func openBackupMobileWallet() {
        let input = MobileOnboardingInput(flow: .seedPhraseBackupToUpgrade(
            userWalletModel: userWalletModel,
            onContinue: weakify(self, forFunction: HardwareBackupTypesViewModel.onBackupToUpgradeComplete)
        ))
        coordinator?.openMobileOnboarding(input: input)
    }

    func openUpgradeToHardwareWallet(context: MobileWalletContext) {
        coordinator?.openUpgradeToHardwareWallet(userWalletModel: userWalletModel, context: context)
    }

    func openBuyHardwareWallet() {
        Analytics.log(.onboardingButtonBuy, params: [.source: .backup])
        safariManager.openURL(TangemBlogUrlBuilder().url(root: .pricing))
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - Types

extension HardwareBackupTypesViewModel {
    struct BackupItem: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let badge: BadgeView.Item?
        let action: () -> Void
    }

    struct BuyItem {
        let title: String
        let buttonTitle: String
        let buttonAction: () -> Void
    }
}
