//
//  MultiWalletMainContentRedesignedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemNFT
import TangemUI
import TangemAssets
import TangemUIUtils
import TangemFoundation
import TangemLocalization
import TangemAccessibilityIdentifiers

struct MultiWalletMainContentRedesignedView: View {
    @ObservedObject var viewModel: MultiWalletMainContentViewModel

    var body: some View {
        VStack(spacing: .unit(.x4)) {
            notificationBanners

            listContent
                .accessibilityIdentifier(MainAccessibilityIdentifiers.tokensList)

            if let nftEntrypointViewModel = viewModel.nftEntrypointViewModel {
                TangemNFTEntrypointRow(viewModel: nftEntrypointViewModel)
            }

            if viewModel.isOrganizeTokensVisible {
                organizeButton
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoadingTokenList)
        .padding(.horizontal, .unit(.x3))
        .onDidAppear(perform: viewModel.onDidAppear)
        .onWillDisappear(perform: viewModel.onWillDisappear)
        .bindAlert($viewModel.error)
    }

    // MARK: - Notification Banners

    private var notificationBanners: some View {
        NotificationBannerContainer(
            items: viewModel.notificationBannerItems,
            stackingType: .carousel
        )
    }

    // MARK: - List Content

    @ViewBuilder
    private var listContent: some View {
        let isLoading = viewModel.isLoadingTokenList
        let hasContent = !viewModel.plainSections.isEmpty || !viewModel.accountSections.isEmpty

        if isLoading {
            skeletonPlaceholders
                .allowsHitTesting(false)
                .transition(.opacity)
        } else if hasContent {
            VStack(spacing: 0) {
                accountsList

                plainTokensList
            }
            .transition(.opacity)
        } else {
            emptyList
                .transition(.opacity)
        }
    }

    private var organizeButton: some View {
        TangemButton(
            content: .combined(
                text: AttributedString(Localization.organizeTokensTitle),
                icon: Assets.OrganizeTokens.filterIcon,
                iconPosition: .left
            ),
            action: viewModel.onOpenOrganizeTokensButtonTap
        )
        .setCornerStyle(.rounded)
        .setStyleType(.secondary)
        .setSize(.x9)
        .accessibilityIdentifier(MainAccessibilityIdentifiers.organizeTokensButton)
    }

    // MARK: - Skeleton Placeholders

    private var skeletonPlaceholders: some View {
        VStack(spacing: .unit(.x2)) {
            ForEach(0 ..< MultiWalletMainContentConstants.placeholderCount, id: \.self) { _ in
                RedesignedAccountSkeletonCardView()
            }
        }
    }

    // MARK: - Empty List

    private var emptyList: some View {
        VStack(spacing: .unit(.x2)) {
            MultiWalletTokenItemsEmptyView()
                .iconColor(Color.Tangem.Graphic.Neutral.quaternary)
                .textColor(Color.Tangem.Text.Neutral.tertiary)
                .spacing(.unit(.x5))

            TangemButton(
                content: .text(AttributedString(Localization.commonAddTokens)),
                action: viewModel.onAddTokensTap
            )
            .setCornerStyle(.rounded)
            .setStyleType(.secondary)
            .setSize(.x10)
            .setHorizontalLayout(.intrinsic)
        }
        .padding(.top, .unit(.x9))
    }

    // MARK: - Accounts List

    private var accountsList: some View {
        LazyVStack(spacing: .unit(.x2)) {
            ForEach(viewModel.accountSections) { accountSection in
                if #available(iOS 17.0, *) {
//                    _View(accountSection.model) { viewModel in
                    let viewModel = accountSection.model
                        ExpandableAccountItemView(viewModel: viewModel) {
                            LazyVStack(spacing: 0) {
                                tokenRowsContent(sections: accountSection.items, roundBottomCorners: true)
                            }
//                        }
                    }
                } else {
                    EmptyView()
                }
            }
        }
    }

    // MARK: - Plain Tokens List

    private var plainTokensList: some View {
        LazyVStack(spacing: 0) {
            tokenRowsContent(sections: viewModel.plainSections)
        }
        .roundedBackground(
            with: MultiWalletMainContentConstants.tokenListBackgroundColor,
            padding: 0,
            radius: MultiWalletMainContentConstants.cornerRadius
        )
    }

    // MARK: - Token Rows Content

    private func tokenRowsContent(
        sections: [MultiWalletMainContentPlainSection],
        roundBottomCorners: Bool = false
    ) -> some View {
        ForEach(indexed: sections.indexed()) { sectionIndex, section in
            let hasTitle = section.model.title != nil
            let isFirstVisibleSection = hasTitle && sectionIndex == 0
            let topEdgeCornerRadius = isFirstVisibleSection ? MultiWalletMainContentConstants.cornerRadius : nil

            LazyVStack(spacing: .zero) {
                TokenSectionView(
                    title: section.model.title,
                    topEdgeCornerRadius: topEdgeCornerRadius,
                    backgroundColor: MultiWalletMainContentConstants.tokenListBackgroundColor
                )

                ForEach(indexed: section.items.indexed()) { itemIndex, item in
                    let isLastItem = sectionIndex == sections.count - 1 && itemIndex == section.items.count - 1
                    let hasPromoBubble = viewModel.tokenItemPromoBubbleViewModel?.id == item.id
                    let promoBubbleViewModel = hasPromoBubble ? viewModel.tokenItemPromoBubbleViewModel : nil

                    TokenItemContainerView(
                        item: item,
                        roundedBottomCorners: roundBottomCorners && isLastItem,
                        promoBubbleViewModel: promoBubbleViewModel
                    )
                }
            }
        }
    }
}

// MARK: - TokenItemContainerView

private struct TokenItemContainerView: View {
    let item: TokenItemViewModel
    let roundedBottomCorners: Bool
    let promoBubbleViewModel: TokenItemPromoBubbleViewModel?

    var body: some View {
        VStack(alignment: .twoLineRowLeading, spacing: 0) {
            MainPageTangemTokenRow(viewModel: item)
                .backgroundColor(MultiWalletMainContentConstants.tokenListBackgroundColor)
                .if(roundedBottomCorners) { view in
                    view.cornerRadiusContinuous(
                        bottomLeadingRadius: MultiWalletMainContentConstants.cornerRadius,
                        bottomTrailingRadius: MultiWalletMainContentConstants.cornerRadius
                    )
                }

            if let promoBubbleViewModel {
                Button(action: promoBubbleViewModel.onTap) {
                    TangemCallout(
                        text: promoBubbleViewModel.message,
                        arrowAlignment: .top,
                        action: TangemCallout.Action(
                            icon: Assets.cross16.image,
                            closure: {
                                withAnimation {
                                    promoBubbleViewModel.onDismiss()
                                }
                            }
                        )
                    )
                    .icon(promoBubbleViewModel.leadingImage)
                    .colorPalette(.green)
                    .arrowAligned(to: .twoLineRowLeading)
                }
                .padding(.bottom, .unit(.x3))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Constants

private enum MultiWalletMainContentConstants {
    static let placeholderCount = 3
    static let cornerRadius: CGFloat = .unit(.x5)
    static let tokenListBackgroundColor = Color.Tangem.Surface.level3
}
