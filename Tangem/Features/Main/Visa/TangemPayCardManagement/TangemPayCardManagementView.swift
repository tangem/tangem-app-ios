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
        content
    }

    private var content: some View {
        scrollableContent
            .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
            .disabled(viewModel.isLoadingReissueFee)
            .overlay { reissueLoadingOverlay }
            .safeAreaInset(edge: .bottom) { footer }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
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

    private var scrollableContent: some View {
        GeometryReader { proxy in
            ScrollView {
                contentStack
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
            }
        }
    }

    private var contentStack: some View {
        VStack(spacing: 0) {
            cardSection

            stateContent
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.contentState {
        case .renaming:
            EmptyView()

        case .closing:
            centered { TangemPayCardClosingMessageView() }

        case .plastic(let plastic, let email):
            centered { TangemPayPlasticCardMessageView(stage: plastic.messageStage, email: email) }

        case .issuing:
            centered {
                TangemPayCardIssuingMessageView()
                    .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.cardIssuingMessage)
            }

        case .reissuing:
            TangemPayReplacingCardBanner()
                .padding(.top, 28)

        case .details(let details):
            detailsSection(details)
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
    private var footer: some View {
        switch viewModel.contentState.footer {
        case .rename(let renameViewModel):
            TangemPayCardRenameToolbarView(renameViewModel: renameViewModel)

        case .plastic(let isActivateAvailable):
            plasticFooter
                .opacity(isActivateAvailable ? 1 : 0)
                .allowsHitTesting(isActivateAvailable)
                .animation(.easeInOut, value: isActivateAvailable)

        case .none:
            EmptyView()
        }
    }

    private var addToApplePayBanner: some View {
        TangemPayAddToApplePayBanner(
            openAction: viewModel.openAddToApplePayGuide,
            closeAction: viewModel.dismissAddToApplePayGuideBanner
        )
    }

    @ViewBuilder
    private var reissueLoadingOverlay: some View {
        if viewModel.isLoadingReissueFee {
            ZStack {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)

                ActivityIndicatorView(
                    style: .large,
                    color: UIColor(DesignSystem.Color.iconSecondary)
                )
            }
        }
    }

    @ViewBuilder
    private var cardSection: some View {
        if case .renaming(let renameViewModel) = viewModel.contentState {
            TangemPayCardRenameView(viewModel: renameViewModel)
        } else {
            carousel
        }
    }

    @ViewBuilder
    private var carousel: some View {
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
                        cardDetailsContent(for: item)
                    }
                    .padding(.horizontal, -16)
                } else {
                    TabView(selection: $viewModel.selectedCardId) {
                        ForEach(viewModel.cardDetailsItems) { item in
                            cardDetailsContent(for: item)
                                .tag(item.id as String?)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: Constants.legacyCarouselHeight)
                }

                pageIndicator
            }
        } else if let item = viewModel.cardDetailsItems.first {
            cardDetailsContent(for: item)
        }
    }

    @ViewBuilder
    private func cardDetailsContent(for item: TangemPayCardManagementViewModel.CardDetailsItem) -> some View {
        switch item.content {
        case .issued(let detailsViewModel):
            TangemPayCardDetailsView(viewModel: detailsViewModel)
        case .issuing:
            TangemPayIssuingCardDetailsView(isGhost: false)
        case .ghost, .plastic:
            TangemPayIssuingCardDetailsView(isGhost: true)
        }
    }

    private var plasticFooter: some View {
        VStack(spacing: Constants.plasticFooterSpacing) {
            TangemUI.Button(
                label: AttributedString(Localization.commonContactSupport),
                accessibilityLabel: Localization.commonContactSupport,
                action: viewModel.onContactSupportButton
            )
            .size(.x12)
            .styleType(.secondary(.default))
            .horizontalLayout(.infinity)
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.plasticContactSupportButton)

            TangemUI.Button(
                label: AttributedString(Localization.tangempayCardDetailsActivate),
                accessibilityLabel: Localization.tangempayCardDetailsActivate,
                action: viewModel.onActivatePlasticCardButton
            )
            .size(.x12)
            .styleType(.primary)
            .horizontalLayout(.infinity)
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.plasticActivateCardButton)
        }
        .padding(.horizontal, Constants.plasticFooterHorizontalPadding)
        .padding(.vertical, Constants.plasticFooterVerticalPadding)
    }

    private var pageIndicator: some View {
        TangemPayCardPageIndicator(
            count: viewModel.cardDetailsItems.count,
            selectedIndex: viewModel.cardDetailsItems.firstIndex { $0.id == viewModel.selectedCardId } ?? 0
        )
    }

    private func detailsSection(
        _ details: TangemPayCardManagementViewModel.ContentState.Details
    ) -> some View {
        VStack(spacing: 24) {
            if details.showsAddToAppleWalletButton {
                TangemPayAddToAppleWalletButton(action: viewModel.addToAppleWallet)
            }

            TangemPayCardActionButtonsView(
                isFrozen: details.freezingState.isFrozen,
                actionsDisabled: details.freezingState.isFreezingUnfreezingInProgress,
                detailsAction: viewModel.onDetailsButton,
                freezeAction: viewModel.onFreezeButton,
                pinAction: viewModel.onPinButton
            )

            VStack(spacing: 8) {
                if details.showsAddToApplePayGuide {
                    addToApplePayBanner
                }

                if let dailyLimitState = details.dailyLimitState {
                    TangemPayDailyLimitRow(
                        state: dailyLimitState,
                        isFrozen: details.freezingState.isFrozen,
                        changeAction: viewModel.openChangeDailyLimit
                    )
                }
            }
        }
        .animation(.easeInOut, value: details.showsAddToAppleWalletButton)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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

                            if let subtitle = viewModel.closeCardSubtitle {
                                Text(subtitle)
                            }
                        }
                        .disabled(closeCardRow.action == nil)
                        .accessibilityIdentifier(
                            viewModel.closeCardSubtitle == nil
                                ? TangemPayAccessibilityIdentifiers.closeCardRow
                                : TangemPayAccessibilityIdentifiers.closeCardRowLastCard
                        )
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
