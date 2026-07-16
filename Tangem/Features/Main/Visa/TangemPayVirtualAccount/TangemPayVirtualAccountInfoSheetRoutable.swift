//
//  TangemPayVirtualAccountInfoSheetRoutable.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol TangemPayVirtualAccountInfoSheetRoutable: AnyObject {
    func virtualAccountInfoSheetDidCreateOrder()
    func virtualAccountInfoSheetRequestBankDetails(productInstanceId: String)
    func closeVirtualAccountInfoSheet()
    func openVirtualAccountURL(_ url: URL)
}
