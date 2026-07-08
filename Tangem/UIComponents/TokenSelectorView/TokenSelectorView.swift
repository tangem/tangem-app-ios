//
//  TokenSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemFoundation

struct TokenSelectorView<EmptyContentView: View, AdditionalContentView: View, HeaderContentView: View>: View {
    @ObservedObject var viewModel: TokenSelectorViewModel
    private let emptyContentView: EmptyContentView
    private let headerContent: HeaderContentView
    private let additionalContent: AdditionalContentView

    private var searchType: SearchType?
    private var sectionHeaderConfiguration: TokenSelectorViewModel.SectionHeaderConfiguration?
    private var showsSeparators = true
    private var hidesSingleWalletName = false

    init(
        viewModel: TokenSelectorViewModel,
        @ViewBuilder emptyContentView: () -> EmptyContentView,
        @ViewBuilder headerContent: () -> HeaderContentView,
        @ViewBuilder additionalContent: () -> AdditionalContentView
    ) {
        self.viewModel = viewModel
        self.emptyContentView = emptyContentView()
        self.additionalContent = additionalContent()
        self.headerContent = headerContent()
    }

    var body: some View {
        switch searchType {
        case .native:
            scrollView {
                scrollContent
            }
            .searchable(text: $viewModel.searchText)
            .keyboardType(.asciiCapable)
            .autocorrectionDisabled()

        case .custom:
            scrollView {
                CustomSearchBar(
                    searchText: $viewModel.searchText,
                    placeholder: Localization.commonSearch,
                    style: .focused
                )

                scrollContent
            }

        case .none:
            scrollView { scrollContent }
        }
    }

    private var isRedesignedLayout: Bool {
        FeatureProvider.isAvailable(.redesign)
    }

    private func scrollView(@ViewBuilder content: @escaping () -> some View) -> some View {
        ScrollViewReader { reader in
            GroupedScrollView(contentType: .lazy(spacing: 8)) {
                content()
                    .overlay(alignment: .top) {
                        Color.clear.frame(height: 0).id(Constants.scrollToTopAnchorID)
                    }
                    .animation(.contentFrameUpdate, value: viewModel.contentVisibility)
            }
            .onChange(of: viewModel.scrollToTopTrigger) { _ in
                withAnimation {
                    reader.scrollTo(Constants.scrollToTopAnchorID, anchor: .top)
                }
            }
            .environment(\.tokenSelectorShowsSeparators, showsSeparators)
            .environment(\.tokenSelectorHidesWalletNameHeader, hidesSingleWalletName && viewModel.wallets.count == 1)
        }
    }

    @ViewBuilder
    private var scrollContent: some View {
        if !viewModel.contentVisibility.isEmpty {
            headerContent
        }

        switch viewModel.contentVisibility {
        case .empty:
            emptyContentView.transition(.move(edge: .top).combined(with: .opacity))
        case .loading:
            TokenSelectorLoadingView().transition(.content)
        case .visible(let itemsCount):
            // zIndex keeps the token list above other content during animated transitions
            tokenListContent(itemsCount: itemsCount).transition(.content).zIndex(1)
        }

        if !viewModel.contentVisibility.isLoading {
            additionalContent.transition(.content)
        }
    }

    @ViewBuilder
    private func tokenListContent(itemsCount: Int) -> some View {
        if let sectionHeaderConfiguration {
            sectionHeader(configuration: sectionHeaderConfiguration, itemsCount: itemsCount)
        }

        walletsSection
    }

    @ViewBuilder
    private var walletsSection: some View {
        if viewModel.walletChips.count > 1 {
            walletChipsView

            // Zero spacing prevents hidden (filtered-out) wallets from adding gaps between chips and the visible wallet
            VStack(spacing: 0) {
                ForEach(viewModel.wallets) {
                    TokenSelectorWalletItemView(viewModel: $0)
                }
            }
        } else {
            ForEach(viewModel.wallets) { TokenSelectorWalletItemView(viewModel: $0) }
        }
    }

    @ViewBuilder
    private var walletChipsView: some View {
        if isRedesignedLayout {
            redesignedWalletChipsView
        } else {
            HorizontalChipsView(
                chips: viewModel.walletChips.map { Chip(id: $0.id, title: $0.name) },
                selectedId: $viewModel.selectedChipId,
                horizontalInset: 8
            )
        }
    }

