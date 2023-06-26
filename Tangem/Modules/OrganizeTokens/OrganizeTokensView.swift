//
//  OrganizeTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensView: View {
    @ObservedObject private var viewModel: OrganizeTokensViewModel

    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "Use native 'safeAreaInset()' instead")
    @State private var scrollViewBottomContentInset = 0.0

    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "Use native 'safeAreaInset()' instead")
    @State private var scrollViewTopContentInset = 0.0

    @State private var tokenListFooterFrameMinY: CGFloat = 0.0
    @State private var tokenListContentFrameMaxY: CGFloat = 0.0
    @State private var isTokenListFooterGradientHidden = true

    init(viewModel: OrganizeTokensViewModel) {
        Self.setupAppearanceIfNeeded()  // [REDACTED_TODO_COMMENT]
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ZStack {
                tokenList

                tokenListHeader

                tokenListFooter
            }
            .background(
                Colors.Background
                    .secondary
                    .ignoresSafeArea(edges: [.vertical])
            )
            .navigationTitle(Localization.organizeTokensTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundCompat(.hidden, for: .navigationBar)
        }
    }

    private var tokenList: some View {
        ScrollView(showsIndicators: false) {
            Spacer(minLength: scrollViewTopContentInset)

            LazyVStack(spacing: 0.0) {
                let parametersProvider = OrganizeTokensListCornerRadiusParametersProvider(
                    sections: viewModel.sections,
                    cornerRadius: Constants.cornerRadius
                )

                ForEach(indexed: viewModel.sections.indexed()) { sectionIndex, sectionViewModel in
                    Section(
                        content: {
                            ForEach(indexed: sectionViewModel.items.indexed()) { itemIndex, itemViewModel in
                                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                                OrganizeTokensListItemView(viewModel: itemViewModel)
                                    .background(Colors.Background.primary)
                                    .cornerRadius(
                                        parametersProvider.cornerRadius(forItemAtIndexPath: indexPath),
                                        corners: parametersProvider.rectCorners(forItemAtIndexPath: indexPath)
                                    )
                            }
                        },
                        header: {
                            Group {
                                switch sectionViewModel.style {
                                case .invisible:
                                    EmptyView()
                                case .fixed(let title):
                                    OrganizeTokensListSectionView(title: title, isDraggable: false)
                                case .draggable(let title):
                                    OrganizeTokensListSectionView(title: title, isDraggable: true)
                                }
                            }
                            .background(Colors.Background.primary)
                            .cornerRadius(
                                parametersProvider.cornerRadius(forSectionAtIndex: sectionIndex),
                                corners: parametersProvider.rectCorners(forSectionAtIndex: sectionIndex)
                            )
                        }
                    )
                }
            }
            .padding(.horizontal, Constants.contentHorizontalInset)
            .readGeometry(to: $tokenListContentFrameMaxY, transform: \.frame.maxY)

            Spacer(minLength: scrollViewBottomContentInset)
        }
        .onChange(of: tokenListContentFrameMaxY) { newValue in
            withAnimation {
                isTokenListFooterGradientHidden = newValue < tokenListFooterFrameMinY
            }
        }
    }

    private var tokenListHeader: some View {
        OrganizeTokensHeaderView(viewModel: viewModel.headerViewModel)
            .readGeometry(transform: \.size.height) { height in
                scrollViewTopContentInset = height
                + Constants.overlayViewAdditionalVerticalInset
                + Constants.tokenListHeaderViewTopVerticalInset
            }
            .padding(.top, Constants.tokenListHeaderViewTopVerticalInset)
            .padding(.bottom, Constants.overlayViewAdditionalVerticalInset)
            .padding(.horizontal, Constants.contentHorizontalInset)
            .background(
                VisualEffectView(style: .systemUltraThinMaterial)   // [REDACTED_TODO_COMMENT]
                    .edgesIgnoringSafeArea(.top)
                    .infinityFrame(alignment: .bottom)
            )
            .infinityFrame(alignment: .top)
    }

    private var tokenListFooter: some View {
        HStack(spacing: 8.0) {
            Group {
                MainButton(
                    title: Localization.commonCancel,
                    style: .secondary,
                    action: viewModel.onCancelButtonTap
                )

                MainButton(
                    title: Localization.commonApply,
                    style: .primary,
                    action: viewModel.onApplyButtonTap
                )
            }
            .background(
                Colors.Background
                    .primary
                    .cornerRadiusContinuous(Constants.cornerRadius)
            )
        }
        .padding(.horizontal, Constants.contentHorizontalInset)
        .background(
            LinearGradient(
                colors: [Colors.Background.fadeStart, Colors.Background.fadeEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            .hidden(isTokenListFooterGradientHidden)
            .ignoresSafeArea()
            .frame(height: 100.0)
            .infinityFrame(alignment: .bottom)
        )
        .readGeometry { geometryInfo in
            tokenListFooterFrameMinY = geometryInfo.frame.minY
            scrollViewBottomContentInset = geometryInfo.size.height + Constants.overlayViewAdditionalVerticalInset
        }
        .infinityFrame(alignment: .bottom)
    }

    private static func setupAppearanceIfNeeded() {
        // [REDACTED_TODO_COMMENT]
        if #unavailable(iOS 16.0) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground()

            let appearance = UINavigationBar.appearance()
            appearance.compactAppearance = navBarAppearance
            appearance.standardAppearance = navBarAppearance
            appearance.scrollEdgeAppearance = navBarAppearance
            if #available(iOS 15.0, *) {
                appearance.compactScrollEdgeAppearance = navBarAppearance
            }
        }
    }
}

// MARK: - Constants

private extension OrganizeTokensView {
    enum Constants {
        static let cornerRadius = 14.0
        static let overlayViewAdditionalVerticalInset = 10.0
        static let tokenListHeaderViewTopVerticalInset = 8.0
        static let contentHorizontalInset = 16.0
    }
}

// MARK: - Previews

struct OrganizeTokensView_Preview: PreviewProvider {
    private static let previewProvider = OrganizeTokensPreviewProvider()

    static var previews: some View {
        let viewModels = [
            previewProvider.multipleSections(),
            previewProvider.singleMediumSection(),
            previewProvider.singleSmallSection(),
        ]

        Group {
            ForEach(viewModels.indexed(), id: \.0.self) { index, sections in
                OrganizeTokensView(
                    viewModel: .init(
                        coordinator: OrganizeTokensCoordinator(),
                        sections: sections
                    )
                )
            }
        }
        .background(Colors.Background.primary)
        .previewLayout(.sizeThatFits)
        .background(Colors.Background.secondary.ignoresSafeArea())
    }
}
