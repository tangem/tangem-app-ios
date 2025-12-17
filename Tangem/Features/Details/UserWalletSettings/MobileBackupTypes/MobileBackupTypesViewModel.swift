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

    lazy var infoItem: InfoItem = makeInfoItem()

    @Injected(\.safariManager) private var safariManager: SafariManager

    private var isBackupNeeded: Bool {
        userWalletModel.config.hasFeature(.mnemonicBackup)
    }

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private lazy var mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let userWalletModel: UserWalletModel
    private weak var coordinator: MobileBackupTypesRoutable?

    private var bag: Set<AnyCancellable> = []

    init(userWalletModel: UserWalletModel, coordinator: MobileBackupTypesRoutable) {
        self.userWalletModel = userWalletModel
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
        sections = makeSections()
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
        case .nameDidChange, .tangemPayOfferAccepted:
            break
        }
    }
}

// MARK: - Helpers

private extension MobileBackupTypesViewModel {
    func makeSections() -> [Section] {
        let commonSection = Section(title: nil, items: makeCommonSectionItems())
        let otherMethodsSection = Section(title: Localization.hwBackupSectionOtherTitle, items: makeOtherMethodsSectionItems())
        return [commonSection, otherMethodsSection]
    }

    func makeCommonSectionItems() -> [SectionItem] {
        [makeHardwareItem()]
    }

    func makeOtherMethodsSectionItems() -> [SectionItem] {
        [makeSeedPhraseItem(), makeICloudItem()]
    }

    func makeSeedPhraseItem() -> SectionItem {
        let badge: BadgeView.Item = if isBackupNeeded {
            .noBackup
        } else {
            .done
        }

        let action = weakify(self, forFunction: MobileBackupTypesViewModel.onSeedPhraseBackupTap)

        return SectionItem(
            title: Localization.hwBackupSeedTitle,
            description: Localization.hwBackupSeedDescription,
            badge: badge,
            isEnabled: true,
            action: action
        )
    }

    func makeHardwareItem() -> SectionItem {
        let badge = BadgeView.Item(title: Localization.commonRecommended, style: .accent)
        let action = weakify(self, forFunction: MobileBackupTypesViewModel.onHardwareBackupTap)
        return SectionItem(
            title: Localization.hwBackupHardwareTitle,
            description: Localization.hwBackupHardwareDescription,
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

    func makeInfoItem() -> InfoItem {
        let action = InfoActionItem(
            title: Localization.detailsBuyWallet,
            handler: weakify(self, forFunction: MobileBackupTypesViewModel.onInfoTap)
        )

        let chips: [InfoChipItem] = [
            InfoChipItem(icon: Assets.Glyphs.checkmarkShield, title: Localization.welcomeCreateWalletFeatureClass),
            InfoChipItem(icon: Assets.Glyphs.boldFlash, title: Localization.welcomeCreateWalletFeatureDelivery),
            InfoChipItem(icon: Assets.Glyphs.sparkles, title: Localization.welcomeCreateWalletFeatureUse),
        ]

        return InfoItem(
            title: Localization.commonTangemWallet,
            description: Localization.hwBackupBannerDescription,
            icon: Assets.Onboarding.tangemVerticalCardSet,
            chips: chips,
            action: action
        )
    }

    func onSeedPhraseBackupTap() {
        logRecoveryPhraseTapAnalytics()

        runTask(in: self) { viewModel in
            if viewModel.isBackupNeeded {
                await viewModel.openSeedPhraseBackup()
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

    func onHardwareBackupTap() {
        logHardwareBackupTapAnalytics()
        runTask(in: self) { viewModel in
            await viewModel.openHardwareBackup()
        }
    }

    func onInfoTap() {
        runTask(in: self) { viewModel in
            await viewModel.openBuyHardwareWallet()
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
    func openHardwareBackup() {
        coordinator?.openHardwareBackupTypes(userWalletModel: userWalletModel)
    }

    func openSeedPhraseBackup() {
        let input = MobileOnboardingInput(flow: .seedPhraseBackup(
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

    func logHardwareBackupTapAnalytics() {
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

    struct InfoItem {
        let title: String
        let description: String
        let icon: ImageType
        let chips: [InfoChipItem]
        let action: InfoActionItem
    }

    struct InfoChipItem: Hashable {
        let icon: ImageType
        let title: String
    }

    struct InfoActionItem {
        let title: String
        let handler: () -> Void
    }
}
