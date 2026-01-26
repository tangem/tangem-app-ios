//
//  EarnDetailView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct EarnDetailView: View {
    @ObservedObject var viewModel: EarnDetailViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Header
            NavigationBar(
                title: "Earn",
                leftButtons: {
                    BackButton(
                        height: 44.0,
                        isVisible: true,
                        isEnabled: true,
                        hPadding: 10.0,
                        action: { viewModel.handleViewAction(.back) }
                    )
                }
            )
            .padding(.top, 12)

            // Content placeholder
            Spacer()
        }
        .background(Color.Tangem.Surface.level3.ignoresSafeArea())
    }
}
