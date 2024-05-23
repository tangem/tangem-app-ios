//
//  StakeDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct StakeDetailsView: View {
    @ObservedObject private var viewModel: StakeDetailsViewModel

    init(viewModel: StakeDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            GroupedScrollView(alignment: .leading, spacing: 14) {
                banner

                GroupedSection(viewModel.averageRewardingViewData) {
                    AverageRewardingView(data: $0)
                } header: {
                    DefaultHeaderView("Average Reward Rate")
                }
                .interItemSpacing(12)
                .innerContentPadding(12)

                GroupedSection(viewModel.detailsViewModels) {
                    DefaultRowView(viewModel: $0)
                }
            }
            .background(Colors.Background.secondary)
            .navigationTitle("Stake Solana")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var banner: some View {
        Rectangle()
            .fill(Color.cyan.opacity(0.5))
            .frame(height: 100)
            .cornerRadiusContinuous(18)
    }
}

struct AverageRewardingViewData: Hashable, Identifiable {
    var id: Int { hashValue }

    let aprFormatted: String
    let profitFormatted: String
}

struct AverageRewardingView: View {
    let data: AverageRewardingViewData

    var body: some View {
        HStack(spacing: .zero) {
            leadingView

            trailingView
        }
    }

    private var leadingView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("APR")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            Text(data.aprFormatted)
                .style(Fonts.Regular.callout, color: Colors.Text.accent)
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }

    private var trailingView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("30 day est. profit")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            Text(data.profitFormatted)
                .style(Fonts.Regular.callout, color: Colors.Text.primary1)
        }
        .lineLimit(1)
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }
}

struct StakeDetailsView_Preview: PreviewProvider {
    static let viewModel = StakeDetailsViewModel(
        inputData: .init(
            tokenItem: .blockchain(
                .init(
                    .solana(
                        curve: .ed25519_slip0010,
                        testnet: false
                    ),
                    derivationPath: .none
                )
            ),
            monthEstimatedProfit: "+56.25$",
            available: 15,
            staked: 0,
            minAPR: 3.54,
            maxAPR: 5.06,
            unbonding: .days(3),
            minimumRequirement: 0.000028,
            rewardClaimingType: .auto,
            warmupPeriod: .days(3),
            rewardScheduleType: .block
        ),
        coordinator: StakeDetailsCoordinator()
    )

    static var previews: some View {
        StakeDetailsView(viewModel: viewModel)
    }
}
