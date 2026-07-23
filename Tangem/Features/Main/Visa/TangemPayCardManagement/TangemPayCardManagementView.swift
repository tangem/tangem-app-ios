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
import TangemAccessibilityIdentifiers

struct TangemPayCardManagementView: View {
    @ObservedObject var viewModel: TangemPayCardManagementViewModel

    @State private var redesignedViewportHeight: CGFloat = 0

    var body: some View {
        redesignedBody
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
        } else {
            redesignedCarousel
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
                    .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.reissueCardRow)

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
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.cardManagementMoreButton)
            }
        }
    }
}

private extension TangemPayCardManagementView {
    enum Constants {
        static let legacyCarouselHeight: CGFloat = 230
    }
}
