//
//  CardSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class CardSettingsViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: ViewState

    @Published var hasSingleSecurityMode: Bool = false
    @Published var isChangeAccessCodeVisible: Bool = false
    @Published var securityModeTitle: String
    @Published var alert: AlertBinder?
    @Published var isChangeAccessCodeLoading: Bool = false

    @Published var cardInfoSection: [DefaultRowViewModel] = []
    @Published var securityModeSection: [DefaultRowViewModel] = []
    @Published var resetToFactoryViewModel: DefaultRowViewModel?

    var isResetToFactoryAvailable: Bool {
        !cardModel.resetToFactoryAvailability.isHidden
    }

    var resetToFactoryFooterMessage: String {
        if cardModel.hasBackupCards {
            return Localization.cardSettingsResetCardWithBackupFooter
        } else {
            return Localization.cardSettingsResetCardWithoutBackupFooter
        }
    }

    // MARK: Dependecies

    private unowned let coordinator: CardSettingsRoutable
    private let cardModel: CardViewModel

    // MARK: Properties

    private var bag: Set<AnyCancellable> = []
    private var shouldShowAlertOnDisableSaveAccessCodes: Bool = true

    init(
        cardModel: CardViewModel,
        coordinator: CardSettingsRoutable
    ) {
        self.cardModel = cardModel
        self.coordinator = coordinator

        securityModeTitle = cardModel.currentSecurityOption.title
        hasSingleSecurityMode = cardModel.availableSecurityOptions.count <= 1
        isChangeAccessCodeVisible = cardModel.currentSecurityOption == .accessCode

        bind()
        setupView()
    }

    func didResetCard() {
        if let userWallet = cardModel.userWallet {
            deleteWallet(userWallet)
        }

        navigateAwayAfterReset()
    }
}

// MARK: - Private

private extension CardSettingsViewModel {
    func bind() {
        cardModel.$currentSecurityOption
            .map { $0.titleForDetails }
            .sink(receiveValue: { [weak self] newMode in
                self?.securityModeTitle = newMode
                self?.setupSecurityOptions()
            })
            .store(in: &bag)
    }

    func prepareTwinOnboarding() {
        if let twinInput = cardModel.twinInput {
            let hasOtherCards = AppSettings.shared.saveUserWallets && userWalletRepository.models.count > 1
            coordinator.openOnboarding(with: twinInput, hasOtherCards: hasOtherCards)
        }
    }

    func setupView() {
        cardInfoSection = [
            DefaultRowViewModel(title: Localization.detailsRowTitleCid, detailsType: .text(cardModel.cardIdFormatted)),
            DefaultRowViewModel(title: Localization.detailsRowTitleIssuer, detailsType: .text(cardModel.cardIssuer)),
            DefaultRowViewModel(title: Localization.detailsRowTitleSignedHashes,
                                detailsType: .text(Localization.detailsRowSubtitleSignedHashesFormat("\(cardModel.cardSignedHashes)"))),
        ]

        setupSecurityOptions()

        if isResetToFactoryAvailable {
            resetToFactoryViewModel = DefaultRowViewModel(
                title: Localization.cardSettingsResetCardToFactory,
                action: openResetCard
            )
        }
    }

    private func setupSecurityOptions() {
        securityModeSection = [DefaultRowViewModel(
            title: Localization.cardSettingsSecurityMode,
            detailsType: .text(securityModeTitle),
            action: hasSingleSecurityMode ? nil : openSecurityMode
        )]

        if isChangeAccessCodeVisible {
            securityModeSection.append(
                DefaultRowViewModel(
                    title: Localization.cardSettingsChangeAccessCode,
                    detailsType: isChangeAccessCodeLoading ? .loader : .none,
                    action: openChangeAccessCodeWarningView
                )
            )
        }
    }

    private func deleteWallet(_ userWallet: UserWallet) {
        self.userWalletRepository.delete(userWallet)
    }

    private func navigateAwayAfterReset() {
        if userWalletRepository.isEmpty {
            coordinator.popToRoot()
        } else {
            coordinator.dismiss()
        }
    }
}

// MARK: - Navigation

extension CardSettingsViewModel {
    func openChangeAccessCodeWarningView() {
        Analytics.log(.buttonChangeUserCode)
        isChangeAccessCodeLoading = true
        setupSecurityOptions()
        cardModel.changeSecurityOption(.accessCode) { [weak self] result in
            DispatchQueue.main.async {
                self?.isChangeAccessCodeLoading = false
                self?.setupSecurityOptions()
            }
        }
    }

    func openSecurityMode() {
        Analytics.log(.buttonChangeSecurityMode)
        coordinator.openSecurityMode(cardModel: cardModel)
    }

    func openResetCard() {
        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .resetToFactory) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if cardModel.canTwin {
            prepareTwinOnboarding()
        } else {
            coordinator.openResetCardToFactoryWarning(cardModel: cardModel)
        }
    }
}
