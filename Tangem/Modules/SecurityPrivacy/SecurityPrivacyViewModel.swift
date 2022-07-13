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

    @Published var isOnceOptionSecurityMode: Bool = false
    @Published var securityModeTitle: String?
    @Published var isSaveCards: Bool = true
    @Published var isSaveAccessCodes: Bool = true
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
        isOnceOptionSecurityMode = cardModel.availableSecOptions.count <= 1

        bind()
    }
}

// MARK: - Private

private extension SecurityPrivacyViewModel {
    func bind() {
        $isSaveCards
            .dropFirst()
            .filter { !$0 }
            .sink(receiveValue: { [weak self] _ in
                self?.presenSavedCardsDeleteAlert()
            })
            .store(in: &bag)

        $isSaveAccessCodes
            .dropFirst()
            .filter { !$0 }
            .sink(receiveValue: { [weak self] _ in
                self?.presentChangeAccessCodeDeleteAlert()
            })
            .store(in: &bag)
    }

    func presentChangeAccessCodeDeleteAlert() {
        let okButton = Alert.Button.destructive(Text("common_delete"), action: {
            // [REDACTED_TODO_COMMENT]
        })
        let cancelButton = Alert.Button.cancel(Text("common_cancel"), action: { [weak self] in
            self?.isSaveAccessCodes = true
        })

        let alert = Alert(
            title: Text("common_attention"),
            message: Text("При отключении данной опции все сохраненные карты и пароли будут сброше, все данные удалены. Для входа в приложение понадобится прикладывать карту."),
            primaryButton: okButton,
            secondaryButton: cancelButton
        )


        self.alert = AlertBinder(alert: alert)
    }

    func presenSavedCardsDeleteAlert() {
        let okButton = Alert.Button.destructive(Text("common_delete"), action: {
            // [REDACTED_TODO_COMMENT]
        })
        let cancelButton = Alert.Button.cancel(Text("common_cancel"), action: { [weak self] in
            self?.isSaveCards = true
        })

        let alert = Alert(
            title: Text("common_attention"),
            message: Text("Все сохраненные пароли от карт будут удалены. Для проведения операций с картой вам необходимо будет вводить пароль."),
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
