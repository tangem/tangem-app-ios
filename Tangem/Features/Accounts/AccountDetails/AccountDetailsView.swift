//
//  AccountDetailsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAccounts
import TangemLocalization
import TangemAssets

struct AccountDetailsView: View {
    @ObservedObject var viewModel: AccountDetailsViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                accountSection

                manageTokensSection

                archiveAccountSection

                Spacer()
            }

            actionSheets
        }
        .alert(item: $viewModel.alert) { $0.alert }
        .onFirstAppear(perform: viewModel.onFirstAppear)
    }

    private var accountSection: some View {
        RowWithLeadingAndTrailingIcons(
            leadingIcon: {
                AccountIconView(data: viewModel.accountIconViewData)
            },
            content: {
                VStack(alignment: .leading, spacing: .zero) {
                    Text(Localization.accountFormName)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                    Text(viewModel.accountName)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                }
            },
            trailingIcon: {
                if viewModel.canBeEdited {
                    CapsuleButton(
                        title: Localization.commonEdit,
                        action: viewModel.openEditAccount
                    )
                }
            }
        )
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    @ViewBuilder
    private var manageTokensSection: some View {
        if viewModel.canManageTokens {
            Button(action: viewModel.openManageTokens) {
                HStack(spacing: 0) {
                    Text(Localization.addTokensTitle)
                        .style(Fonts.Regular.callout, color: Colors.Text.primary1)

                    Spacer()

                    Assets.chevronRight.image
                        .foregroundColor(Colors.Icon.informative)
                }
                .defaultRoundedBackground(with: Colors.Background.action)
            }
        }
    }

    @ViewBuilder
    private var archiveAccountSection: some View {
        switch viewModel.archivingState {
        case .none:
            EmptyView()

        case .some(let state):
            VStack(alignment: .leading, spacing: 8) {
                makeArchivingSectionContent(from: state)

                Text(Localization.accountDetailsArchiveDescription)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .padding(.leading, 14)
            }
        }
    }

    private func makeArchivingSectionContent(from state: AccountDetailsViewModel.ArchivingState) -> some View {
        Button(action: viewModel.showShouldArchiveDialog) {
            HStack(spacing: 0) {
                Text(viewModel.getArchivingButtonTitle(from: state))
                    .style(Fonts.Regular.callout, color: viewModel.getArchivingButtonColor(from: state))

                Spacer()

                if state == .archivingInProgress {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.Tangem.Graphic.Neutral.quaternary))
                        .fixedSize()
                }
            }
            .frame(minHeight: 20)
        }
        .disabled(state == .archivingInProgress)
        .defaultRoundedBackground(with: Colors.Background.action)
        .animation(.default, value: viewModel.archivingState)
    }

    private var actionSheets: some View {
        NavHolder()
            .confirmationDialog(
                Localization.accountDetailsArchiveDescription,
                isPresented: $viewModel.archiveAccountDialogPresented,
                titleVisibility: .visible
            ) {
                Button(Localization.accountDetailsArchive, role: .destructive) {
                    Analytics.log(.accountSettingsButtonArchiveAccountConfirmation)
                    viewModel.archiveAccount()
                }
            }
            .onChange(of: viewModel.archiveAccountDialogPresented) { isPresented in
                if !isPresented {
                    viewModel.handleDialogDismissed()
                }
            }
    }
}
