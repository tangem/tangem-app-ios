//
//  TangemPayCardManagementView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct TangemPayCardManagementView: View {
    @ObservedObject var viewModel: TangemPayCardManagementViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                TangemPayCardDetailsView(viewModel: viewModel.tangemPayCardDetailsViewModel)

                if viewModel.shouldDisplayAddToApplePayGuide {
                    Button(action: viewModel.openAddToApplePayGuide) {
                        TangemPayAddToApplePayBanner(closeAction: viewModel.dismissAddToApplePayGuideBanner)
                    }
                }

                GroupedSection(viewModel.cardSettingsRows) {
                    DefaultRowView(viewModel: $0)
                } header: {
                    DefaultHeaderView(Localization.tangempayCardPageSettingsTitle)
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
