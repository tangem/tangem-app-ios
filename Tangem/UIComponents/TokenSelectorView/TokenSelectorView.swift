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

    private func scrollView(@ViewBuilder content: @escaping () -> some View) -> some View {
        ScrollViewReader { reader in
            GroupedScrollView(contentType: .lazy(spacing: 8)) {
                Color.clear.frame(height: 0)
                    .id(Constants.scrollToTopAnchorID)

                content()
                    .animation(.contentFrameUpdate, value: viewModel.contentVisibility)
            }
            .onChange(of: viewModel.scrollToTopTrigger) { _ in
                withAnimation {
                    reader.scrollTo(Constants.scrollToTopAnchorID, anchor: .top)
                }
            }
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
            tokenListContent(itemsCount: itemsCount).transition(.content)
        }

        if !viewModel.contentVisibility.isLoading {
            additionalContent
        }
    }

    @ViewBuilder
    private func tokenListContent(itemsCount: Int) -> some View {
        if let sectionHeaderConfiguration {
            sectionHeader(configuration: sectionHeaderConfiguration, itemsCount: itemsCount)
        }

        ForEach(viewModel.wallets) { TokenSelectorWalletItemView(viewModel: $0) }
    }

    private func sectionHeader(
        configuration: TokenSelectorViewModel.SectionHeaderConfiguration,
        itemsCount: Int
    ) -> some View {
        let itemsCountToDisplay = viewModel.itemsCountToDisplay(configuration: configuration, itemsCount: itemsCount)

        return HStack(spacing: 8) {
            Text(configuration.title)
                .style(Fonts.BoldStatic.title3, color: Colors.Text.primary1)

            if let itemsCountToDisplay {
                Text("\(itemsCountToDisplay)")
                    .style(Fonts.BoldStatic.title3, color: Colors.Text.tertiary)
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
}

extension TokenSelectorView {
    enum SearchType {
        case native
        case custom
    }

    private enum Constants {
        static var scrollToTopAnchorID: String { "TokenSelectorView.scrollToTopAnchor" }
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
