//
//  LegacyMainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol LegacyMainRoutable: TokenDetailsRoutable {
    func close(newScan: Bool)
    func openSettings(cardModel: CardViewModel)
    func openTokenDetails(cardModel: CardViewModel, blockchainNetwork: BlockchainNetwork, amountType: Amount.AmountType)
    func openOnboardingModal(with input: OnboardingInput)
    func openCurrencySelection(autoDismiss: Bool)
    func openTokensList(with cardModel: CardViewModel)
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String)
    func openQR(shareAddress: String, address: String, qrNotice: String)
    func openUserWalletList()
    func openPromotion(cardPublicKey: String, cardId: String, walletId: String)
}

protocol OpenCurrencySelectionDelegate: AnyObject {
    func openCurrencySelection()
}
