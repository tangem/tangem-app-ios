//
//  AppCoordinator+DetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension AppCoordinator: DetailsRoutable {
    func openMail(with dataCollector: EmailDataCollector, support: EmailSupport, emailType: EmailType) {
        mailViewModel = MailViewModel(dataCollector: dataCollector, support: support, emailType: emailType)
    }
    
    func openWalletConnect(with cardModel: CardViewModel) {
        walletConnectViewModel = WalletConnectViewModel(cardModel: cardModel, coordinator: self)
    }
    
    func openDisclaimer() {
        disclaimerViewModel = .init(style: .navbar, showAccept: false, dismissCallback: {})
    }
    
    func openCardTOU(at url: URL) {
        pushedWebViewModel = WebViewContainerViewModel(url: url, title: "details_row_title_card_tou".localized)
    }
    
    func openResetToFactory(action: @escaping (_ completion: @escaping (Result<Void, Error>) -> Void) -> Void) {
        cardOperationViewModel = CardOperationViewModel(title: "details_row_title_reset_factory_settings".localized,
                                                        buttonTitle: "card_operation_button_title_reset",
                                                        shouldPopToRoot: true,
                                                        alert: "details_row_title_reset_factory_settings_warning".localized,
                                                        actionButtonPressed: action,
                                                        coordinator: self)
    }
    
    func openSecManagement(with cardModel: CardViewModel) {
        secManagementViewModel = SecurityManagementViewModel(cardModel: cardModel, coordinator: self)
    }
}

