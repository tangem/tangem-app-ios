//
//  MobileSocialWalletView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileSocialWalletView: View {
    typealias ViewModel = MobileSocialWalletViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .background(DesignSystem.Color.bgPrimary)
    }
}

// MARK: - Subviews

private extension MobileSocialWalletView {
    var content: some View {
        ZStack {
            switch viewModel.state {
            case .idle:
                EmptyView()

            case .agreement(let viewModel):
                makeAgreementView(viewModel: viewModel)
                    .navigationBarHidden(true)

            case .processing(let item):
                makeProcessingView(item: item)
                    .navigationBarHidden(true)

            case .support(let viewModel):
                SupportChatView(viewModel: viewModel)
                    .navigationBarHidden(false)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.default, value: viewModel.state.rawCaseValue)
    }

    func makeAgreementView(viewModel: MobileSocialAgreementViewModel) -> some View {
        MobileSocialAgreementView(viewModel: viewModel)
    }

    func makeProcessingView(item: ViewModel.ProcessingItem) -> some View {
        StatusScreen(
            title: item.title,
            description: item.description,
            actionTitle: "",
            action: {}
        )
        .appearance(.info)
        .assetSlot {
            Loader()
                .loaderColor(DesignSystem.Color.iconBrand)
                .loaderSize(.size32)
        }
        .footerHidden(true)
    }
}
