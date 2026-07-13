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
import TangemUIUtils
import TangemLocalization

struct TangemPayCardManagementView: View {
    @ObservedObject var viewModel: TangemPayCardManagementViewModel

    @State private var redesignedViewportHeight: CGFloat = 0

    var body: some View {
        if FeatureProvider.isAvailable(.tangemPaySpendRedesign) {
            redesignedBody
        } else {
            legacyBody
        }
    }

    private var legacyBody: some View {
        ScrollView {
            if viewModel.multipleCardsEnabled {
                multiCardContent
            } else {
                legacyContent
            }
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .disabled(viewModel.isLoadingReissueFee)
        .overlay {
            if viewModel.isLoadingReissueFee {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)

                    ActivityIndicatorView(
                        style: .large,
                        color: UIColor(Color.Tangem.Graphic.Neutral.tertiary)
                    )
                }
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            if let renameVM = viewModel.cardRenameViewModel {
                TangemPayCardRenameToolbarView(renameViewModel: renameVM)
            }
        })
        .toolbar {
            if let renameVM = viewModel.cardRenameViewModel {
                NavigationToolbarButton.close(placement: .topBarTrailing, action: renameVM.close)
            }
        }
        .navigationBarBackButtonHidden(viewModel.cardRenameViewModel != nil)
        .animation(.easeInOut, value: viewModel.cardRenameViewModel != nil)
        .sheet(item: $viewModel.addToApplePayGuideViewModel) {
            TangemPayAddToAppPayGuideView(viewModel: $0)
        }
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
    }

    // MARK: - Legacy single-card

    private var legacyContent: some View {
        VStack(spacing: 14) {
            Group {
                if let renameVM = viewModel.cardRenameViewModel {
                    TangemPayCardRenameView(viewModel: renameVM)
                } else if let detailsViewModel = viewModel.tangemPayCardDetailsViewModel {
                    TangemPayCardDetailsView(viewModel: detailsViewModel)
                }
            }
            .transition(.identity)

            if viewModel.cardRenameViewModel == nil {
                if viewModel.isReissuing {
                    TangemPayReplacingCardBanner()
                } else {
                    if viewModel.shouldDisplayAddToApplePayGuide {
                        Button(action: viewModel.openAddToApplePayGuide) {
                            TangemPayAddToApplePayBanner(closeAction: viewModel.dismissAddToApplePayGuideBanner)
                        }
                    }

                    if let dailyLimitState = viewModel.dailyLimitState {
                        TangemPayDailyLimitSectionView(
                            state: dailyLimitState,
                            isFrozen: viewModel.freezingState.isFrozen,
                            changeAction: viewModel.openChangeDailyLimit
                        )
                    }

                    GroupedSection(viewModel.cardSettingsRows) {
                        DefaultRowView(viewModel: $0)
                    } header: {
                        DefaultHeaderView(Localization.tangempayCardPageSettingsTitle)
                            .padding(.vertical, 12)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Multi-card

    private var multiCardContent: some View {
        VStack(spacing: 14) {
            Group {
                if let renameVM = viewModel.cardRenameViewModel {
                    TangemPayCardRenameView(viewModel: renameVM)
                        .padding(.horizontal, 16)
                } else {
                    cardDetailsCarousel
                    if viewModel.hasMultipleCards {
                        pageIndicator
                    }
                }
            }
            .transition(.identity)

            if viewModel.cardRenameViewModel == nil {
                if viewModel.isIssuing {
                    issuingBanner
                } else if viewModel.isReissuing {
                    TangemPayReplacingCardBanner()
                        .padding(.horizontal, 16)
                } else if viewModel.isClosing {
                    TangemPayClosingCardBanner()
                        .padding(.horizontal, 16)
                } else {
                    activeCardSections
                }
            }
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var activeCardSections: some View {
        if viewModel.shouldDisplayAddToApplePayGuide {
            Button(action: viewModel.openAddToApplePayGuide) {
                TangemPayAddToApplePayBanner(closeAction: viewModel.dismissAddToApplePayGuideBanner)
            }
            .padding(.horizontal, 16)
        }

        if let dailyLimitState = viewModel.dailyLimitState {
            TangemPayDailyLimitSectionView(
                state: dailyLimitState,
                isFrozen: viewModel.freezingState.isFrozen,
                changeAction: viewModel.openChangeDailyLimit
            )
            .padding(.horizontal, 16)
        }

        GroupedSection(viewModel.cardSettingsRows) {
            DefaultRowView(viewModel: $0)
        } header: {
            DefaultHeaderView(Localization.tangempayCardPageSettingsTitle)
                .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)

        GroupedSection(viewModel.closeCardRow) { row in
            DefaultRowView(viewModel: row)
                .appearance(row.action != nil ? .destructiveButton : .disabledDestructiveButton)
        }
        .padding(.horizontal, 16)
    }

    private var issuingBanner: some View {
        TangemPayIssuingCardBanner()
            .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var cardDetailsCarousel: some View {
        if viewModel.hasMultipleCards {
            if #available(iOS 17.0, *) {
                PeekingCarouselView(
                    items: viewModel.cardDetailsItems,
                    selectedID: $viewModel.selectedCardId
                ) { item in
                    cardDetailsContent(for: item)
                }
            } else {
                legacyTabViewCarousel
            }
        } else if let item = viewModel.cardDetailsItems.first {
            cardDetailsContent(for: item)
                .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func cardDetailsContent(for item: TangemPayCardManagementViewModel.CardDetailsItem) -> some View {
        switch item.content {
        case .issued(let detailsViewModel):
            TangemPayCardDetailsView(viewModel: detailsViewModel)
        case .issuing:
            TangemPayIssuingCardDetailsView()
        }
    }

    /// iOS 16 fallback — `PeekingCarouselView` requires iOS 17 scroll APIs.
    private var legacyTabViewCarousel: some View {
        TabView(selection: $viewModel.selectedCardId) {
            ForEach(viewModel.cardDetailsItems) { item in
                cardDetailsContent(for: item)
                    .tag(item.id as String?)
                    .padding(.horizontal, 16)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: Constants.legacyCarouselHeight)
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.cardDetailsItems) { item in
                let isSelected = item.id == viewModel.selectedCardId
                Capsule()
                    .fill(
                        isSelected
                            ? Colors.Text.primary1
                            : Colors.Text.tertiary.opacity(0.4)
                    )
                    .frame(width: isSelected ? 16 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
        }
    }

    // MARK: - Redesign

    private var redesignedBody: some View {
        redesignedContent
            .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
            .disabled(viewModel.isLoadingReissueFee)
            .overlay { redesignedReissueLoadingOverlay }
            .safeAreaInset(edge: .bottom) {
                if let renameVM = viewModel.cardRenameViewModel {
                    TangemPayCardRenameToolbarView(renameViewModel: renameVM)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { redesignedToolbar }
            .navigationBarBackButtonHidden(viewModel.cardRenameViewModel != nil)
            .animation(.easeInOut, value: viewModel.cardRenameViewModel != nil)
            .sheet(item: $viewModel.addToApplePayGuideViewModel) {
                TangemPayAddToAppPayGuideView(viewModel: $0)
            }
            .alert(item: $viewModel.alert) { $0.alert }
            .onAppear(perform: viewModel.onAppear)
            .modifyView { view in
                if #unavailable(iOS 26.0) {
                    view.backportTranslucentNavigationBar()
                } else {
                    view
                }
            }
            .redesigned()
    }

    private var redesignedContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                redesignedCardSection

                if viewModel.isIssuing {
                    Spacer(minLength: 0)

                    TangemPayCardIssuingMessageView()

                    Spacer(minLength: 0)
                } else if viewModel.isClosing {
                    Spacer(minLength: 0)

                    TangemPayCardClosingMessageView()

                    Spacer(minLength: 0)
                } else {
                    redesignedDetailsSection
                        .padding(.top, 28)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .frame(maxWidth: .infinity, minHeight: redesignedViewportHeight, alignment: .top)
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { redesignedViewportHeight = proxy.size.height }
                    .onChange(of: proxy.size.height) { newHeight in
                        redesignedViewportHeight = newHeight
                    }
            }
        }
    }

    private var redesignedAddToApplePayBanner: some View {
        TangemPayAddToApplePayBannerRedesigned(
            openAction: viewModel.openAddToApplePayGuide,
            closeAction: viewModel.dismissAddToApplePayGuideBanner
        )
    }

    @ViewBuilder
    private var redesignedReissueLoadingOverlay: some View {
        if viewModel.isLoadingReissueFee {
            ZStack {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)

                ActivityIndicatorView(
                    style: .large,
                    color: UIColor(Color.Tangem.Graphic.Neutral.tertiary)
                )
            }
        }
    }

    @ViewBuilder
    private var redesignedCardSection: some View {
        if let renameVM = viewModel.cardRenameViewModel {
            TangemPayCardRenameViewRedesigned(viewModel: renameVM)
        } else if viewModel.multipleCardsEnabled {
            redesignedCarousel
        } else if let detailsViewModel = viewModel.tangemPayCardDetailsViewModel {
            TangemPayCardDetailsViewRedesigned(viewModel: detailsViewModel)
        }
    }

    @ViewBuilder
    private var redesignedCarousel: some View {
        if viewModel.hasMultipleCards {
            VStack(spacing: 12) {
                if #available(iOS 17.0, *) {
                    PeekingCarouselView(
                        items: viewModel.cardDetailsItems,
                        selectedID: $viewModel.selectedCardId,
                        configuration: .init(
                            peek: 8,
                            spacing: 8
                        )
                    ) { item in
                        redesignedCardDetailsContent(for: item)
                    }
                    .padding(.horizontal, -16)
                } else {
                    TabView(selection: $viewModel.selectedCardId) {
                        ForEach(viewModel.cardDetailsItems) { item in
                            redesignedCardDetailsContent(for: item)
                                .tag(item.id as String?)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: Constants.legacyCarouselHeight)
                }

                redesignedPageIndicator
            }
        } else if let item = viewModel.cardDetailsItems.first {
            redesignedCardDetailsContent(for: item)
        }
    }

    @ViewBuilder
    private func redesignedCardDetailsContent(for item: TangemPayCardManagementViewModel.CardDetailsItem) -> some View {
        switch item.content {
        case .issued(let detailsViewModel):
            TangemPayCardDetailsViewRedesigned(viewModel: detailsViewModel)
        case .issuing:
            TangemPayIssuingCardDetailsViewRedesigned()
        }
    }

    private var redesignedPageIndicator: some View {
        TangemPayCardPageIndicatorRedesigned(
            count: viewModel.cardDetailsItems.count,
            selectedIndex: viewModel.cardDetailsItems.firstIndex { $0.id == viewModel.selectedCardId } ?? 0
        )
    }

    @ViewBuilder
    private var redesignedDetailsSection: some View {
        if viewModel.cardRenameViewModel == nil {
            if viewModel.isReissuing {
                TangemPayReplacingCardBanner()
            } else {
                VStack(spacing: 24) {
                    TangemPayCardActionButtonsView(
                        isFrozen: viewModel.freezingState.isFrozen,
                        actionsDisabled: viewModel.cardActionsDisabled,
                        detailsAction: viewModel.onDetailsButton,
                        freezeAction: viewModel.onFreezeButton,
                        pinAction: viewModel.onPinButton
                    )

                    VStack(spacing: 8) {
                        if viewModel.shouldDisplayAddToApplePayGuide {
                            redesignedAddToApplePayBanner
                        }

                        if let dailyLimitState = viewModel.dailyLimitState {
                            TangemPayDailyLimitRowRedesigned(
                                state: dailyLimitState,
                                isFrozen: viewModel.freezingState.isFrozen,
                                changeAction: viewModel.openChangeDailyLimit
                            )
                        }
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var redesignedToolbar: some ToolbarContent {
        if let renameVM = viewModel.cardRenameViewModel {
            NavigationToolbarButton.close(placement: .topBarTrailing, action: renameVM.close)
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: viewModel.onReplaceButton) {
                        Label {
                            Text(Localization.tangempayCardDetailsReissueCard)
                        } icon: {
                            DesignSystem.Icons.ArrowRefresh.regular20.image
                                .renderingMode(.template)
                        }
                    }

                    if let closeCardRow = viewModel.closeCardRow {
                        Divider()

                        Button {
                            closeCardRow.action?()
                        } label: {
                            Label {
                                Text(closeCardRow.title)
                            } icon: {
                                Image(systemName: "trash")
                            }
                        }
                        .disabled(closeCardRow.action == nil)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Colors.Icon.primary1)
                        .accessibilityLabel(Localization.commonMore)
                }
            }
        }
    }
}

private extension TangemPayCardManagementView {
    enum Constants {
        static let legacyCarouselHeight: CGFloat = 230
    }
}
