//
//  StakingDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct StakingDetailsView: View {
    @ObservedObject private var viewModel: StakingDetailsViewModel
    @State private var bottomViewHeight: CGFloat = .zero

    init(viewModel: StakingDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                GroupedScrollView(alignment: .leading, spacing: 14) {
                    banner

                    averageRewardingView

                    GroupedSection(viewModel.detailsViewModels) {
                        DefaultRowView(viewModel: $0)
                    }

                    rewardView

                    FixedSpacer(height: bottomViewHeight)
                }
                .interContentPadding(14)

                actionButton
            }
            .background(Colors.Background.secondary)
            .navigationTitle("Staking Solana")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var banner: some View {
        Button(action: { viewModel.userDidTapBanner() }) {
            Assets.whatIsStakingBanner.image
                .resizable()
                .cornerRadiusContinuous(18)
        }
    }

    private var averageRewardingView: some View {
        GroupedSection(viewModel.averageRewardingViewData) {
            AverageRewardingView(data: $0)
        } header: {
            DefaultHeaderView("Average Reward Rate")
        }
        .interItemSpacing(12)
        .innerContentPadding(12)
    }

    private var rewardView: some View {
        GroupedSection(viewModel.rewardViewData) {
            RewardView(data: $0)
        } header: {
            DefaultHeaderView("Rewards")
        }
        .interItemSpacing(12)
        .innerContentPadding(12)
    }

    private var actionButton: some View {
        MainButton(title: "Stake") {
            viewModel.userDidTapActionButton()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .readGeometry(\.size.height, bindTo: $bottomViewHeight)
    }
}

struct RewardViewData: Hashable, Identifiable {
    var id: Int { hashValue }

    let state: State
}

extension RewardViewData {
    enum State: Hashable {
        case noRewards
        case rewards(fiatFormatted: String, cryptoFormatted: String)
    }
}

struct RewardView: View {
    let data: RewardViewData

    var body: some View {
        HStack(spacing: 4) {
            content
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }

    @ViewBuilder
    var content: some View {
        switch data.state {
        case .noRewards:
            Text("No rewards to claim")
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
        case .rewards(let fiatFormatted, let cryptoFormatted):
            Text(fiatFormatted)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

            Text(AppConstants.dotSign)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

            Text(cryptoFormatted)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
        }
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
        .infinityFrame(axis: .horizontal, alignment: .leading)
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

struct StakingDetailsView_Preview: PreviewProvider {
    static let viewModel = StakingDetailsViewModel(
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
            monthEstimatedProfit: 56.25,
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
        coordinator: StakingDetailsCoordinator()
    )

    static var previews: some View {
        StakingDetailsView(viewModel: viewModel)
    }
}