    private var redesignedWalletChipsView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Constants.redesignedChipsSpacing) {
                    ForEach(viewModel.walletChips) { chip in
                        redesignedWalletChip(chip)
                            .id(chip.id)
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: Constants.redesignedChipHeight)
            .onAppear {
                // Defer to the next runloop so the chips are laid out before scrolling to the preselected one.
                DispatchQueue.main.async {
                    scrollToSelectedChip(using: proxy, animated: false)
                }
            }
            .onChange(of: viewModel.selectedChipId) { _ in
                scrollToSelectedChip(using: proxy, animated: true)
            }
        }
    }

    private func scrollToSelectedChip(using proxy: ScrollViewProxy, animated: Bool) {
        guard let selectedChipId = viewModel.selectedChipId else { return }

        if animated {
            withAnimation { proxy.scrollTo(selectedChipId, anchor: .center) }
        } else {
            proxy.scrollTo(selectedChipId, anchor: .center)
        }
    }

    private func redesignedWalletChip(_ chip: TokenSelectorViewModel.WalletChipData) -> some View {
        let isSelected = viewModel.selectedChipId == chip.id

        return Button {
            if viewModel.selectedChipId != chip.id {
                viewModel.selectedChipId = chip.id
            }
        } label: {
            HStack(spacing: Constants.redesignedChipIconSpacing) {
                Text(chip.name)
                    .style(
                        Fonts.Bold.subheadline,
                        color: isSelected
                            ? Color.Tangem.Tabs.textPrimary
                            : Color.Tangem.Tabs.textSecondary
                    )
                    .lineLimit(1)

                if let thumbnail = chip.thumbnail {
                    MiniatureWalletView(type: thumbnail)
                        .frame(
                            width: Constants.redesignedChipIconSide,
                            height: Constants.redesignedChipIconSide
                        )
                }
            }
            .padding(.horizontal, Constants.redesignedChipHorizontalPadding)
            .frame(height: Constants.redesignedChipHeight)
            .background(
                RoundedRectangle(
                    cornerRadius: Constants.redesignedChipCornerRadius,
                    style: .continuous
                )
                .fill(
                    isSelected
                        ? Color.Tangem.Tabs.backgroundPrimary
                        : Color.Tangem.Tabs.backgroundSecondary
                )
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(
        configuration: TokenSelectorViewModel.SectionHeaderConfiguration,
        itemsCount: Int
    ) -> some View {
        let itemsCountToDisplay = viewModel.itemsCountToDisplay(configuration: configuration, itemsCount: itemsCount)

        return HStack(spacing: 8) {
            if isRedesignedLayout {
                Text(configuration.title)
                    .style(.Tangem.Heading20.semibold.font, color: .Tangem.Text.Neutral.primary)

                if let itemsCountToDisplay {
                    Text("\(itemsCountToDisplay)")
                        .style(.Tangem.Heading20.semibold.font, color: .Tangem.Text.Neutral.tertiary)
                }
            } else {
                Text(configuration.title)
                    .style(Fonts.BoldStatic.title3, color: Colors.Text.primary1)

                if let itemsCountToDisplay {
                    Text("\(itemsCountToDisplay)")
                        .style(Fonts.BoldStatic.title3, color: Colors.Text.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}

// MARK: - Setupable

extension TokenSelectorView: Setupable {
    func searchType(_ searchType: SearchType) -> Self {
        map { $0.searchType = searchType }
    }

    func sectionHeader(_ configuration: TokenSelectorViewModel.SectionHeaderConfiguration) -> Self {
        map { $0.sectionHeaderConfiguration = configuration }
    }

    func showsSeparators(_ showsSeparators: Bool) -> Self {
        map { $0.showsSeparators = showsSeparators }
    }

    /// Hides the wallet-name section header when the selector contains a single wallet (the name is redundant then).
    func hidesSingleWalletName(_ hidesSingleWalletName: Bool) -> Self {
        map { $0.hidesSingleWalletName = hidesSingleWalletName }
    }
}

extension TokenSelectorView {
    enum SearchType {
        case native
        case custom
    }

    private enum Constants {
        static var scrollToTopAnchorID: String { "TokenSelectorView.scrollToTopAnchor" }
        static var chipsToListExtraSpacing: CGFloat { 8 }
        static var redesignedChipHeight: CGFloat { 36 }
        static var redesignedChipCornerRadius: CGFloat { 24 }
        static var redesignedChipsSpacing: CGFloat { 8 }
        static var redesignedChipHorizontalPadding: CGFloat { 14 }
        static var redesignedChipIconSpacing: CGFloat { 6 }
        static var redesignedChipIconSide: CGFloat { 20 }
    }
}

// MARK: - Convenience init

extension TokenSelectorView where AdditionalContentView == EmptyView, HeaderContentView == EmptyView {
    init(
        viewModel: TokenSelectorViewModel,
        @ViewBuilder emptyContentView: () -> EmptyContentView
    ) {
        self.init(
            viewModel: viewModel,
            emptyContentView: emptyContentView,
            headerContent: { EmptyView() },
            additionalContent: { EmptyView() }
        )
    }
}

extension TokenSelectorView where AdditionalContentView == EmptyView {
    init(
        viewModel: TokenSelectorViewModel,
        @ViewBuilder emptyContentView: () -> EmptyContentView,
        @ViewBuilder headerContent: () -> HeaderContentView
    ) {
        self.init(
            viewModel: viewModel,
            emptyContentView: emptyContentView,
            headerContent: headerContent,
            additionalContent: { EmptyView() }
        )
    }
}

extension TokenSelectorView where HeaderContentView == EmptyView {
    init(
        viewModel: TokenSelectorViewModel,
        @ViewBuilder emptyContentView: () -> EmptyContentView,
        @ViewBuilder additionalContent: () -> AdditionalContentView
    ) {
        self.init(
            viewModel: viewModel,
            emptyContentView: emptyContentView,
            headerContent: { EmptyView() },
            additionalContent: additionalContent
        )
    }
}

// MARK: - Animations and Transitions

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.1))
    )
}

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
