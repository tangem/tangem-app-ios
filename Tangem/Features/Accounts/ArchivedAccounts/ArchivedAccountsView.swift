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
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .background(Colors.Background.secondary.ignoresSafeArea())
            .alert(item: $viewModel.alertBinder, content: { $0.alert })
    }

    private var content: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                loadingView

            case .failedToLoad:
                errorView

            case .loaded(let accountInfos):
                makeAccountsView(from: accountInfos)
            }
        }
        .transition(.opacity)
        .animation(.default, value: viewModel.viewState)
    }

    private func makeAccountsView(from models: [ArchivedCryptoAccountInfo]) -> some View {
        VStack(spacing: 0) {
            GroupedSection(models) { model in
                AccountRowView(
                    input: viewModel.makeAccountRowData(for: model),
                    trailing: {
                        makeRecoverButton(for: model)
                    }
                )
                .padding(.vertical, 12)
            }
            .separatorStyle(.none)

            Spacer()
        }
    }

    private func makeRecoverButton(for model: ArchivedCryptoAccountInfo) -> some View {
        let isRecovering = viewModel.recoveringAccountId == model.id
        let isAnyRecovering = viewModel.recoveringAccountId != nil

        return CircleButton(title: Localization.accountArchivedRecover) {
            viewModel.recoverAccount(model)
        }
        .loading(isRecovering)
        .disabled(isAnyRecovering)
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
