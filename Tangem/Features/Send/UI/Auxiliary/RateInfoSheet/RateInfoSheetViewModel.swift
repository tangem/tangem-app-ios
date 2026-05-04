//
//  RateInfoSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

struct RateInfoSheetViewModel: FloatingSheetContentViewModel {
    var id: String { String(describing: Self.self) }

    let rateType: RateType
    let onDismiss: () -> Void

    func close() {
        onDismiss()
    }

    enum RateType {
        case fixed
        case floating
    }
}
