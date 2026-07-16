//
//  ManageTokensListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

struct ManageTokensListView<Header, Footer>: View where Header: View, Footer: View {
    typealias HeaderFactory = () -> Header?
    typealias FooterFactory = () -> Footer?

    @ObservedObject var viewModel: ManageTokensListViewModel
    let isReadOnly: Bool
    let header: Header?
    let footer: Footer?

    private var contentOffsetObserver: Binding<CGPoint>? = nil
    private var backgroundColor: Color = .clear
    private var roundedCornersEnabled: Bool = false
    private var cornerRadius: CGFloat = Constants.cornerRadius
    private let bottomPadding: CGFloat

    init(
        viewModel: ManageTokensListViewModel,
        bottomPadding: CGFloat = Constants.bottomPadding,
        isReadOnly: Bool = false,
        @ViewBuilder header: HeaderFactory,
        @ViewBuilder footer: FooterFactory
    ) {
        self.viewModel = viewModel
        self.bottomPadding = bottomPadding
        self.isReadOnly = isReadOnly
        self.header = header()
        self.footer = footer()
    }

    init(
        viewModel: ManageTokensListViewModel,
        bottomPadding: CGFloat = Constants.bottomPadding,
        isReadOnly: Bool = false,
        @ViewBuilder header: HeaderFactory
    ) where Footer == EmptyView {
        self.viewModel = viewModel
        self.bottomPadding = bottomPadding
        self.isReadOnly = isReadOnly
        self.header = header()
        footer = nil
    }

    init(
        viewModel: ManageTokensListViewModel,
        bottomPadding: CGFloat = Constants.bottomPadding,
        isReadOnly: Bool = false
    ) where Header == EmptyView, Footer == EmptyView {
        self.viewModel = viewModel
        self.bottomPadding = bottomPadding
        self.isReadOnly = isReadOnly
        header = nil
        footer = nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                if let header {
                    header
                }

                tokenList

                if let footer {
                    footer
                }
            }
            .padding(.bottom, bottomPadding)
            .readContentOffset(inCoordinateSpace: .named(CoordinateSpaceName.scrollView)) { value in
                contentOffsetObserver?.wrappedValue = value
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .clipShape(RoundedRectangle(cornerRadius: roundedCornersEnabled ? cornerRadius : .zero, style: .continuous))
        .coordinateSpace(name: CoordinateSpaceName.scrollView)
    }

    private var tokenList: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.tokenListItemModels) {
                ManageTokensListItemView(viewModel: $0, isReadOnly: isReadOnly)
            }

            if viewModel.hasNextPage {
                ManageTokensListLoaderView()
                    .onAppear(perform: viewModel.fetch)
            }
        }
    }
}

extension ManageTokensListView: Setupable {
    func addContentOffsetObserver(_ observer: Binding<CGPoint>) -> Self {
        map {
            $0.contentOffsetObserver = observer
        }
    }

    func backgroundColor(_ color: Color) -> Self {
        map {
            $0.backgroundColor = color
        }
    }

    func roundedCorners(_ enabled: Bool, radius: CGFloat = Constants.cornerRadius) -> Self {
        map {
            $0.roundedCornersEnabled = enabled
            $0.cornerRadius = radius
        }
    }
}

extension ManageTokensListView {
    enum Constants {
        static var bottomPadding: CGFloat { 60 }
        static var cornerRadius: CGFloat { 14 }
    }
}

private enum CoordinateSpaceName {
    static let prefix = "ManageTokensListView.CoordinateSpaceName."

    static let scrollView = prefix + "scrollView"
}
