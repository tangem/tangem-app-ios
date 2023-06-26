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
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ZStack {
                Group {
                    tokenList

                    tokenListHeader
                }
                .padding(.horizontal, Constants.contentHorizontalInset)

                tokenListFooter
            }
            .background(
                Colors.Background
                    .secondary
                    .ignoresSafeArea(edges: [.vertical])
            )
            .navigationTitle(Localization.organizeTokensTitle)
            .navigationBarTitleDisplayMode(.inline)
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
            .readGeometry(\.frame.maxY, bindTo: $tokenListContentFrameMaxY)

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
            .readGeometry(\.size.height) { height in
                scrollViewTopContentInset = height + Constants.overlayViewAdditionalVerticalInset + 8.0
            }
            .padding(.top, 8.0)
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
}

// MARK: - Constants

private extension OrganizeTokensView {
    enum Constants {
        static let cornerRadius = 14.0
        static let overlayViewAdditionalVerticalInset = 10.0
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
