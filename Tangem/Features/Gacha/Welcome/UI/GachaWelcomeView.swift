//
//  GachaWelcomeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct GachaWelcomeView: View {
    @ObservedObject var viewModel: GachaWelcomeViewModel

    let onCloseButtonAction: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            NavigationBarButton.close(action: onCloseButtonAction)
                .padding(.top, Metrics.closeTopPadding)
                .padding(.trailing, Metrics.closeTrailingPadding)
        }
        .environment(\.isRedesign, true)
    }
}

// MARK: - Metrics

private extension GachaWelcomeView {
    enum Metrics {
        static let closeTopPadding: CGFloat = 8
        static let closeTrailingPadding: CGFloat = 16
    }
}

// MARK: - Previews

#Preview {
    GachaWelcomeView(viewModel: GachaWelcomeViewModel(), onCloseButtonAction: {})
}
