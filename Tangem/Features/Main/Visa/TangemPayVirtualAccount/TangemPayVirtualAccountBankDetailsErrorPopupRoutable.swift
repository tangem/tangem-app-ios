//
//  TangemPayVirtualAccountBankDetailsErrorPopupRoutable.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

protocol TangemPayVirtualAccountBankDetailsErrorPopupRoutable: AnyObject {
    func virtualAccountDidLoadBankCredentials(_ credentials: TangemPayBankCredentialsResponse)
    func virtualAccountBankDetailsErrorPopupDidRequestSupport()
    func closeVirtualAccountSheet()
}
