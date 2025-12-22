//
//  StakingDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils
import TangemUI
import TangemAccessibilityIdentifiers

struct StakingDetailsView: View {
    @ObservedObject var viewModel: StakingDetailsViewModel

    @State private var viewGeometryInfo: GeometryInfo = .zero
    @State private var contentSize: CGSize = .zero
    @State private var bottomViewSize: CGSize = .zero

    private var spacer: CGFloat {
        var height = viewGeometryInfo.frame.height
        height -= contentSize.height
        height -= bottomViewSize.height
        return max(0, height)
    }

    var body: some View {
        RefreshScrollView(stateObject: viewModel.scrollViewStateObject, contentSettings: .lazyVStack(spacing: .zero)) {
            VStack(spacing: 14) {
                if !viewModel.hideStakingInfoBanner {
                    banner
                }

                GroupedSection(viewModel.detailsViewModels) { data in
                    DefaultRowView(viewModel: data)
                }

                rewardView

                GroupedSection(viewModel.stakes) { data in
                    StakingDetailsStakeView(data: data)
                        .confirmationDialog(viewModel: $viewModel.confirmationDialog)
                } header: {
                    DefaultHeaderView(Localization.stakingYourStakes)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }
                .separatorStyle(.none)
                .interItemSpacing(0)
                .innerContentPadding(0)
            }
            .readGeometry(\.frame.size, bindTo: $contentSize)
            .padding(.horizontal, 16)

            bottomView
                .padding(.horizontal, 16)
        }
        .readGeometry(bindTo: $viewGeometryInfo)
        .background(Colors.Background.secondary)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(StakingAccessibilityIdentifiers.title)
        .onAppear(perform: viewModel.onAppear)
        .alert(item: $viewModel.alert) { $0.alert }
        .bottomSheet(
            item: $viewModel.descriptionBottomSheetInfo,
            backgroundColor: Colors.Background.tertiary
        ) {
            DescriptionBottomSheetView(
                info: DescriptionBottomSheetInfo(title: $0.title, description: $0.description)
            )
        }
    }

    private var banner: some View {
        Button(action: viewModel.userDidTapBanner) {
            ZStack(alignment: .leading) {
                Assets.whatIsStakingBanner.image
                    .resizable()
                    .cornerRadiusContinuous(18)
                whatIsStakingText
                    .padding(.leading, 14)
            }
        }
    }

    private var whatIsStakingText: some View {
        Text(Localization.stakingDetailsBannerText)
            .font(Fonts.Bold.title1)
            .foregroundStyle(
                LinearGradient(
                    colors: [Colors.Text.constantWhite, Colors.Text.stakingGradient],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    private var rewardView: some View {
        GroupedSection(viewModel.rewardViewData) { data in
            RewardView(data: data)
        } header: {
            DefaultHeaderView(Localization.stakingRewards)
                .padding(.top, 8)
        }
        .innerContentPadding(4)
    }

    private var bottomView: some View {
        VStack(spacing: 12) {
            FixedSpacer(height: spacer)

            VStack(spacing: 12) {
                legalView

                actionButton
            }
            .readGeometry(\.frame.size, bindTo: $bottomViewSize)
        }
        .disableAnimations() // To force `.animation(nil)` behaviour
    }

    private var legalView: some View {
        Text(viewModel.legalText)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var actionButton: some View {
        if let actionButtonType = viewModel.actionButtonType {
            MainButton(
                title: actionButtonType.title,
                isLoading: viewModel.actionButtonLoading,
                isDisabled: viewModel.actionButtonState != .enabled,
                handleActionWhenDisabled: viewModel.actionButtonState.allowTapHandling
            ) {
                viewModel.userDidTapActionButton()
            }
            .padding(.bottom, 8)
            .accessibilityIdentifier(StakingAccessibilityIdentifiers.stakeButton)
        }
    }
}

struct StakingDetailsView_Preview: PreviewProvider {
    static let viewModel = StakingDetailsViewModel(
        tokenItem: CommonWalletModel.mockETH.tokenItem,
        tokenBalanceProvider: CommonWalletModel.mockETH.availableBalanceProvider,
        stakingManager: StakingManagerMock(),
        coordinator: StakingDetailsCoordinator()
    )

    static var previews: some View {
        StakingDetailsView(viewModel: viewModel)
    }
}
