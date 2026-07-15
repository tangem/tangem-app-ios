//
//  CampaignView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemUIUtils
import TangemLocalization
import TangemAccounts

struct CampaignView: View {
    @ObservedObject var viewModel: CampaignViewModel

    var body: some View {
        FloatingSheetContainerView(
            state: viewModel.viewState,
            showsButton: showsButton,
            maxHeightFraction: viewModel.viewState == .readyToEnroll ? 0.9 : nil,
            button: { button },
            headerContent: { header },
            mainContent: { mainContent }
        )
        .onAppear(perform: viewModel.onAppear)
    }

    // MARK: - Header

    private var header: some View {
        BottomSheetHeaderView(
            title: "",
            trailing: { NavigationBarButton.close(action: viewModel.close) }
        )
    }

    // MARK: - Main content

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.viewState {
        case .idle, .loading:
            loadingContent
        case .summary:
            summaryContent
        case .readyToEnroll:
            readyToEnrollContent
        case .campaignNotActive, .alreadyActivated, .enrollSuccess:
            statusContent
        }
    }

    private var loadingContent: some View {
        TangemLoader()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 50)
    }

    private var statusContent: some View {
        VStack(spacing: 32) {
            icon

            VStack(spacing: 8) {
                Text(viewModel.statusTitle)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                    .fixedSize(horizontal: false, vertical: true)

                if !viewModel.statusSubtitle.isEmpty {
                    Text(viewModel.statusSubtitle)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 36)
    }

    private var summaryContent: some View {
        campaignInfo
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
    }

    private var readyToEnrollContent: some View {
        VStack(spacing: 24) {
            campaignInfo
            accountSection
            termsView
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    private var campaignInfo: some View {
        VStack(spacing: 32) {
            logo

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.summaryTitle)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                    .fixedSize(horizontal: false, vertical: true)

                Text(viewModel.summaryDescription)
                    .style(Fonts.Bold.caption1, color: Colors.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: viewModel.openLearnMore) {
                    Text(Localization.commonLearnMore)
                        .style(Fonts.Bold.caption1, color: Colors.Text.primary1)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.promoCampaignSelectCashbackAccount)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            if let rowViewModel = viewModel.selectedTokenRowViewModel {
                VStack(alignment: .leading, spacing: 16) {
                    if let accountViewData = viewModel.selectedAccountViewData {
                        AccountInlineHeaderView(
                            iconData: accountViewData.iconData,
                            name: accountViewData.name
                        )
                    }

                    CampaignTokenRowView(viewModel: rowViewModel, networkName: viewModel.selectedTokenNetworkName)
                }
                .padding(16)
                .background(DesignSystem.Color.bgPrimary)
                .cornerRadiusContinuous(24)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var termsView: some View {
        Text(viewModel.termsText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .environment(\.openURL, OpenURLAction { _ in
                viewModel.openTerms()
                return .handled
            })
    }

    private var logo: some View {
        IconView(
            url: viewModel.logoURL,
            size: CGSize(bothDimensions: Constants.circleDimension),
            cornerRadius: Constants.circleCornerRadius,
            forceKingfisher: true
        ) {
            Circle()
                .fill(DesignSystem.Color.bgDisabled)
                .frame(width: Constants.circleDimension, height: Constants.circleDimension)
        }
    }

    private var icon: some View {
        viewModel.viewState.icon.image
            .resizable()
            .frame(width: Constants.statusIconDimension, height: Constants.statusIconDimension)
            .foregroundColor(viewModel.viewState.iconColor)
            .frame(width: Constants.circleDimension, height: Constants.circleDimension)
            .background(viewModel.viewState.iconBackgroundColor)
            .clipShape(Circle())
    }

    // MARK: - Button

    @ViewBuilder
    private var button: some View {
        switch viewModel.viewState {
        case .campaignNotActive, .alreadyActivated, .enrollSuccess:
            MainButton(settings: MainButton.Settings(title: Localization.commonClose, action: viewModel.close))
        case .summary:
            MainButton(settings: MainButton.Settings(title: Localization.promoCampaignSelectToken, isDisabled: true, action: viewModel.selectToken))
        case .readyToEnroll:
            MainButton(settings: MainButton.Settings(title: Localization.promoCampaignEnroll, isDisabled: true, action: viewModel.enroll))
        case .idle, .loading:
            EmptyView()
        }
    }

    private var showsButton: Bool {
        switch viewModel.viewState {
        case .campaignNotActive, .alreadyActivated, .enrollSuccess, .summary, .readyToEnroll: true
        case .idle, .loading: false
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let circleDimension: CGFloat = 80
    static let circleCornerRadius: CGFloat = circleDimension / 2
    static let statusIconDimension: CGFloat = 28
}

// MARK: - Previews

private extension CampaignView {
    static func preview(state: CampaignViewModel.ViewState) -> CampaignView {
        CampaignView(viewModel: CampaignViewModel(
            campaignId: CashbackCampaign.whaleSwap.rawValue,
            coordinator: nil,
            cashbackPromoService: CashbackPromoService(),
            initialState: state
        ))
    }
}

#Preview("Loading") {
    CampaignView.preview(state: .loading)
}

#Preview("Summary") {
    CampaignView.preview(state: .summary)
}

#Preview("Ready to enroll") {
    CampaignView.preview(state: .readyToEnroll)
}

#Preview("Enroll success") {
    CampaignView.preview(state: .enrollSuccess)
}

#Preview("Already activated") {
    CampaignView.preview(state: .alreadyActivated)
}

#Preview("Not active") {
    CampaignView.preview(state: .campaignNotActive)
}
