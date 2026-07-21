//
//  TokenSummaryMetricInfoViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

final class TokenSummaryMetricInfoViewModel: FloatingSheetContentViewModel {
    let title: String
    let info: String
    let onClose: () -> Void

    init(title: String, info: String, onClose: @escaping () -> Void) {
        self.title = title
        self.info = info
        self.onClose = onClose
    }
}
