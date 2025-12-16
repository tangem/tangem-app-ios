//
//  ArchivedAccountsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccounts
import TangemLocalization

struct ArchivedAccountsView: View {
    @ObservedObject var viewModel: ArchivedAccountsViewModel

    var body: some View {
        content
            .task { await viewModel.fetchArchivedAccounts() }
            .onAppear { viewModel.onAppear() }
            .frame(maxWidth: .infinity)
            .background(Colors.Background.secondary.ignoresSafeArea())
            .alert(item: $viewModel.alertBinder, content: { $0.alert })
    }

    private var content: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                loadingView
                    .padding(.horizontal, Constants.horizontalPadding)

            case .failure:
                errorView
                    .padding(.horizontal, Constants.horizontalPadding)

            case .success(let accountInfos):
                makeAccountsView(from: accountInfos)
            }
        }
        .transition(.opacity)
        .animation(.default, value: viewModel.viewState)
    }

    private func makeAccountsView(from models: [ArchivedCryptoAccountInfo]) -> some View {
        GroupedScrollView(contentType: .lazy(alignment: .center, spacing: 0)) {
            GroupedSection(models) { model in
                ArchivedAccountRowView(viewData: viewModel.makeAccountRowViewData(for: model))
                    .padding(.vertical, 12)
            }
            .separatorStyle(.none)
        }
        .scrollIndicators(.hidden)
    }

    private var loadingView: some View {
        VStack {
            Spacer()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.informative))
                .scaleEffect(1.1)

            Spacer()
        }
    }

    private var errorView: some View {
        VStack {
            Spacer()

            UnableToLoadDataView(isButtonBusy: false) {
                Task { await viewModel.fetchArchivedAccounts() }
            }

            Spacer()
        }
    }
}

// MARK: - Constants

private extension ArchivedAccountsView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
    }
}
