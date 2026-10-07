//
//  PromoCampaignView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Kingfisher
import SwiftUI
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PromoCampaignView: View {
    @ObservedObject var viewModel: PromoCampaignViewModel

    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                heroImage

                VStack(spacing: Constants.sectionSpacing) {
                    title

                    if let rowViewModel = viewModel.selectedTokenRowViewModel {
                        selectedTokenSection(rowViewModel: rowViewModel)
                    }

                    PromoCampaignBlocksView(blocks: viewModel.blocks)

                    if let learnMoreLink = viewModel.learnMoreLink {
                        learnMore(learnMoreLink)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .padding(.top, Constants.contentTopOffset)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .overlay(alignment: .topTrailing) {
            NavigationBarButton.close(action: viewModel.close)
                .padding(16)
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            footer
        }
        .sheet(item: $viewModel.tokenSelectorViewModel) { tokenSelectorViewModel in
            CampaignTokenSelectorView(viewModel: tokenSelectorViewModel)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgPrimary
            configuration.backgroundInteractionBehavior = .tapToDismiss
            configuration.verticalSwipeBehavior = .init(target: .sheet, threshold: Constants.swipeToDismissThreshold)
            configuration.maxHeightFraction = Constants.maxHeightFraction
        }
    }

    // MARK: - Hero image

    private var heroImage: some View {
        Color.clear
            .frame(height: Constants.heroImageHeight)
            .frame(maxWidth: .infinity)
            .overlay {
                KFImage(viewModel.imageURL)
                    .resizable()
                    .cancelOnDisappear(true)
                    .placeholder { DesignSystem.Color.bgSecondary }
                    .onFailureView { DesignSystem.Color.bgSecondary }
                    .aspectRatio(contentMode: .fill)
            }
            .clipped()
            .accessibilityHidden(true)
            .overlay(alignment: .bottom) {
                LinearGradient(
                    stops: [
                        .init(color: DesignSystem.Color.bgPrimary.opacity(0), location: 0),
                        .init(color: DesignSystem.Color.bgPrimary, location: 0.5),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: Constants.heroImageTintHeight)
            }
    }

    // MARK: - Title

    private var title: some View {
        Text(viewModel.title)
            .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Selected token

    private func selectedTokenSection(rowViewModel: TokenSelectorItemViewModel) -> some View {
        VStack(spacing: 0) {
            PromoCampaignBlockTitleView(title: Localization.promoCampaignSelectedCashbackAccount)

            SwiftUI.Button(action: viewModel.selectToken) {
                VStack(alignment: .leading, spacing: 16) {
                    if let accountViewData = viewModel.selectedAccountViewData {
                        AccountInlineHeaderView(iconData: accountViewData.iconData, name: accountViewData.name)
                    }

                    CampaignTokenRowView(viewModel: rowViewModel, networkName: viewModel.selectedTokenNetworkName)
                }
                .padding(16)
                .background(DesignSystem.Color.bgTransparentPrimary)
                .cornerRadiusContinuous(Constants.cardCornerRadius)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Learn more

    private func learnMore(_ link: PromoCampaignContent.Link) -> some View {
        SwiftUI.Button(action: { viewModel.open(link.url) }) {
            Text(link.title)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {
            if let termsText = viewModel.termsText {
                Text(termsText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .environment(\.openURL, OpenURLAction { url in
                        viewModel.open(url)
                        return .handled
                    })
            }

            TangemUI.Button(label: viewModel.actionButtonTitle, accessibilityLabel: nil, action: viewModel.performAction)
                .styleType(.default)
                .horizontalLayout(.infinity)
                .size(.x12)
                .disabled(!viewModel.isActionEnabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(ListFooterOverlayShadowView(color: DesignSystem.Color.bgPrimary))
    }
}

// MARK: - Constants

private enum Constants {
    static let maxHeightFraction: CGFloat = 0.9
    static let swipeToDismissThreshold: CGFloat = 100
    static let heroImageHeight: CGFloat = 388
    static let heroImageTintHeight: CGFloat = 136
    static let contentTopOffset: CGFloat = 256
    static let sectionSpacing: CGFloat = 24
    static let cardCornerRadius: CGFloat = 24
}

// MARK: - Previews

#Preview("Awaiting payout token") {
    PromoCampaignView(viewModel: PromoCampaignViewModel(campaign: .preview(isPayoutNeeded: true), coordinator: nil))
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("No payout token needed") {
    PromoCampaignView(viewModel: PromoCampaignViewModel(campaign: .preview(isPayoutNeeded: false), coordinator: nil))
        .background(DesignSystem.Color.bgPrimary)
}

private extension PromoCampaign {
    static func preview(isPayoutNeeded: Bool) -> PromoCampaign {
        PromoCampaign(
            id: 1,
            name: "whale_swap_cashback",
            isEnrolled: false,
            content: PromoCampaignContent(
                title: "Enroll in Whale Swap Cashback",
                imageURL: nil,
                blocks: [
                    .items(title: "Cashback and amounts", items: [
                        .init(label: "From $10K", value: "0.10%"),
                        .init(label: "From $20K", value: "0.20%"),
                        .init(label: "From $100K", value: "0.50%"),
                    ]),
                    .table(.init(
                        title: "Max payout and limits",
                        headers: [],
                        rows: [["Per swap", "$500"], ["Per wallet per swap", "$10K"]]
                    )),
                    .text("Stable coin into stablecoin swaps are excluded. Payout arrives weekly in USDT or USDC address of your choice."),
                ],
                learnMoreLink: .init(title: "Learn more", url: URL(string: "https://tangem.com")!),
                termsLink: .init(title: "Whale Swap Cashback Terms", url: URL(string: "https://tangem.com")!),
                actionButtonTitle: "Enroll"
            ),
            isPayoutNeeded: isPayoutNeeded,
            payoutTokens: []
        )
    }
}
