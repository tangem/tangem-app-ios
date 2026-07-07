//
//  FloatingSheetRegistry+TransactionDetails.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class TangemUI.FloatingSheetRegistry

extension FloatingSheetRegistry {
    func registerTransactionDetailsFloatingSheets() {
        register(TransactionDetailsViewModel.self) { viewModel in
            TransactionDetailsView(viewModel: viewModel)
        }
    }
}
