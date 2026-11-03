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
    @State private var currentSection: EarnYieldPickerSection = .calculator
    @State private var isTabsPinned = false
    @State private var pendingSection: EarnYieldPickerSection?
    @State private var viewport = ScrollMeasurement.zero
    @State private var scrollFrames = ScrollFrames()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    header

                    tabs(proxy)
                        .scrollMarker(.tabs)
                        .opacity(isTabsPinned ? 0 : 1)
                        .accessibilityHidden(isTabsPinned)
                        .padding(.top, Constants.sectionSpacing)

                    sections
                        .padding(.top, Constants.sectionSpacing)
                }
                .scrollMarker(.content)
            }
            .coordinateSpace(name: Constants.scrollSpace)
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .scrollMarker(.viewport, in: .local)
            .onPreferenceChange(ScrollMarkersKey.self, perform: updateLayout)
            .overlay(alignment: .top) {
                if isTabsPinned {
                    pinnedTabs(proxy)
                }
            }
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .footer {
            Footer(.buttons(primary: primaryButton)).showFade()
        }
        .topNavigation(
            title: isTabsPinned ? viewModel.selectedProduct.name : "",
            leading: .none,
            close: .enabled(viewModel.onClose)
        )
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
    var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            LoopingVideoBackgroundView(viewModel: viewModel.video)
                .frame(height: heroHeight)
                .clipped()
                .overlay(alignment: .bottom) { tint }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                title
                chips
                productInfo
            }
            .padding(.top, -Constants.heroOverlap)
        }
    }

    var heroHeight: CGFloat {
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

// MARK: - Tabs

private extension EarnYieldPickerView {
    func tabs(_ proxy: ScrollViewProxy) -> some View {
        TabNavigation(data: viewModel.sections, selection: sectionBinding(proxy))
            .scrollable()
            .padding(.horizontal, Constants.tabsExtraHorizontalPadding)
    }

    func pinnedTabs(_ proxy: ScrollViewProxy) -> some View {
        tabs(proxy)
            .padding(.vertical, Constants.pinnedTabsVerticalPadding)
            .background {
                Fade(position: .top)
                    .variant(.hard)
                    .padding(.bottom, -Constants.pinnedFadeTail)
                    .ignoresSafeArea(edges: .top)
            }
    }

    func sectionBinding(_ proxy: ScrollViewProxy) -> Binding<EarnYieldPickerSection> {
        Binding(
            get: { currentSection },
            set: { section in
                currentSection = section
                pendingSection = section

                withAnimation(.easeInOut(duration: Constants.scrollDuration)) {
                    proxy.scrollTo(SectionAnchor(section: section), anchor: sectionAnchor)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.scrollDuration) {
                    if pendingSection == section {
                        pendingSection = nil
                    }
                }
            }
        )
    }

    var sectionsEdge: CGFloat {
        viewport.safeAreaInsets.top + (scrollFrames.values[.tabs]?.height ?? 0) + Constants.pinnedTabsVerticalPadding * 2
    }

    var visibleBottom: CGFloat {
        viewport.safeAreaInsets.top + viewport.frame.height
    }

    var sectionAnchor: UnitPoint {
        guard visibleBottom > 0 else {
            return .top
        }

        return UnitPoint(x: 0.5, y: sectionsEdge / visibleBottom)
    }

    func sectionTop(_ section: EarnYieldPickerSection) -> CGFloat {
        scrollFrames.values[.section(section)]?.minY ?? .infinity
    }

    func updateLayout(_ measurements: [ScrollMarker: ScrollMeasurement]) {
        if let measuredViewport = measurements[.viewport], measuredViewport != viewport {
            viewport = measuredViewport
        }

        scrollFrames.values = measurements.mapValues(\.frame)

        if let tabsFrame = scrollFrames.values[.tabs] {
            let isPinned = tabsFrame.minY <= viewport.safeAreaInsets.top + Constants.pinnedTabsVerticalPadding

            if isPinned != isTabsPinned {
                isTabsPinned = isPinned

                if isPinned {
                    viewModel.video.pause()
                } else {
                    viewModel.video.play()
                }
            }
        }

        updateCurrentSection()
    }

    func updateCurrentSection() {
        guard pendingSection == nil, let contentBottom = scrollFrames.values[.content]?.maxY else {
            return
        }

        let section = EarnYieldPickerSection.current(
            sectionTops: Dictionary(uniqueKeysWithValues: EarnYieldPickerSection.allCases.map { ($0, sectionTop($0)) }),
            pinnedEdge: sectionsEdge + Constants.sectionEdgeTolerance,
            visibleBottom: visibleBottom,
            remainingScroll: contentBottom - visibleBottom
        )

        if section != currentSection {
            currentSection = section
        }
    }
}

// MARK: - Sections

private extension EarnYieldPickerView {
    var sections: some View {
        VStack(spacing: Constants.sectionSpacing) {
            section(.calculator) {
                VStack(spacing: 0) {
                    // [REDACTED_TODO_COMMENT]
                    EarnProductSectionTitle(title: "Calculate your earnings")

                    EarnCalculatorView(viewModel: viewModel.calculator, onIncentiveInfoTap: viewModel.onIncentiveInfoTap)
                        .padding(.horizontal, Constants.horizontalPadding)
                }
            }

            if viewModel.sections.contains(.benefits) {
                section(.benefits) {
                    EarnProductBenefitsView(benefits: viewModel.selectedProduct.details.benefits)
                }
            }

            section(.details) {
                EarnProductDetailsView(
                    details: viewModel.selectedProduct.details,
                    onLinkTap: viewModel.onLinkTap,
                    onInfoTap: { info in
                        presentedInfoTitle = info.title
                        presentedInfo = info
                    }
                )
            }
        }
    }

    func section(_ section: EarnYieldPickerSection, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 0)
                .id(SectionAnchor(section: section))
                .scrollMarker(.section(section))

            content()
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

// MARK: - Scroll geometry

private extension EarnYieldPickerView {
    struct SectionAnchor: Hashable {
        let section: EarnYieldPickerSection
    }

    final class ScrollFrames {
        var values: [ScrollMarker: CGRect] = [:]
    }

    enum ScrollMarker: Hashable {
        case viewport
        case content
        case tabs
        case section(EarnYieldPickerSection)
    }

    struct ScrollMeasurement: Equatable {
        static let zero = ScrollMeasurement(frame: .zero, safeAreaInsets: EdgeInsets())

        let frame: CGRect
        let safeAreaInsets: EdgeInsets
    }

    struct ScrollMarkersKey: PreferenceKey {
        static let defaultValue: [ScrollMarker: ScrollMeasurement] = [:]

        static func reduce(value: inout [ScrollMarker: ScrollMeasurement], nextValue: () -> [ScrollMarker: ScrollMeasurement]) {
            value.merge(nextValue()) { $1 }
        }
    }
}

private extension View {
    func scrollMarker(
        _ marker: EarnYieldPickerView.ScrollMarker,
        in coordinateSpace: CoordinateSpace = .named(EarnYieldPickerView.Constants.scrollSpace)
    ) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: EarnYieldPickerView.ScrollMarkersKey.self,
                    value: [marker: EarnYieldPickerView.ScrollMeasurement(frame: proxy.frame(in: coordinateSpace), safeAreaInsets: proxy.safeAreaInsets)]
                )
            }
        }
    }
}

// MARK: - Constants

private extension EarnYieldPickerView {
    enum Constants {
        static let scrollSpace = "EarnYieldPickerScroll"
        static let heroHeightRatio: CGFloat = 722 / 874
        static let heroOverlap: CGFloat = 217
        static let tintHeight: CGFloat = 264
        static let horizontalPadding: CGFloat = 24
        static let blockVerticalPadding: CGFloat = 12
        static let titleSpacing: CGFloat = 4
        static let chipSpacing: CGFloat = 8
        static let productInfoSpacing: CGFloat = 8
        static let sectionSpacing: CGFloat = 24
        static let tabsExtraHorizontalPadding: CGFloat = 8
        static let pinnedTabsVerticalPadding: CGFloat = 12
        static let pinnedFadeTail: CGFloat = 8
        static let sectionEdgeTolerance: CGFloat = 1
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
