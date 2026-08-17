//
//  MobileBackupTypesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization
import TangemMobileWalletSdk
import TangemMobileWalletBackup

final class MobileBackupTypesViewModel: ObservableObject {
    @Published var sections: [Section] = []

    let navTitle = Localization.commonBackup

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private let userWalletModel: UserWalletModel
    private let mode: MobileBackupTypesMode
    private weak var coordinator: MobileBackupTypesRoutable?

    init(userWalletModel: UserWalletModel, mode: MobileBackupTypesMode, coordinator: MobileBackupTypesRoutable) {
        self.userWalletModel = userWalletModel
        self.mode = mode
        self.coordinator = coordinator
        sections = makeSections()
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
    func makeSections() -> [Section] {
        switch mode {
        case .activate: makeActivateSections()
        case .backup: makeBackupSections()
        }
    }

    func makeBackupSections() -> [Section] {
        let commonSection = Section(
            title: nil,
            items: [makeSeedBackupItem(), makeICloudBackupItem()]
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
            items: [makeSeedBackupItem(), makeICloudBackupItem()]
        )
        return [commonSection, otherMethodsSection]
    }

    func makeSeedBackupItem() -> SectionItem {
        let viewModel = MobileBackupSeedPhraseTypeViewModel(
            userWalletModel: userWalletModel,
            delegate: self
        )
        return .seedPhrase(viewModel)
    }

    func makeUpgradeItem() -> SectionItem {
        let viewModel = MobileBackupUpgradeTypeViewModel(
            userWalletModel: userWalletModel,
            delegate: self
        )
        return .upgrade(viewModel)
    }

    func makeICloudBackupItem() -> SectionItem {
        let viewModel = MobileBackupICloudTypeViewModel(
            userWalletModel: userWalletModel,
            delegate: self
        )
        return .iCloud(viewModel)
    }
}

// MARK: - MobileBackupSeedPhraseTypeDelegate

extension MobileBackupTypesViewModel: MobileBackupSeedPhraseTypeDelegate {
    func onSeedPhraseBackup() async {
        await openSeedPhraseBackup()
    }

    func onSeedPhraseReveal(context: MobileWalletContext) async {
        await openSeedPhraseReveal(context: context)
    }
}

// MARK: - MobileBackupICloudTypeDelegate

extension MobileBackupTypesViewModel: MobileBackupICloudTypeDelegate {
    func onICloudBackup() async {
        await openICloudBackup()
    }

    func onICloudBackupDetails(backup: MobileWalletBackup, onDelete: @escaping () -> Void) async {
        await openICloudBackupDetails(backup: backup, onDelete: onDelete)
    }
}

// MARK: - MobileBackupUpgradeTypeDelegate

extension MobileBackupTypesViewModel: MobileBackupUpgradeTypeDelegate {
    func onUpgradeTap() async {
        await openUpgrade()
    }
}

// MARK: - Navigation

@MainActor
private extension MobileBackupTypesViewModel {
    func openUpgrade() {
        coordinator?.openMobileUpgrade(userWalletModel: userWalletModel)
    }

    func openICloudBackup() {
        let input = MobileOnboardingInput(flow: .iCloudBackup(
            userWalletModel: userWalletModel,
            source: .backup(action: .backup)
        ))
        coordinator?.openMobileOnboarding(input: input)
    }

    func openICloudBackupDetails(backup: MobileWalletBackup, onDelete: @escaping () -> Void) {
        coordinator?.openMobileBackupICloudDetails(
            backup: backup,
            userWalletModel: userWalletModel,
            onDelete: onDelete
        )
    }

    func openSeedPhraseBackup() {
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
}

// MARK: - Analytics

private extension MobileBackupTypesViewModel {
    func logScreenOpenedAnalytics() {
        let hasSeedPhraseBackup = !userWalletModel.config.hasFeature(.mnemonicBackup)
        let hasICloudBackup = !userWalletModel.config.hasFeature(.iCloudBackup)

        Analytics.log(
            .walletSettingsBackupScreenOpened,
            params: [
                .backupManual: .affirmativeOrNegative(for: hasSeedPhraseBackup),
                .backupCloud: hasICloudBackup ? .done : .incomplete,
            ],
            contextParams: analyticsContextParams
        )
    }
}

// MARK: - Types

extension MobileBackupTypesViewModel {
    struct Section {
        let title: String?
        let items: [SectionItem]
    }

    enum SectionItem {
        case seedPhrase(MobileBackupSeedPhraseTypeViewModel)
        case iCloud(MobileBackupICloudTypeViewModel)
        case upgrade(MobileBackupUpgradeTypeViewModel)
    }
}
