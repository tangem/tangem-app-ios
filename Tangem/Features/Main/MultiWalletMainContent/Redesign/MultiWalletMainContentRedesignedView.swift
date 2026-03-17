//
//  MultiWalletMainContentRedesignedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
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

    private var listContent: some View {
        let isLoading = viewModel.isLoadingTokenList
        let hasContent = !viewModel.plainSections.isEmpty || !viewModel.accountSections.isEmpty

        return ZStack(alignment: .top) {
            // Skeleton placeholders layer
            skeletonPlaceholders(isLoading: isLoading)
                .allowsHitTesting(false)

            // Real content layer
            if hasContent {
                VStack(spacing: 0) {
                    accountsList

                    plainTokensList
                }
                .opacity(isLoading ? 0 : 1)
            } else if !isLoading {
                emptyList
            }
        }
        .accessibilityIdentifier(MainAccessibilityIdentifiers.tokensList)
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

    private func skeletonPlaceholders(isLoading: Bool) -> some View {
        let accountCount = viewModel.accountSections.count

        return VStack(spacing: .unit(.x2)) {
            ForEach(0 ..< Constants.placeholderCount, id: \.self) { index in
                let hasMatchingAccount = index < accountCount

                if hasMatchingAccount {
                    // Matched: stays in tree, just fades opacity — no slide
                    RedesignedAccountSkeletonCardView()
                        .opacity(isLoading ? 1 : 0)
                } else if isLoading {
                    // Unmatched: removed from tree when loading ends → slides down
                    RedesignedAccountSkeletonCardView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Empty List

    private var emptyList: some View {
        MultiWalletTokenItemsEmptyView()
            .padding(.top, 96)
            .cornerRadiusContinuous(Constants.cornerRadius)
    }

    // MARK: - Accounts List

    private var accountsList: some View {
        LazyVStack(spacing: .unit(.x2)) {
            ForEach(viewModel.accountSections) { accountSection in
                ExpandableAccountItemView(viewModel: accountSection.model) {
                    LazyVStack(spacing: 0) {
                        tokenRowsContent(sections: accountSection.items, roundBottomCorners: true)
                    }
                }
                .cornerRadius(.unit(.x5))
                .backgroundColor(Constants.tokenListBackgroundColor)
            }
        }
    }

    // MARK: - Plain Tokens List

    private var plainTokensList: some View {
        LazyVStack(spacing: 0) {
            tokenRowsContent(sections: viewModel.plainSections)
        }
        .roundedBackground(with: Constants.tokenListBackgroundColor, padding: 0, radius: Constants.cornerRadius)
    }

    // MARK: - Token Rows Content

    private func tokenRowsContent(
        sections: [MultiWalletMainContentPlainSection],
        roundBottomCorners: Bool = false
    ) -> some View {
        ForEach(indexed: sections.indexed()) { sectionIndex, section in
            let hasTitle = section.model.title != nil
            let isFirstVisibleSection = hasTitle && sectionIndex == 0
            let topEdgeCornerRadius = isFirstVisibleSection ? Constants.cornerRadius : nil

            LazyVStack(spacing: .zero) {
                TokenSectionView(title: section.model.title, topEdgeCornerRadius: topEdgeCornerRadius)

                ForEach(indexed: section.items.indexed()) { itemIndex, item in
                    let isFirstItem = !hasTitle && sectionIndex == 0 && itemIndex == 0
                    let isLastItem = sectionIndex == sections.count - 1 && itemIndex == section.items.count - 1
                    let hasPromoBubble = viewModel.tokenItemPromoBubbleViewModel?.id == item.id
                    let promoBubbleViewModel = hasPromoBubble ? viewModel.tokenItemPromoBubbleViewModel : nil

                    tokenItemView(
                        item: item,
                        isFirstItem: isFirstItem,
                        roundedBottomCorners: roundBottomCorners && isLastItem,
                        promoBubbleViewModel: promoBubbleViewModel
                    )
                }
            }
        }
    }

    // MARK: - Token Item View with Promo Bubble

    private func tokenItemView(
        item: TokenItemViewModel,
        isFirstItem: Bool,
        roundedBottomCorners: Bool = false,
        promoBubbleViewModel: TokenItemPromoBubbleViewModel?
    ) -> some View {
        VStack(spacing: 0) {
            if let promoBubbleViewModel {
                TokenItemPromoBubbleView(
                    viewModel: promoBubbleViewModel,
                    position: isFirstItem ? .top : .normal
                )
            }

            MainPageTangemTokenRow(viewModel: item)
                .backgroundColor(Constants.tokenListBackgroundColor)
                .if(roundedBottomCorners) { view in
                    view.cornerRadiusContinuous(
                        bottomLeadingRadius: Constants.cornerRadius,
                        bottomTrailingRadius: Constants.cornerRadius
                    )
                }
                .overlay(alignment: .top) {
                    trianglePointer.opacity(promoBubbleViewModel == nil ? 0 : 1)
                }
        }
    }

    private var trianglePointer: some View {
        Triangle()
            .rotation(Angle(degrees: 180))
            .fill(Colors.Control.unchecked)
            .frame(width: 12, height: 8)
    }
}

// MARK: - Constants

private extension MultiWalletMainContentRedesignedView {
    enum Constants {
        static let placeholderCount = 3
        static let cornerRadius: CGFloat = .unit(.x5)
        static let tokenListBackgroundColor = Color.Tangem.Surface.level1
    }
}
