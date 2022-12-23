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

    @Published var hasSingleSecurityMode: Bool
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
            return Localization.resetCardWithBackupToFactoryMessage
        } else {
            return Localization.resetCardWithoutBackupToFactoryMessage
        }
    }

    var securityModeFooterMessage: String {
        if isChangeAccessCodeVisible {
            return Localization.cardSettingsChangeAccessCodeFooter
        }

        return cardModel.currentSecurityOption.description
    }

    // MARK: Properties

    private unowned let coordinator: CardSettingsRoutable
    private let cardModel: CardViewModel
    private var isChangeAccessCodeVisible: Bool {
        cardModel.currentSecurityOption == .accessCode
    }
    private var bag: Set<AnyCancellable> = []

    init(
        cardModel: CardViewModel,
        coordinator: CardSettingsRoutable
    ) {
        self.cardModel = cardModel
        self.coordinator = coordinator

        securityModeTitle = cardModel.currentSecurityOption.title
        hasSingleSecurityMode = cardModel.availableSecurityOptions.count <= 1

        bind()
        setupView()
    }
}

// MARK: - Private

private extension CardSettingsViewModel {
    func bind() {
        cardModel.$currentSecurityOption
            .receiveValue { [weak self] newMode in
                self?.securityModeTitle = newMode.titleForDetails
                self?.setupSecurityOptions()
            }
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

    func setupSecurityOptions() {
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

    func deleteWallet(_ userWallet: UserWallet) {
        self.userWalletRepository.delete(userWallet)
    }

    func navigateAwayAfterReset() {
        if self.userWalletRepository.isEmpty {
            self.coordinator.popToRoot()
        } else {
            self.coordinator.dismiss()
        }
    }

    func didResetCard(with userWallet: UserWallet) {
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
