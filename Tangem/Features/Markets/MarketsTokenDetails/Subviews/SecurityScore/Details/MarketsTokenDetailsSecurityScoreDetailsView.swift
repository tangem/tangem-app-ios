//
//  MarketsTokenDetailsSecurityScoreDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI

// [REDACTED_INFO]: legacy security score sheet, replaced by MarketsTokenDetailsSecurityScoreDetailsRedesignedView
struct MarketsTokenDetailsSecurityScoreDetailsView: View {
    let viewModel: MarketsTokenDetailsSecurityScoreDetailsViewModel

    var body: some View {
        GroupedScrollView {
            title

            subtitle

            MarketsTokenDetailsSecurityScoreProvidersSection(viewModel: viewModel)
        }
    }

    private var title: some View {
        Text(viewModel.title)
            .style(Fonts.Bold.body.weight(.semibold), color: Colors.Text.primary1)
            .padding(.vertical, 12.0)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.securityScoreDetailsTitle)
    }

    private var subtitle: some View {
        Text(viewModel.subtitle)
            .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
            .padding(.vertical, 14.0)
    }
}

// MARK: - Previews

#Preview {
    let helper = MarketsTokenDetailsSecurityScoreRatingHelper()

    MarketsTokenDetailsSecurityScoreDetailsView(
        viewModel: .init(
            providers: [
                .init(
                    name: "Provider #1",
                    iconURL: URL(string: "about:blank")!,
                    ratingViewData: .init(
                        ratingBullets: helper.makeRatingBullets(forSecurityScoreValue: 2.5),
                        securityScore: helper.makeSecurityScore(forSecurityScoreValue: 2.5)
                    ),
                    auditDate: Date().formatted(date: .numeric, time: .omitted),
                    auditURL: URL(string: "https://www.certik.com")
                ),
                .init(
                    name: "Provider #2",
                    iconURL: URL(string: "about:blank")!,
                    ratingViewData: .init(
                        ratingBullets: helper.makeRatingBullets(forSecurityScoreValue: 4.5),
                        securityScore: helper.makeSecurityScore(forSecurityScoreValue: 4.5)
                    ),
                    auditDate: Date().formatted(date: .numeric, time: .omitted),
                    auditURL: URL(string: "https://www.certik.com")
                ),
            ],
            routable: nil
        )
    )
}
