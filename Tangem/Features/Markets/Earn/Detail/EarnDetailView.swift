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
        VStack(spacing: .zero) {
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

            // Content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    // Mostly Used Section
                    EarnDetailHeaderView(headerTitle: "Mostly used")
                    EarnMostlyUsedView(viewModels: viewModel.mostlyUsedViewModels)

                    // Best Opportunities Section
                    EarnDetailHeaderView(headerTitle: "Best opportunities")
                    EarnFilterHeaderView(
                        onNetworksTap: { viewModel.handleViewAction(.networksFilterTap) },
                        onTypesTap: { viewModel.handleViewAction(.typesFilterTap) }
                    )
                    EarnBestOpportunitiesListView()
                }
            }
        }
        .background(Color.Tangem.Surface.level3.ignoresSafeArea())
    }
}

private extension EarnDetailView {
    enum Layout {
        static let sectionSpacing: CGFloat = 12.0
    }
}
