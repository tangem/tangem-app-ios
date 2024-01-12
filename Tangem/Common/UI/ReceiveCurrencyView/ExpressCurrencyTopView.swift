//
//  ExpressCurrencyTopView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ExpressCurrencyTopView: View {
    let title: String
    let state: State

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            Spacer()

            switch state {
            case .idle:
                EmptyView()
            case .loading:
                SkeletonView()
                    .frame(width: 72, height: 14)
                    .cornerRadius(3)
                    .padding(.vertical, 2)
            case .notAvailable:
                Text(Localization.swappingTokenNotAvailable)
                    .style(Fonts.Regular.footnote, color: Colors.Text.disabled)
            case .formatted(let value):
                SensitiveText(builder: Localization.commonBalance, sensitive: value)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
    }
}

extension ExpressCurrencyTopView {
    enum State {
        case idle
        case notAvailable
        case loading
        case formatted(String)
    }
}

#Preview("ExpressCurrencyTopView") {
    VStack(spacing: 16) {
        ExpressCurrencyTopView(title: Localization.swappingToTitle, state: .idle)

        ExpressCurrencyTopView(title: Localization.swappingToTitle, state: .loading)

        ExpressCurrencyTopView(title: Localization.swappingToTitle, state: .notAvailable)

        ExpressCurrencyTopView(title: Localization.swappingToTitle, state: .formatted("214.233123"))
    }
    .padding()
}
