//
//  TangemPayCashbackDetailView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayCashbackDetailView: View {
    @ObservedObject private var viewModel: TangemPayCashbackDetailViewModel

    init(viewModel: TangemPayCashbackDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            TangemPayCashbackDetailContentView(
                state: viewModel.state,
                reloadAction: viewModel.loadDetails,
                rateCardAction: viewModel.openTiersInfo,
                accrualsCardAction: viewModel.openAccrualsInfo
            )
            .environment(\.openURL, OpenURLAction { url in
                viewModel.openURL(url)
                return .handled
            })
            .navigationTitle(Localization.tangempayCashbackTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewModel.close) {
                        DesignSystem.Icons.Cross.regular20.image
                            .renderingMode(.template)
                            .foregroundStyle(DesignSystem.Color.iconPrimary)
                    }
                }
            }
            .task {
                viewModel.onAppear()
            }
            .sheet(item: $viewModel.tiersViewData) { data in
                TangemPayCashbackTiersView(
                    data: data,
                    onClose: viewModel.closeTiersInfo
                )
                .presentationDetents(idealHeight: Constants.tiersIdealContentHeight)
                .presentationBackground(Constants.presentationBackground)
            }
            .sheet(item: $viewModel.accrualsViewData) { data in
                TangemPayCashbackAccrualsView(
                    data: data,
                    onDocTap: viewModel.openDoc,
                    onClose: viewModel.closeAccrualsInfo
                )
                .presentationDetents(idealHeight: Constants.accrualsIdealContentHeight)
                .presentationBackground(Constants.presentationBackground)
            }
        }
    }
}

// MARK: - Constants

private extension TangemPayCashbackDetailView {
    enum Constants {
        static let tiersIdealContentHeight: CGFloat = 340
        static let accrualsIdealContentHeight: CGFloat = 470
        static let presentationBackground = DesignSystem.Color.bgSecondary
    }
}
