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
            .padding(.horizontal, 16.0)
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

            LazyVStack(spacing: 0.0) {
                ForEach(viewModel.sections) { sectionViewModel in
                    Section(
                        content: {
                            ForEach(sectionViewModel.items) { itemViewModel in
                                OrganizeTokensSectionItemView(viewModel: itemViewModel)
                            }
                        },
                        header: {
                            OrganizeTokensSectionView(viewModel: sectionViewModel)
                        }
                    )
                    .background(Colors.Background.primary)
                }
            }

            Spacer(minLength: scrollViewBottomContentInset)
        }
    }

    private var tokenListHeader: some View {
        OrganizeTokensHeaderView(viewModel: viewModel.headerViewModel)
            .readSize { scrollViewTopContentInset = $0.height + 16.0 }
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
        .readSize { scrollViewBottomContentInset = $0.height + 16.0}
        .infinityFrame(alignment: .bottom)
    }
}

// MARK: - Previews

struct OrganizeTokensView_Preview: PreviewProvider {
    static let viewModel = OrganizeTokensViewModel(coordinator: OrganizeTokensCoordinator())

    static var previews: some View {
        OrganizeTokensView(viewModel: viewModel)
    }
}
