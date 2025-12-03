//
//  TangemPayWithdrawInProgressSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import TangemLocalization

protocol TangemPayWithdrawInProgressSheetRoutable {
    func closeWithdrawInProgressSheet()
}

struct TangemPayWithdrawInProgressSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    let coordinator: TangemPayWithdrawInProgressSheetRoutable

    func close() {
        coordinator.closeWithdrawInProgressSheet()
    }
}
