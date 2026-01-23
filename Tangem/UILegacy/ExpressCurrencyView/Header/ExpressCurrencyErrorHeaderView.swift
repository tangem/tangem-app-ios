//
//  ExpressCurrencyErrorHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct ExpressCurrencyErrorHeaderView: View {
    let errorState: ExpressCurrencyViewModel.ErrorState

    var body: some View {
        switch errorState {
        case .insufficientFunds:
            Text(Localization.swappingInsufficientFunds)
                .style(Fonts.Regular.caption1, color: Colors.Text.warning)
        case .error(let text):
            // Use for generic error
            Text(text)
                .style(Fonts.Regular.caption1, color: Colors.Text.warning)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Insufficient Funds") {
    ExpressCurrencyErrorHeaderView(errorState: .insufficientFunds)
}

#Preview("Generic Error") {
    ExpressCurrencyErrorHeaderView(errorState: .error("Something went wrong"))
}
#endif // DEBUG
