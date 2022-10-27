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
            .weakAssign(to: \.securityModeTitle, on: self)
            .store(in: &bag)
    }

    func prepareTwinOnboarding() {
        if let twinInput = cardModel.twinInput {
            coordinator.openOnboarding(with: twinInput)
        }
    }
    
    func setupView() {
        cardInfoSection = [
            DefaultRowViewModel(title: "details_row_title_cid".localized, detailsType: .text(cardModel.cardIdFormatted)),
            DefaultRowViewModel(title: "details_row_title_issuer".localized, detailsType: .text(cardModel.cardIssuer)),
            DefaultRowViewModel(title: "details_row_title_signed_hashes".localized,
                                detailsType: .text("details_row_subtitle_signed_hashes_format".localized("\(cardModel.cardSignedHashes)"))),
        ]
        
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

        if isResetToFactoryAvailable {
            resetToFactoryViewModel = DefaultRowViewModel(
                title: "card_settings_reset_card_to_factory".localized,
                action: openResetCard
            )
        }
    }
}

// MARK: - Navigation

extension CardSettingsViewModel {
    func openChangeAccessCodeWarningView() {
        Analytics.log(.buttonChangeUserCode)
        isChangeAccessCodeLoading = true
        cardModel.changeSecurityOption(.accessCode) { [weak self] result in
            DispatchQueue.main.async {
                self?.isChangeAccessCodeLoading = false
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
            coordinator.openResetCardToFactoryWarning { [weak self] in
                self?.cardModel.resetToFactory { [weak self] result in
                    switch result {
                    case .success:
                        self?.coordinator.resetCardDidFinish()
                    case let .failure(error):
                        if !error.isUserCancelled {
                            self?.alert = error.alertBinder
                        }
                    }
                }
            }
        }
    }
}
