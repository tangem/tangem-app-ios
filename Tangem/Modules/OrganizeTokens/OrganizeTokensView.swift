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

    @available(iOS, deprecated: 15.0, message: "Use native 'safeAreaInset()' instead")
    @State private var scrollViewBottomContentInset = 0.0

    @available(iOS, deprecated: 15.0, message: "Use native 'safeAreaInset()' instead")
    @State private var scrollViewTopContentInset = 0.0

    @State private var tokenListFooterFrameMinY: CGFloat = 0.0
    @State private var tokenListContentFrameMaxY: CGFloat = 0.0

    @State private var scrollViewContentOffset: CGPoint = .zero

    @State private var isTokenListFooterGradientHidden = true
    @State private var isNavigationBarBackgroundHidden = true

    let scrollViewCoordinateSpaceName = UUID()

    init(viewModel: OrganizeTokensViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Group {
                tokenList

                tokenListHeader

                tokenListFooter
            }
        }
        .background(
            Colors.Background
                .secondary
                .ignoresSafeArea(edges: [.vertical])
        )
    }

    private var tokenList: some View {
        ScrollView(showsIndicators: false) {
            Spacer(minLength: scrollViewTopContentInset)
                .readContentOffset(
                    inCoordinateSpace: .named(scrollViewCoordinateSpaceName),
                    bindTo: $scrollViewContentOffset
                )

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
            .readGeometry(\.frame.maxY, bindTo: $tokenListContentFrameMaxY)

            Spacer(minLength: scrollViewBottomContentInset)
        }
        .coordinateSpace(name: scrollViewCoordinateSpaceName)
        .onChange(of: tokenListContentFrameMaxY) { newValue in
            withAnimation(.easeOut(duration: 0.1)) {
                isTokenListFooterGradientHidden = newValue < tokenListFooterFrameMinY
            }
        }
        .onChange(of: scrollViewContentOffset) { newValue in
            isNavigationBarBackgroundHidden = newValue.y <= 0.0
        }
    }

    private var tokenListHeader: some View {
        OrganizeTokensHeaderView(viewModel: viewModel.headerViewModel)
            .readGeometry(\.size.height) { height in
                scrollViewTopContentInset = height
                    + Constants.overlayViewAdditionalVerticalInset
                    + Constants.tokenListHeaderViewTopVerticalInset
            }
            .padding(.top, Constants.tokenListHeaderViewTopVerticalInset)
            .padding(.bottom, Constants.overlayViewAdditionalVerticalInset)
            .padding(.horizontal, Constants.contentHorizontalInset)
            .background(navigationBarBackground)
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

    private var navigationBarBackground: some View {
        VisualEffectView(style: .systemUltraThinMaterial)
            .edgesIgnoringSafeArea(.top)
            .hidden(isNavigationBarBackgroundHidden)
            .infinityFrame(alignment: .bottom)
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
    }
}
