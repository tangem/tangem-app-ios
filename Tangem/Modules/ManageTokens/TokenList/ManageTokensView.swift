//
//  ManageTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk
import AlertToast

struct ManageTokensView: View {
    @ObservedObject var viewModel: ManageTokensViewModel

    var body: some View {
        VStack {
            header

            if viewModel.isShowTokenList {
                list
            } else {
                skeletonList
            }
        }
		.background(Colors.Background.primary)
        .scrollDismissesKeyboardCompat(true)
        .alert(item: $viewModel.alert, content: { $0.alert })
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.manageTokensListHeaderTitle)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .lineLimit(1)

            if viewModel.isShowAddCustomToken {
                Text(Localization.manageTokensListHeaderSubtitle)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var list: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.tokenViewModels) {
                ManageTokensItemView(viewModel: $0)
            }

            addCutomTokenView

            if viewModel.hasNextPage {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.informative))
                    .onAppear(perform: viewModel.fetchMore)
            }
        }
    }

    private var addCutomTokenView: some View {
        ManageTokensAddCustomItemView {
            viewModel.addCustomTokenDidTapAction()
        }
    }

    private var skeletonList: some View {
        ForEach(1 ... 10, id: \.self) { _ in
            VStack {
                HStack(spacing: 12) {
                    SkeletonView()
                        .frame(size: .init(width: 36, height: 36))
                        .cornerRadius(18)

                    VStack(alignment: .leading, spacing: 6) {
                        SkeletonView()
                            .frame(size: .init(width: 70, height: 12))
                            .cornerRadius(3)

                        SkeletonView()
                            .frame(size: .init(width: 52, height: 12))
                            .cornerRadius(3)
                    }

                    Spacer(minLength: 24)

                    VStack(alignment: .trailing) {
                        SkeletonView()
                            .frame(size: .init(width: 44, height: 12))
                            .cornerRadius(3)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}
