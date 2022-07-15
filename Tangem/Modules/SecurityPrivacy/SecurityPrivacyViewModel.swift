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
    // MARK: ViewState

    @Published var hasSingleSecurityMode: Bool = false
    @Published var isChangeAccessCodeVisible: Bool = false
    @Published var securityModeTitle: String?
    @Published var isSavingWallet: Bool = true
    @Published var isSavingAccessCodes: Bool = true
    @Published var alert: AlertBinder?

    // MARK: Dependecies

    private unowned let coordinator: SecurityPrivacyRoutable
    private let cardViewModel: CardViewModel

    // MARK: Properties

    private var bag: Set<AnyCancellable> = []
    private var shouldShowAlertOnDisableSaveAccessCodes: Bool = true

    init(
        cardModel: CardViewModel,
        coordinator: SecurityPrivacyRoutable
    ) {
        self.cardViewModel = cardModel
        self.coordinator = coordinator

        securityModeTitle = cardModel.currentSecOption.title
        hasSingleSecurityMode = cardModel.availableSecOptions.count <= 1
        isChangeAccessCodeVisible = cardModel.currentSecOption == .accessCode

        bind()
    }
}

// MARK: - Private

private extension SecurityPrivacyViewModel {
    func bind() {
        $isSavingWallet
            .dropFirst()
            .filter { !$0 }
            .sink(receiveValue: { [weak self] _ in
                self?.presentSavingWalletDeleteAlert()
            })
            .store(in: &bag)

        $isSavingAccessCodes
            .dropFirst()
            .filter { !$0 }
            .sink(receiveValue: { [weak self] _ in
                self?.presentSavingAccessCodesDeleteAlert()
            })
            .store(in: &bag)
    }

    func presentSavingWalletDeleteAlert() {
        let okButton = Alert.Button.destructive(Text("common_delete"), action: { [weak self] in
            self?.disableSaveWallet()
        })
        let cancelButton = Alert.Button.cancel(Text("common_cancel"), action: { [weak self] in
            self?.isSavingWallet = true
        })

        let alert = Alert(
            title: Text("common_attention"),
            message: Text("security_and_privacy_off_saved_wallet_alert_message"),
            primaryButton: okButton,
            secondaryButton: cancelButton
        )

        self.alert = AlertBinder(alert: alert)
    }

    func presentSavingAccessCodesDeleteAlert() {
        guard shouldShowAlertOnDisableSaveAccessCodes else { return }

        let okButton = Alert.Button.destructive(Text("common_delete"), action: { [weak self] in
            self?.disableSaveAccessCodes()
        })

        let cancelButton = Alert.Button.cancel(Text("common_cancel"), action: { [weak self] in
            self?.isSavingAccessCodes = true
        })

        let alert = Alert(
            title: Text("common_attention"),
            message: Text("security_and_privacy_off_saved_access_code_alert_message"),
            primaryButton: okButton,
            secondaryButton: cancelButton
        )


        self.alert = AlertBinder(alert: alert)
    }

    func disableSaveWallet() {
        // [REDACTED_TODO_COMMENT]
        disableSaveAccessCodes()
    }

    func disableSaveAccessCodes() {
        // [REDACTED_TODO_COMMENT]

        if isSavingAccessCodes {
            shouldShowAlertOnDisableSaveAccessCodes = false
            isSavingAccessCodes = false
            shouldShowAlertOnDisableSaveAccessCodes = true
        }
    }
}

// MARK: - Navigation

extension SecurityPrivacyViewModel {
    func openChangeAccessCode() {
        coordinator.openChangeAccessCodeWarningView { [weak self] completion in
            guard let self = self else { return }

            self.cardViewModel.changeSecOption(.accessCode, completion: completion)
        }
    }

    func openChangeAccessMethod() {
        coordinator.openSecurityManagement(cardModel: cardViewModel)
    }

    func openTokenSynchronization() {
        coordinator.openTokenSynchronization()
    }

    func openResetSavedCards() {
        coordinator.openResetSavedCards()
    }
}
