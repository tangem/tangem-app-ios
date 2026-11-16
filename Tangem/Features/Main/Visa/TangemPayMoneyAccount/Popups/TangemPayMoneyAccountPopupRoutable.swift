//
//  TangemPayMoneyAccountPopupRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol TangemPayMoneyAccountPopupRoutable: AnyObject {
    func closeTangemPayMoneyAccountPopup()
    func openMailFromTangemPayMoneyAccountPopup(mailViewModel: MailViewModel)
}
