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

    @ScaledSize private var loaderSize: CGSize = .init(width: 222, height: 36)

    var body: some View {
        VStack(spacing: SizeUnit.x4.value) {
            balance

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

    private var balance: some View {
        LoadableBalanceView(
            state: headerViewModel.balance,
            style: .init(
                font: Font.Tangem.title44,
                textColor: Color.Tangem.Text.Neutral.primary
            ),
            loader: .init(
                size: loaderSize,
                cornerRadiusStyle: .capsule
            )
        )
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
