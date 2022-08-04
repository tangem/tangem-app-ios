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

    var cardId: String {
        cardModel.cardInfo.cardIdFormatted
    }

    var cardIssuer: String {
        cardModel.cardInfo.card.issuer.name
    }

    var cardSignedHashes: String? {
        guard cardModel.hasWallet,
              cardModel.config.features.contains(.signedHashesCounterAvailable) else {
            return nil
        }

        return "\(cardModel.cardInfo.card.walletSignedHashes)"
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
    }
}

// MARK: - Private

private extension CardSettingsViewModel {
    func bind() {
        cardModel.$currentSecurityOption
            .map { $0.title }
            .weakAssign(to: \.securityModeTitle, on: self)
            .store(in: &bag)
    }
}

// MARK: - Navigation

extension CardSettingsViewModel {
    func openChangeAccessCodeWarningView() {
        isChangeAccessCodeLoading = true
        cardModel.changeSecurityOption(.accessCode) { [weak self] result in
            DispatchQueue.main.async {
                self?.isChangeAccessCodeLoading = false
            }
        }
    }

    func openSecurityMode() {
        coordinator.openSecurityMode(cardModel: cardModel)
    }

    func openResetCard() {
        coordinator.openResetCardToFactoryWarning { [weak self] in
            self?.cardModel.resetToFactory { [weak self] result in
                switch result {
                case .success:
                    self?.coordinator.closeResetCardToFactoryWarning()
                case let .failure(error):
                    print("ResetCardToFactoryWarning error", error)
                }
            }
        }
    }
}
