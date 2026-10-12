//
//  FloatingSheetRegistry+TangemPayTransactionDetails.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class TangemUI.FloatingSheetRegistry

extension FloatingSheetRegistry {
    /// Registered outside the view tree: a transaction push shows the sheet from any screen, including
    /// those presented over the main screen through UIKit.
    func registerTangemPayTransactionDetailsFloatingSheets() {
        register(TangemPayTransactionDetailsViewModel.self, viewBuilder: TangemPayTransactionDetailsView.init)
    }
}
