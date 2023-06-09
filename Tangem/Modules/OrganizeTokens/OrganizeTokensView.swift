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

    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "Replace with native .safeAreaInset()")
    @State private var scrollViewBottomContentInset = 0.0

    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "Replace with native .safeAreaInset()")
    @State private var scrollViewTopContentInset = 0.0

    private let contentSizeBinding: Binding<CGSize>

    init(
        viewModel: OrganizeTokensViewModel,
        contentSizeBinding: Binding<CGSize> = .constant(.zero)
    ) {
        self.viewModel = viewModel
        self.contentSizeBinding = contentSizeBinding
    }

    var body: some View {
        NavigationView {
            ZStack {
                Group {
                    tokenList

                    tokenListHeader

                    tokenListFooter
                }
                .padding(.horizontal, 16.0)
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
                    sections: viewModel.sections
                )

                ForEach(indexed: viewModel.sections.indexed()) { sectionIndex, sectionViewModel in
                    Section(
                        content: {
                            ForEach(indexed: sectionViewModel.items.indexed()) { itemIndex, itemViewModel in
                                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                                OrganizeTokensSectionItemView(viewModel: itemViewModel)
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
                                    OrganizeTokensSectionView(title: title, isDraggable: false)
                                case .draggable(let title):
                                    OrganizeTokensSectionView(title: title, isDraggable: true)
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
            .readSize { contentSizeBinding.wrappedValue = adjustedContentSize(from: $0) }

            Spacer(minLength: scrollViewBottomContentInset)
        }
    }

    private var tokenListHeader: some View {
        OrganizeTokensHeaderView(viewModel: viewModel.headerViewModel)
            .readSize { scrollViewTopContentInset = $0.height + 10.0 + 8.0 }
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
                    .cornerRadiusContinuous(14.0)
            )
        }
        .readSize { scrollViewBottomContentInset = $0.height + 10.0 }
        .infinityFrame(alignment: .bottom)
    }

    private func adjustedContentSize(from originalContentSize: CGSize) -> CGSize {
        return CGSize(
            width: originalContentSize.width,
            height: scrollViewTopContentInset + scrollViewBottomContentInset + originalContentSize.height
        )
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
