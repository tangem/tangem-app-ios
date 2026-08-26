//
//  PortfolioTokenItemView+BalanceText.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

extension PortfolioTokenItemView {
    /// Maskable balance; `nil` stays a plain dash — "no data" must not look like "hidden".
    struct BalanceText: View {
        let value: String?

        var body: some View {
            if let value {
                SensitiveText(value)
            } else {
                Text(AppConstants.enDashSign)
            }
        }
    }
}
