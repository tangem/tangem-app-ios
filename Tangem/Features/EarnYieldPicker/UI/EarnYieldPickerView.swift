//
//  EarnYieldPickerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct EarnYieldPickerView: View {
    @ObservedObject var viewModel: EarnYieldPickerViewModel

    @State private var presentedInfo: EarnProductDetails.InfoSheet?
    @State private var presentedInfoTitle = ""
    @State private var isTabsPinned = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        AnchoredSectionsScrollView(
            sections: viewModel.sections,
            isTabsPinned: $isTabsPinned,
            ignoresTopSafeArea: true,
            header: header(viewport:)
        ) {
            sections
        }
        .onChange(of: isTabsPinned) { isPinned in
            if isPinned {
                viewModel.video.pause()
            } else {
                viewModel.video.play()
            }
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .footer {
            Footer(.buttons(primary: primaryButton)).showFade()
        }
        .topNavigation(leading: .none, close: .enabled(viewModel.onClose)) {
            TopNavigationTitleContent(title: viewModel.selectedProduct.name)
                .opacity(isTabsPinned ? 1 : 0)
                .animation(reduceMotion ? nil : .easeInOut(duration: Constants.pinnedTitleFadeDuration), value: isTabsPinned)
                .accessibilityHidden(!isTabsPinned)
        }
        .environment(\.topNavigationDrawsBarBackground, false)
        .modal(
            item: $presentedInfo,
            contentLayout: .intrinsic,
            navigation: .title(presentedInfoTitle)
        ) { info in
            EarnProductInfoSheetView(sheet: info)
        }
    }
}

// MARK: - Header

private extension EarnYieldPickerView {
    func header(viewport: AnchoredSectionsViewport) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            hero(height: heroHeight(viewport: viewport))

            VStack(alignment: .leading, spacing: 0) {
                title
                chips
                productInfo
            }
            .padding(.top, -Constants.heroOverlap)
        }
    }

    func hero(height: CGFloat) -> some View {
        GeometryReader { proxy in
            let pull = max(0, proxy.frame(in: .named(AnchoredSections.coordinateSpace)).minY)

            LoopingVideoBackgroundView(viewModel: viewModel.video)
                .frame(width: proxy.size.width, height: height + pull)
                .clipped()
                .overlay(alignment: .bottom) { tint }
                .offset(y: -pull)
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    func heroHeight(viewport: AnchoredSectionsViewport) -> CGFloat {
        let screenHeight = viewport.frame.height + viewport.safeAreaInsets.top + viewport.safeAreaInsets.bottom
        return screenHeight * Constants.heroHeightRatio
    }

    var tint: some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: DesignSystem.Color.bgPrimary.opacity(0), location: 0),
                Gradient.Stop(color: DesignSystem.Color.bgPrimary, location: 0.5),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: Constants.tintHeight)
    }

    // [REDACTED_TODO_COMMENT]
    var title: some View {
        VStack(alignment: .leading, spacing: Constants.titleSpacing) {
            Text("Earn on your Ethereum")
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Choose type of product for gaining your balance")
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.blockVerticalPadding)
    }

    var chips: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Constants.chipSpacing) {
                    ForEach(viewModel.products) { product in
                        EarnYieldPickerProductChip(
                            name: product.name,
                            rate: viewModel.rate(of: product),
                            isSelected: product.id == viewModel.selectedProduct.id,
                            onTap: {
                                withAnimation(Constants.productSwitchAnimation) {
                                    viewModel.select(product)
                                }
                            }
                        )
                        .id(product.id)
                    }
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.blockVerticalPadding)
            }
            .onAppear {
                proxy.scrollTo(viewModel.selectedProduct.id, anchor: .center)
            }
            .onChange(of: viewModel.selectedProduct.id) { id in
                withAnimation(.easeInOut(duration: Constants.scrollDuration)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }

    var productInfo: some View {
        VStack(alignment: .leading, spacing: Constants.productInfoSpacing) {
            if let incentiveBadgeText = viewModel.incentiveBadgeText {
                SwiftUI.Button(action: viewModel.onIncentiveInfoTap) {
                    Badge(label: incentiveBadgeText, accessibilityLabel: nil)
                        .size(.x6)
                        .variant(.tinted)
                        .appearance(.info)
                        .slotEnd(DesignSystem.Icons.Info.regular16)
                }
                .buttonStyle(.plain)
            }

            Text(viewModel.selectedProduct.description)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.blockVerticalPadding)
    }
}

// MARK: - Sections

private extension EarnYieldPickerView {
    var sections: some View {
        VStack(spacing: Constants.sectionSpacing) {
            VStack(spacing: 0) {
                // [REDACTED_TODO_COMMENT]
                EarnProductSectionTitle(title: "Calculate your earnings")

                EarnCalculatorView(viewModel: viewModel.calculator, onIncentiveInfoTap: viewModel.onIncentiveInfoTap)
                    .padding(.horizontal, Constants.horizontalPadding)
            }
            .anchoredSection(EarnYieldPickerSection.calculator)

            if viewModel.sections.contains(.benefits) {
                EarnProductBenefitsView(benefits: viewModel.selectedProduct.details.benefits)
                    .anchoredSection(EarnYieldPickerSection.benefits)
            }

            EarnProductDetailsView(
                details: viewModel.selectedProduct.details,
                onLinkTap: viewModel.onLinkTap,
                onInfoTap: { info in
                    presentedInfoTitle = info.title
                    presentedInfo = info
                }
            )
            .anchoredSection(EarnYieldPickerSection.details)
        }
    }

    // [REDACTED_TODO_COMMENT]
    var primaryButton: TangemUI.Button {
        let label = switch viewModel.primaryAction {
        case .startEarning: "Start earning"
        case .addFunds: Localization.commonAddFunds
        }

        return TangemUI.Button(label: label, accessibilityLabel: nil, action: viewModel.onPrimaryActionTap)
            .styleType(.primary)
    }
}

// MARK: - Constants

private extension EarnYieldPickerView {
    enum Constants {
        static let heroHeightRatio: CGFloat = 722 / 874
        static let pinnedTitleFadeDuration: TimeInterval = 0.25
        static let heroOverlap: CGFloat = 217
        static let tintHeight: CGFloat = 264
        static let horizontalPadding: CGFloat = 24
        static let blockVerticalPadding: CGFloat = 12
        static let titleSpacing: CGFloat = 4
        static let chipSpacing: CGFloat = 8
        static let productInfoSpacing: CGFloat = 8
        static let sectionSpacing: CGFloat = 24
        static let scrollDuration: TimeInterval = 0.3
        static let productSwitchAnimation: Animation = .easeInOut(duration: 0.3)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        if let viewModel = EarnYieldPickerViewModel(
            products: [.pooledStakingPreview, .lendingOnAavePreview],
            selectedProductID: .lendingOnAave,
            balanceProvider: NFTSendFixedBalanceProvider(
                tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
                fixedValue: 1
            ),
            currencyCode: "USD",
            coordinator: nil
        ) {
            EarnYieldPickerView(viewModel: viewModel)
        }
    }
}
