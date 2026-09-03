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

    var body: some View {
        redesignedBody
    }

    // MARK: - Redesign

    private var redesignedBody: some View {
        redesignedContent
            .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
            .disabled(viewModel.isLoadingReissueFee)
            .overlay { redesignedReissueLoadingOverlay }
            .safeAreaInset(edge: .bottom) { redesignedFooter }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { redesignedToolbar }
            .navigationBarBackButtonHidden(viewModel.contentState.isRenaming)
            .animation(.easeInOut, value: viewModel.contentState.isRenaming)
            .sheet(item: $viewModel.addToApplePayGuideViewModel) {
                TangemPayAddToAppPayGuideView(viewModel: $0)
            }
            .alert(item: $viewModel.alert) { $0.alert }
            .onAppear(perform: viewModel.onAppear)
            .translucentNavigationBar()
            .redesigned()
    }

    private var redesignedContent: some View {
        GeometryReader { proxy in
            ScrollView {
                redesignedContentStack
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
            }
        }
    }

    private var redesignedContentStack: some View {
        VStack(spacing: 0) {
            redesignedCardSection

            redesignedStateContent
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    @ViewBuilder
    private var redesignedStateContent: some View {
        switch viewModel.contentState {
        case .renaming:
            EmptyView()

        case .closing:
            centered { TangemPayCardClosingMessageView() }

        case .plastic(let plastic, let email):
            centered { TangemPayPlasticCardMessageView(stage: plastic.messageStage, email: email) }

        case .issuing:
            centered { TangemPayCardIssuingMessageView() }

        case .reissuing:
            TangemPayReplacingCardBanner()
                .padding(.top, 28)

        case .details(let details):
            redesignedDetailsSection(details)
                .padding(.top, 28)
        }
    }

    @ViewBuilder
    private func centered(@ViewBuilder content: () -> some View) -> some View {
        Spacer(minLength: 0)

        content()

        Spacer(minLength: 0)
    }

    @ViewBuilder
    private var redesignedFooter: some View {
        switch viewModel.contentState.footer {
        case .rename(let renameViewModel):
            TangemPayCardRenameToolbarView(renameViewModel: renameViewModel)

        case .plastic(let isActivateAvailable):
            redesignedPlasticFooter
                .opacity(isActivateAvailable ? 1 : 0)
                .allowsHitTesting(isActivateAvailable)
                .animation(.easeInOut, value: isActivateAvailable)

        case .none:
            EmptyView()
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
        if case .renaming(let renameViewModel) = viewModel.contentState {
            TangemPayCardRenameViewRedesigned(viewModel: renameViewModel)
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
            TangemPayIssuingCardDetailsViewRedesigned(isGhost: false)
        case .ghost, .plastic:
            TangemPayIssuingCardDetailsViewRedesigned(isGhost: true)
        }
    }

    private var redesignedPlasticFooter: some View {
        VStack(spacing: Constants.plasticFooterSpacing) {
            TangemUI.Button(
                label: AttributedString(Localization.commonContactSupport),
                accessibilityLabel: Localization.commonContactSupport,
                action: viewModel.onContactSupportButton
            )
            .size(.x12)
            .styleType(.secondary)
            .horizontalLayout(.infinity)

            TangemUI.Button(
                label: AttributedString(Localization.tangempayCardDetailsActivate),
                accessibilityLabel: Localization.tangempayCardDetailsActivate,
                action: viewModel.onActivatePlasticCardButton
            )
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
        }
        .padding(.horizontal, Constants.plasticFooterHorizontalPadding)
        .padding(.vertical, Constants.plasticFooterVerticalPadding)
    }

    private var redesignedPageIndicator: some View {
        TangemPayCardPageIndicatorRedesigned(
            count: viewModel.cardDetailsItems.count,
            selectedIndex: viewModel.cardDetailsItems.firstIndex { $0.id == viewModel.selectedCardId } ?? 0
        )
    }

    private func redesignedDetailsSection(
        _ details: TangemPayCardManagementViewModel.ContentState.Details
    ) -> some View {
        VStack(spacing: 24) {
            TangemPayCardActionButtonsView(
                isFrozen: details.freezingState.isFrozen,
                actionsDisabled: details.freezingState.isFreezingUnfreezingInProgress,
                detailsAction: viewModel.onDetailsButton,
                freezeAction: viewModel.onFreezeButton,
                pinAction: viewModel.onPinButton
            )

            VStack(spacing: 8) {
                if details.showsAddToApplePayGuide {
                    redesignedAddToApplePayBanner
                }

                if let dailyLimitState = details.dailyLimitState {
                    TangemPayDailyLimitRowRedesigned(
                        state: dailyLimitState,
                        isFrozen: details.freezingState.isFrozen,
                        changeAction: viewModel.openChangeDailyLimit
                    )
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var redesignedToolbar: some ToolbarContent {
        if case .renaming(let renameVM) = viewModel.contentState {
            NavigationToolbarButton.close(placement: .topBarTrailing, action: renameVM.close)
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.cardRenameCloseButton)
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if viewModel.contentState.isReplaceCardAvailable {
                        SwiftUI.Button(action: viewModel.onReplaceButton) {
                            Label {
                                Text(Localization.tangempayCardDetailsReissueCard)
                            } icon: {
                                DesignSystem.Icons.ArrowRefresh.regular20.image
                                    .renderingMode(.template)
                            }
                        }
                        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.reissueCardRow)
                    }

                    if let closeCardRow = viewModel.closeCardRow {
                        Divider()

                        SwiftUI.Button {
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
        static let plasticFooterSpacing: CGFloat = 10
        static let plasticFooterHorizontalPadding: CGFloat = 16
        static let plasticFooterVerticalPadding: CGFloat = 12
    }
}
