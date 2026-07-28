//
//  TangemPayVirtualAccountInfoSheetRoutable.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

@MainActor
protocol TangemPayVirtualAccountInfoSheetRoutable: AnyObject {
    func virtualAccountInfoSheetDidCreateOrder()
    func virtualAccountDidLoadBankCredentials(_ credentials: TangemPayBankCredentialsResponse)
    func virtualAccountInfoSheetDidFailToLoadBankCredentials(productInstanceId: String)
    func closeVirtualAccountSheet()
    func openVirtualAccountURL(_ url: URL)
}
