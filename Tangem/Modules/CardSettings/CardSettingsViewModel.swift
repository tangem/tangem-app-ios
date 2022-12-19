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

    var resetToFactoryMessage: String {
        if cardModel.hasBackupCards {
            return "reset_card_with_backup_to_factory_message".localized
        } else {
            return "reset_card_without_backup_to_factory_message".localized
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
            DefaultRowViewModel(title: "details_row_title_cid".localized, detailsType: .text(cardModel.cardIdFormatted)),
            DefaultRowViewModel(title: "details_row_title_issuer".localized, detailsType: .text(cardModel.cardIssuer)),
            DefaultRowViewModel(title: "details_row_title_signed_hashes".localized,
                                detailsType: .text("details_row_subtitle_signed_hashes_format".localized("\(cardModel.cardSignedHashes)"))),
        ]

        setupSecurityOptions()

        if isResetToFactoryAvailable {
            resetToFactoryViewModel = DefaultRowViewModel(
                title: "card_settings_reset_card_to_factory".localized,
                action: openResetCard
            )
        }
    }

    private func setupSecurityOptions() {
        securityModeSection = [DefaultRowViewModel(
            title: "card_settings_security_mode".localized,
            detailsType: .text(securityModeTitle),
            action: hasSingleSecurityMode ? nil : openSecurityMode
        )]

        if isChangeAccessCodeVisible {
            securityModeSection.append(
                DefaultRowViewModel(
                    title: "card_settings_change_access_code".localized,
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
        if self.userWalletRepository.isEmpty {
            self.coordinator.popToRoot()
        } else {
            self.coordinator.dismiss()
        }
    }

    private func didResetCard(with userWallet: UserWallet) {
        deleteWallet(userWallet)
        navigateAwayAfterReset()
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

        let userWallet = cardModel.userWallet

        if cardModel.canTwin {
            prepareTwinOnboarding()
        } else {
            coordinator.openResetCardToFactoryWarning(message: resetToFactoryMessage) { [weak self] in
                self?.cardModel.resetToFactory { [weak self] result in
                    guard let self, let userWallet else { return }

                    switch result {
                    case .success:
                        self.didResetCard(with: userWallet)
                    case let .failure(error):
                        if !error.isUserCancelled {
                            self.alert = error.alertBinder
                        }
                    }
                }
            }
        }
    }
}
