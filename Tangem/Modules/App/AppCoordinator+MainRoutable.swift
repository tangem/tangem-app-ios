//
//  AppCoordinator+MainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension AppCoordinator: MainRoutable {
    func close(newScan: Bool) {
        popToRoot()
        
        if newScan {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.welcomeViewModel.scanCard()
            }
        }
    }
    
    func openSettings(cardModel: CardViewModel) {
        detailsViewModel = DetailsViewModel(cardModel: cardModel, coordinator: self)
    }
    
    func openTokenDetails(cardModel: CardViewModel, blockchainNetwork: BlockchainNetwork, amountType: Amount.AmountType) {
        tokenDetailsViewModel = TokenDetailsViewModel(cardModel: cardModel,
                                                      blockchainNetwork: blockchainNetwork,
                                                      amountType: amountType,
                                                      coordinator: self)
    }
    
    func openCurrencySelection(autoDismiss: Bool) {
        currencySelectViewModel = CurrencySelectViewModel()
        currencySelectViewModel?.dismissAfterSelection = autoDismiss
    }
    
    func openExternalURL(_ url: URL) {
        safariURL = url
    }
    
    func openTokensList(with cardModel: CardViewModel) {
        let coordinator = TokenListCoordinator()
        coordinator.dismissAction = { [weak self] in self?.tokenListCoordinator = nil }
        coordinator.start(with: .add(cardModel: cardModel))
        self.tokenListCoordinator = coordinator
    }
    
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType) {
        mailViewModel = MailViewModel(dataCollector: dataCollector, support: .tangem, emailType: emailType)
    }
    
    func openQR(shareAddress: String, address: String, qrNotice: String) {
        addressQrBottomSheetContentViewVodel = .init(shareAddress: shareAddress, address: address, qrNotice: qrNotice)
    }
}
