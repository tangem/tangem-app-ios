//
//  MobileBackupTypesViewModel.swift
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
import TangemAssets
import class TangemSdk.BiometricsUtil

final class MobileBackupTypesViewModel: ObservableObject {
    @Published var sections: [Section] = []
    @Published var alert: AlertBinder?

    let navTitle = Localization.commonBackup

    @Injected(\.safariManager) private var safariManager: SafariManager

    private var isBackupNeeded: Bool {
        userWalletModel.config.hasFeature(.mnemonicBackup)
    }

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private lazy var mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let userWalletModel: UserWalletModel
    private let mode: MobileBackupTypesMode
    private weak var coordinator: MobileBackupTypesRoutable?

    private var bag: Set<AnyCancellable> = []

    init(userWalletModel: UserWalletModel, mode: MobileBackupTypesMode, coordinator: MobileBackupTypesRoutable) {
        self.userWalletModel = userWalletModel
        self.mode = mode
        self.coordinator = coordinator
        setup()
        bind()
    }
}

// MARK: - Internal methods

extension MobileBackupTypesViewModel {
    func onFirstAppear() {
        logScreenOpenedAnalytics()
    }
}

// MARK: - Private methods

private extension MobileBackupTypesViewModel {
    func setup() {
        runTask(in: self) { @MainActor viewModel in
            viewModel.sections = viewModel.makeSections()
        }
    }

    func bind() {
        userWalletModel.updatePublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                viewModel.handleUpdate(result: result)
            }
            .store(in: &bag)
    }

    func handleUpdate(result: UpdateResult) {
        switch result {
        case .configurationChanged:
            setup()
        case .nameDidChange, .tangemPayOfferAccepted, .tangemPayKYCDeclined:
            break
        }
    }
}

// MARK: - Helpers

private extension MobileBackupTypesViewModel {
    func makeSections() -> [Section] {
        switch mode {
        case .activate: makeActivateSections()
        case .backup: makeBackupSections()
        }
    }

    func makeBackupSections() -> [Section] {
        let commonSection = Section(
            title: nil,
            items: [makeActivationItem(), makeICloudItem()]
        )
        return [commonSection]
    }

    func makeActivateSections() -> [Section] {
        let commonSection = Section(
            title: nil,
            items: [makeUpgradeItem()]
        )
        let otherMethodsSection = Section(
            title: Localization.hwBackupSectionOtherTitle,
            items: [makeActivationItem(), makeICloudItem()]
        )
        return [commonSection, otherMethodsSection]
    }

    func makeActivationItem() -> SectionItem {
        let badge: BadgeView.Item = if isBackupNeeded {
            .noBackup
        } else {
            .done
        }

        let action = weakify(self, forFunction: MobileBackupTypesViewModel.onActivationTap)

        return SectionItem(
            title: Localization.hwBackupSeedTitle,
            description: Localization.hwBackupSeedDescription,
            badge: badge,
            isEnabled: true,
            action: action
        )
    }

    func makeUpgradeItem() -> SectionItem {
        let badge = BadgeView.Item(title: Localization.commonRecommended, style: .accent)
        let action = weakify(self, forFunction: MobileBackupTypesViewModel.onUpgradeTap)
        return SectionItem(
            title: Localization.hwBackupUpgradeTitle,
            description: Localization.hwBackupUpgradeDescription,
            badge: badge,
            isEnabled: true,
            action: action
        )
    }

    func makeICloudItem() -> SectionItem {
        let badge = BadgeView.Item(title: Localization.commonComingSoon, style: .secondary)
        return SectionItem(
            title: Localization.hwBackupIcloudTitle,
            description: Localization.hwBackupIcloudDescription,
            badge: badge,
            isEnabled: false,
            action: {}
        )
    }

    func onActivationTap() {
        logRecoveryPhraseTapAnalytics()

        runTask(in: self) { viewModel in
            if viewModel.isBackupNeeded {
                await viewModel.openActivation()
            } else {
                await viewModel.handleSeedPhraseReveal()
            }
        }
    }

    func handleSeedPhraseReveal() async {
        do {
            let context = try await unlock()
            await openSeedPhraseReveal(context: context)
        } catch where error.isCancellationError {
            AppLogger.error("Unlock is canceled", error: error)
        } catch {
            AppLogger.error("Unlock failed:", error: error)
            await runOnMain {
                alert = error.alertBinder
            }
        }
    }

    func onUpgradeTap() {
        logUpgradeTapAnalytics()
        runTask(in: self) { viewModel in
            await viewModel.openUpgrade()
        }
    }
}

// MARK: - Unlocking

private extension MobileBackupTypesViewModel {
    func unlock() async throws -> MobileWalletContext {
        let authUtil = MobileAuthUtil(
            userWalletId: userWalletModel.userWalletId,
            config: userWalletModel.config,
            biometricsProvider: CommonUserWalletBiometricsProvider()
        )
        let result = try await authUtil.unlock()

        switch result {
        case .successful(let context):
            return context

        case .canceled:
            throw CancellationError()

        case .userWalletNeedsToDelete:
            assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
            throw CancellationError()
        }
    }
}

// MARK: - Navigation

@MainActor
private extension MobileBackupTypesViewModel {
    func openUpgrade() {
        coordinator?.openMobileUpgrade(userWalletModel: userWalletModel)
    }

    func openActivation() {
        let input = MobileOnboardingInput(flow: .walletActivate(
            userWalletModel: userWalletModel,
            source: .backup(action: .backup)
        ))
        coordinator?.openMobileOnboarding(input: input)
    }

    func openSeedPhraseReveal(context: MobileWalletContext) {
        let input = MobileOnboardingInput(flow: .seedPhraseReveal(context: context))
        coordinator?.openMobileOnboarding(input: input)
    }

    func openBuyHardwareWallet() {
        logBuyHardwareWalletAnalytics()
        safariManager.openURL(TangemShopUrlBuilder().url(utmCampaign: .backup))
    }
}

// MARK: - Analytics

private extension MobileBackupTypesViewModel {
    func logScreenOpenedAnalytics() {
        let hasManualBackup = !userWalletModel.config.hasFeature(.mnemonicBackup)

        Analytics.log(
            .walletSettingsBackupScreenOpened,
            params: [.backupManual: .affirmativeOrNegative(for: hasManualBackup)],
            contextParams: analyticsContextParams
        )
    }

    func logUpgradeTapAnalytics() {
        Analytics.log(.walletSettingsButtonHardwareUpdate, contextParams: analyticsContextParams)
    }

    func logRecoveryPhraseTapAnalytics() {
        Analytics.log(.walletSettingsButtonRecoveryPhrase, contextParams: analyticsContextParams)
    }

    func logBuyHardwareWalletAnalytics() {
        Analytics.log(
            .basicButtonBuy,
            params: [.source: Analytics.BuyWalletSource.backup.parameterValue],
            contextParams: analyticsContextParams
        )
    }
}

// MARK: - Types

extension MobileBackupTypesViewModel {
    struct Section: Identifiable {
        let id = UUID()
        let title: String?
        let items: [SectionItem]
    }

    struct SectionItem: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let badge: BadgeView.Item?
        let isEnabled: Bool
        let action: () -> Void
    }
}
