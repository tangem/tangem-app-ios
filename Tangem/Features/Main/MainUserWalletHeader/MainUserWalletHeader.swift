//
//  MainUserWalletHeader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MainUserWalletHeader: View {
    let model: MainUserWalletHeaderModel

    @ObservedObject private var headerViewModel: MainHeaderViewModel

    init(model: MainUserWalletHeaderModel) {
        self.model = model
        headerViewModel = model.headerViewModel
    }

    @ScaledMetric private var height: CGFloat = 84
    @ScaledSize private var loaderSize: CGSize = .init(width: 222, height: 36)
    @ScaledMetric private var thumbnailSize: CGFloat = 24

    var body: some View {
        VStack(spacing: SizeUnit.x4.value) {
            balance

            walletNameWithThumbnail

            if let paginationState = model.paginationState {
                TangemPagination(
                    totalPages: paginationState.totalPages,
                    currentIndex: paginationState.currentIndex
                )
                .pagerStationary()
            }

            if let actionButtonsViewModel = model.actionButtonsViewModel {
                RedesignActionButtonsView(viewModel: actionButtonsViewModel)
                    .padding(.top, .unit(.x2))
                    .padding(.bottom, .unit(.x6))
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var walletNameWithThumbnail: some View {
        HStack(spacing: SizeUnit.x1.value) {
            Text(headerViewModel.userWalletName)
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)

            if let walletThumbnailType = headerViewModel.walletThumbnailType {
                MiniatureWalletView(type: walletThumbnailType)
                    .frame(width: thumbnailSize, height: thumbnailSize)
            }
        }
    }

    private var balance: some View {
        LoadableBalanceView(
            state: headerViewModel.balance,
            style: .init(
                font: Font.Tangem.Custom.titleRegular44,
                textColor: Color.Tangem.Text.Neutral.primary
            ),
            loader: .init(
                size: loaderSize,
                cornerRadiusStyle: .capsule
            )
        )
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(height: height)
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17, *)
#Preview {
    @Previewable @State var provider = FakeCardHeaderPreviewProvider()

    VStack(spacing: 20) {
        ForEach(provider.models.indices, id: \.self) { index in
            MainUserWalletHeader(model: MainUserWalletHeaderModel(
                headerViewModel: provider.models[index],
                actionButtonsViewModel: nil,
                paginationState: nil
            ))
            .onTapGesture {
                let infoProvider = provider.infoProviders[index]
                infoProvider.tapAction(infoProvider)
            }
        }
    }
    .padding()
}
#endif // DEBUG
