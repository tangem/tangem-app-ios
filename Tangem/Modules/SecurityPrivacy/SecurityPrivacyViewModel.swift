//
//  SecurityPrivacyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class SecurityPrivacyViewModel: ObservableObject {
    // MARK: Dependecies
    private unowned let coordinator: SecurityPrivacyRoutable
    private let cardModel: CardViewModel

    // MARK: ViewState

    @Published var securityModeTitle: String?
    @Published var isSavedCards: Bool = true
    @Published var isSavedPasswords: Bool = true
    @Published var alert: AlertBinder?

    // MARK: Properties

    private var bag: Set<AnyCancellable> = []

    init(
        cardModel: CardViewModel,
        coordinator: SecurityPrivacyRoutable
    ) {
        self.cardModel = cardModel
        self.coordinator = coordinator

        securityModeTitle = cardModel.currentSecOption.title

        bind()
    }
}

// MARK: - Private

private extension SecurityPrivacyViewModel {
    func bind() {
        $isSavedCards
            .dropFirst()
            .filter { !$0 }
            .sink(receiveValue: { [weak self] _ in
                self?.presentChangeAccessCodeAlert()
            })
            .store(in: &bag)
    }

    func presentChangeAccessCodeAlert() {
        let okButton = Alert.Button.default(Text("OK"))
        let cancelButton = Alert.Button.cancel(Text("Cancel"), action: { [weak self] in
            self?.isSavedCards = true
        })

        let alert = Alert(
            title: Text("Внимание"),
            message: Text("При отключении данной опции все сохраненные карты и пароли будут сброшены, все данные удалены. Для входа в приложение понадобится прикладывать карту."),
            primaryButton: okButton,
            secondaryButton: cancelButton
        )

        self.alert = AlertBinder(alert: alert)
    }
}

// MARK: - View Output

extension SecurityPrivacyViewModel {
    func openChangeAccessCode() {
        coordinator.openChangeAccessCode()
    }

    func openChangeAccessMethod() {
        coordinator.openSecurityManagement(cardModel: cardModel)
    }

    func openTokenSynchronization() {
        coordinator.openTokenSynchronization()
    }

    func openResetSavedCards() {
        coordinator.openResetSavedCards()
    }
}
