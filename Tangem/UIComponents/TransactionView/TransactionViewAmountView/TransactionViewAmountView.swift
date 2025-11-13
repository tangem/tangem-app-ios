//
//  TransactionViewAmountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct TransactionViewAmountView: View {
    let data: TransactionViewAmountViewData
    let size: Size

    var body: some View {
        if let amount = data.formattedAmount {
            SensitiveText(amount)
                .style(size.font, color: data.amountColor)
        }
    }
}

extension TransactionViewAmountView {
    enum Size {
        case medium
        case large

        var font: Font {
            switch self {
            case .medium: Fonts.Regular.subheadline
            case .large: Fonts.Bold.largeTitle
            }
        }
    }
}
