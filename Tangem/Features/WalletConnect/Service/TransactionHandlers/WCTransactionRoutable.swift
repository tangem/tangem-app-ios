//
//  WCTransactionRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

@MainActor
protocol WCTransactionRoutable {
    func show(floatingSheetViewModel: some FloatingSheetContentViewModel)
    func show(toast: Toast<WarningToast>)
}
