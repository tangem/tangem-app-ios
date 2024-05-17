//
//  UserWalletSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class UserWalletSettingsViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - ViewState

    @Published var name: String
    @Published var walletConnectRowViewModel: WalletConnectRowViewModel?
    @Published var backupViewModel: DefaultRowViewModel?
    @Published var forgetViewModel: DefaultRowViewModel?
    @Published var commonSectionModels: [DefaultRowViewModel] = []

    @Published var alert: AlertBinder?
    @Published var actionSheet: ActionSheetBinder?

    // MARK: - Dependencies

    private let userWalletModel: UserWalletModel
    private weak var coordinator: UserWalletSettingsRoutable?
    private var bag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        coordinator: UserWalletSettingsRoutable
    ) {
        name = userWalletModel.name

        self.userWalletModel = userWalletModel
        self.coordinator = coordinator

        bind()
    }

    func onAppear() {
        setupView()
    }
}

// MARK: - Private

private extension WalletDetailsViewModel {
    func setupView() {
        setupWalletConnectRowViewModel()
        setupCommonSection()
        // setupAccountsSection()
        setupBackupViewModel()
        setupForgetViewModel()
    }

    func setupWalletConnectRowViewModel() {
        guard !userWalletModel.config.getFeatureAvailability(.walletConnect).isHidden else {
            walletConnectRowViewModel = nil
            return
        }

        walletConnectRowViewModel = WalletConnectRowViewModel(
            title: Localization.walletConnectTitle,
            subtitle: Localization.walletConnectSubtitle,
            action: weakify(self, forFunction: WalletDetailsViewModel.openWalletConnect)
        )
    }

    func setupAccountsSection() {
        // [REDACTED_TODO_COMMENT]
    }

    func setupCommonSection() {
        var viewModels: [DefaultRowViewModel] = []

        viewModels.append(DefaultRowViewModel(
            title: Localization.cardSettingsTitle,
            action: weakify(self, forFunction: WalletDetailsViewModel.openCardSettings)
        ))

        if !userWalletModel.config.getFeatureAvailability(.referralProgram).isHidden {
            viewModels.append(
                DefaultRowViewModel(
                    title: Localization.detailsReferralTitle,
                    action: weakify(self, forFunction: WalletDetailsViewModel.openReferral)
                )
            )
        }

        viewModels.append(
            DefaultRowViewModel(
                title: Localization.disclaimerTitle,
                action: weakify(self, forFunction: WalletDetailsViewModel.openDisclaimer)
            )
        )

        commonSectionModels = viewModels
    }

    func setupBackupViewModel() {
        guard !userWalletModel.config.getFeatureAvailability(.backup).isHidden else {
            backupViewModel = nil
            return
        }

        backupViewModel = DefaultRowViewModel(
            title: Localization.detailsRowTitleCreateBackup,
            action: weakify(self, forFunction: WalletDetailsViewModel.prepareBackup)
        )
    }

    func setupForgetViewModel() {
        forgetViewModel = DefaultRowViewModel(
            title: "Forget wallet",
            action: weakify(self, forFunction: WalletDetailsViewModel.didTapDeleteWallet)
        )
    }

    // MARK: - Actions

    func prepareBackup() {
        Analytics.log(.buttonCreateBackup)
        if let backupInput = userWalletModel.backupInput {
            openOnboarding(with: backupInput)
        }
    }

    func didTapDeleteWallet() {
        Analytics.log(.buttonDeleteWalletTapped)

        let sheet = ActionSheet(
            title: Text(Localization.userWalletListDeletePrompt),
            buttons: [
                .destructive(
                    Text(Localization.commonDelete),
                    action: weakify(self, forFunction: WalletDetailsViewModel.didConfirmWalletDeletion)
                ),
                .cancel(Text(Localization.commonCancel)),
            ]
        )
        actionSheet = ActionSheetBinder(sheet: sheet)
    }

    func didConfirmWalletDeletion() {
        guard let userWalletModel = userWalletRepository.selectedModel else {
            return
        }

        userWalletRepository.delete(userWalletModel.userWalletId, logoutIfNeeded: true)
    }

    func bind() {
        $name
            .debounce(for: 0.5, scheduler: DispatchQueue.global())
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, name in
                viewModel.userWalletModel.updateWalletName(name.trimmed())
            })
            .store(in: &bag)
    }
}

// MARK: - Navigation

private extension WalletDetailsViewModel {
    func openOnboarding(with input: OnboardingInput) {
        coordinator?.openOnboardingModal(with: input)
    }

    func openWalletConnect() {
        Analytics.log(.buttonWalletConnect)
        coordinator?.openWalletConnect(with: userWalletModel.config.getDisabledLocalizedReason(for: .walletConnect))
    }

    func openCardSettings() {
        Analytics.log(.buttonCardSettings)

        let scanParameters = CardScannerParameters(
            shouldAskForAccessCodes: true,
            performDerivations: false,
            sessionFilter: userWalletModel.config.cardSessionFilter
        )

        let scanner = CardScannerFactory().makeScanner(
            with: userWalletModel.config.makeTangemSdk(),
            parameters: scanParameters
        )

        coordinator?.openScanCardSettings(with: scanner)
    }

    func openDisclaimer() {
        coordinator?.openDisclaimer(at: userWalletModel.config.tou.url)
    }

    func openReferral() {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .referralProgram) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        let input = ReferralInputModel(
            userWalletId: userWalletModel.userWalletId.value,
            supportedBlockchains: userWalletModel.config.supportedBlockchains,
            userTokensManager: userWalletModel.userTokensManager
        )

        coordinator?.openReferral(input: input)
    }
}
