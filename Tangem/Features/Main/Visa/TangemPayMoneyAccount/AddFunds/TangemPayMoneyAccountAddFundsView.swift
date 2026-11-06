//
//  TangemPayMoneyAccountAddFundsView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayMoneyAccountAddFundsView: View {
    let viewModel: TangemPayMoneyAccountAddFundsViewModel

    var body: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.options) { option in
                Row(title: option.title, subtitle: option.subtitle)
                    .subtitleLineLimit(nil)
                    .start { Avatar(.icon(option.icon, appearance: .info)) }
                    .onTap { viewModel.select(option) }
                    .accessibilityIdentifier(option.accessibilityIdentifier)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    let viewModel = TangemPayMoneyAccountAddFundsViewModel(onSelect: { _ in })
    TangemPayMoneyAccountAddFundsView(viewModel: viewModel)
}
