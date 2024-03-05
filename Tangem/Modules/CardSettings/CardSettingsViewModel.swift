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
    // MARK: ViewState

    @Published var hasSingleSecurityMode: Bool
    @Published var securityModeTitle: String
    @Published var alert: AlertBinder?
    @Published var isChangeAccessCodeLoading: Bool = false

    @Published var cardInfoSection: [DefaultRowViewModel] = []
    @Published var securityModeSection: [DefaultRowViewModel] = []
    @Published var accessCodeRecoverySection: DefaultRowViewModel?
    @Published var resetToFactoryViewModel: DefaultRowViewModel?

    var isResetToFactoryAvailable: Bool {
        !cardModel.resetToFactoryAvailability.isHidden
    }

    var resetToFactoryFooterMessage: String {
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

        return securityOptionChangeInteractor.currentSecurityOption.description
    }

    // MARK: Dependencies

    private weak var coordinator: CardSettingsRoutable?
    private let cardModel: CardViewModel

    private let recoveryInteractor: UserCodeRecovering
    private let securityOptionChangeInteractor: SecurityOptionChanging

    // MARK: Private

    private var isChangeAccessCodeVisible: Bool {
        securityOptionChangeInteractor.currentSecurityOption == .accessCode
    }

    private var bag: Set<AnyCancellable> = []

    // [REDACTED_TODO_COMMENT]
    init(
        cardModel: CardViewModel,
        coordinator: CardSettingsRoutable
    ) {
        self.cardModel = cardModel
        self.coordinator = coordinator
        recoveryInteractor = UserCodeRecoveringCardInteractor(with: cardModel.cardInfo)
        securityOptionChangeInteractor = SecurityOptionChangingCardInteractor(with: cardModel.cardInfo)

        securityModeTitle = securityOptionChangeInteractor.currentSecurityOption.title
        hasSingleSecurityMode = securityOptionChangeInteractor.availableSecurityOptions.count <= 1

        bind()
        setupView()
    }
}

// MARK: - Private

private extension CardSettingsViewModel {
    func bind() {
        securityOptionChangeInteractor.currentSecurityOptionPublisher
            .receiveValue { [weak self] newMode in
                self?.securityModeTitle = newMode.titleForDetails
                self?.setupSecurityOptions()
            }
            .store(in: &bag)

        recoveryInteractor.isUserCodeRecoveryAllowedPublisher
            .sink { [weak self] enabled in
                self?.setupAccessCodeRecoveryModel(enabled: enabled)
            }
            .store(in: &bag)
    }

    func prepareTwinOnboarding() {
        if let twinInput = cardModel.twinInput {
            coordinator?.openOnboarding(with: twinInput)
        }
    }

    func setupView() {
        cardInfoSection = [
            DefaultRowViewModel(title: Localization.detailsRowTitleCid, detailsType: .text(cardModel.cardIdFormatted)),
            DefaultRowViewModel(title: Localization.detailsRowTitleIssuer, detailsType: .text(cardModel.cardIssuer)),
        ]

        if cardModel.canDisplayHashesCount {
            cardInfoSection.append(DefaultRowViewModel(
                title: Localization.detailsRowTitleSignedHashes,
                detailsType: .text(Localization.detailsRowSubtitleSignedHashesFormat("\(cardModel.cardSignedHashes)"))
            ))
        }

        setupSecurityOptions()
        setupAccessCodeRecoveryModel(enabled: recoveryInteractor.isUserCodeRecoveryAllowed)

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

    func setupAccessCodeRecoveryModel(enabled: Bool) {
        if cardModel.canChangeAccessCodeRecoverySettings {
            accessCodeRecoverySection = DefaultRowViewModel(
                title: Localization.cardSettingsAccessCodeRecoveryTitle,
                detailsType: .text(enabled ? Localization.commonEnabled : Localization.commonDisabled),
                action: openAccessCodeSettings
            )
        }
    }
}

// MARK: - Navigation

extension CardSettingsViewModel {
    func openChangeAccessCodeWarningView() {
        Analytics.log(.buttonChangeUserCode)
        isChangeAccessCodeLoading = true
        setupSecurityOptions()
        securityOptionChangeInteractor.changeSecurityOption(.accessCode) { [weak self] result in
            DispatchQueue.main.async {
                self?.isChangeAccessCodeLoading = false
                self?.setupSecurityOptions()
            }
        }
    }

    func openSecurityMode() {
        Analytics.log(.buttonChangeSecurityMode)
        coordinator?.openSecurityMode(with: securityOptionChangeInteractor)
    }

    func openResetCard() {
        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .resetToFactory) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if cardModel.canTwin {
            prepareTwinOnboarding()
        } else {
            let cardInteractor = FactorySettingsResettingCardInteractor(with: cardModel.cardInfo)
            let input = ResetToFactoryViewModel.Input(
                cardInteractor: cardInteractor,
                hasBackupCards: cardModel.hasBackupCards,
                userWalletId: cardModel.userWalletId
            )
            coordinator?.openResetCardToFactoryWarning(with: input)
        }
    }

    func openAccessCodeSettings() {
        Analytics.log(.cardSettingsButtonAccessCodeRecovery)
        coordinator?.openAccessCodeRecoverySettings(with: recoveryInteractor)
    }
}
