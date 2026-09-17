//
//  TangemPayOrderCardTypeView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TangemPayOrderCardTypeView: View {
    @ObservedObject var viewModel: TangemPayOrderCardTypeViewModel

    @State private var scrollID: TangemPayOrderCardType?

    var body: some View {
        content
            .background { background }
            .safeAreaInset(edge: .bottom, spacing: 0) { footer }
            .topNavigation(
                title: Localization.tangempayOrderTypeTitle,
                leading: .none,
                onClose: viewModel.close
            )
    }

    private var background: some View {
        DesignSystem.Color.bgPrimary
            .overlay(alignment: .top) {
                (viewModel.isBasicTariff ? Assets.Visa.orderCardBgBasic : Assets.Visa.orderCardBgPlus)
                    .image
                    .resizable()
                    .scaledToFit()
            }
            .ignoresSafeArea()
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                carousel
                    .padding(.top, Constants.cardTopMargin)
                    .padding(.bottom, Constants.cardToTabsGap)

                TabNavigation(data: viewModel.cardTypes, selection: tabSelection)
                    .variant(.material)
                    .padding(.vertical, Constants.tabsVerticalPadding)

                infoRows
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    /// The tab and the carousel are separate analytics events, so each writes through its own entry point.
    private var tabSelection: Binding<TangemPayOrderCardType> {
        Binding(
            get: { viewModel.selectedCardType },
            set: { viewModel.onCardTypeTabTapped($0) }
        )
    }

    private var swipeSelection: Binding<TangemPayOrderCardType> {
        Binding(
            get: { viewModel.selectedCardType },
            set: { viewModel.onCardTypeSwiped($0) }
        )
    }

    // MARK: - Carousel

    @ViewBuilder
    private var carousel: some View {
        if #available(iOS 17.0, *) {
            centeredCarousel
        } else {
            legacyCarousel
        }
    }

    @available(iOS 17.0, *)
    private var centeredCarousel: some View {
        GeometryReader { proxy in
            let horizontalInset = max(0, (proxy.size.width - Constants.cardWidth) / 2)

            ScrollView(.horizontal) {
                HStack(spacing: Constants.cardSpacing) {
                    ForEach(viewModel.cardTypes) { cardType in
                        cardView(cardType)
                            .id(cardType)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrollID, anchor: .center)
            .scrollClipDisabled()
            .contentMargins(.horizontal, horizontalInset, for: .scrollContent)
            .onAppear { scrollID = viewModel.selectedCardType }
            .onChange(of: scrollID) { _, new in
                guard let new, viewModel.selectedCardType != new else { return }
                viewModel.onCardTypeSwiped(new)
            }
            .onChange(of: viewModel.selectedCardType) { _, new in
                guard scrollID != new else { return }
                withAnimation(Constants.carouselScrollAnimation) { scrollID = new }
            }
        }
        .frame(height: Constants.cardHeight)
    }

    private var legacyCarousel: some View {
        TabView(selection: swipeSelection) {
            ForEach(viewModel.cardTypes) { cardType in
                cardView(cardType)
                    .tag(cardType)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: Constants.cardHeight)
    }

    private func cardView(_ cardType: TangemPayOrderCardType) -> some View {
        KFImage(viewModel.imageURL(for: cardType))
            .placeholder { Assets.Visa.cardGhost.image.resizable() }
            .resizable()
            .scaledToFit()
            .frame(width: Constants.cardWidth, height: Constants.cardHeight)
    }

    // MARK: - Rows

    private var infoRows: some View {
        TangemPayOrderCardInfoRowsView(rows: viewModel.infoRows)
            .padding(.horizontal, Constants.rowsHorizontalPadding)
            .animation(.default, value: viewModel.selectedCardType)
    }

    // MARK: - Footer

    private var footer: some View {
        TangemUI.Button(
            label: AttributedString(Localization.tangempayOrderTypeSelect),
            accessibilityLabel: Localization.tangempayOrderTypeSelect,
            action: viewModel.select
        )
        .size(.x12)
        .styleType(.default)
        .horizontalLayout(.infinity)
        .disabled(!viewModel.isSelectEnabled)
        .padding(.horizontal, Constants.footerHorizontalPadding)
        .padding(.vertical, Constants.footerVerticalPadding)
        .background(alignment: .bottom) {
            BottomFadeWithBlur(backgroundColor: DesignSystem.Color.bgPrimary)
        }
    }
}

private extension TangemPayOrderCardTypeView {
    enum Constants {
        static let cardWidth: CGFloat = 266
        static let cardHeight: CGFloat = 172
        static let cardSpacing: CGFloat = 48

        /// Fixed, so that the card and the switcher hold their place whatever the selected type's row count is.
        static let cardTopMargin: CGFloat = 112
        static let cardToTabsGap: CGFloat = 152

        static let tabsVerticalPadding: CGFloat = 8
        static let rowsHorizontalPadding: CGFloat = 8
        static let footerHorizontalPadding: CGFloat = 16
        static let footerVerticalPadding: CGFloat = 12

        /// Mirrors the DS tab navigation's own selection timing so the card and the pill travel together.
        static let carouselScrollAnimation: Animation = .timingCurve(0.8, 0, 0.4, 1.2, duration: 0.4)
    }
}
