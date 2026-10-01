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
import TangemAccessibilityIdentifiers

struct AccountDetailsView: View {
    @ObservedObject var viewModel: AccountDetailsViewModel

    var body: some View {
        VStack(spacing: 24) {
            accountSection

            jointAccountMembersSection

            manageTokensSection

            supportedNetworksHint

            archiveAccountSection

            Spacer()
        }
        .alert(item: $viewModel.alert) { $0.alert }
        .onFirstAppear(perform: viewModel.onFirstAppear)
    }

    @ViewBuilder
    private var accountSection: some View {
        if viewModel.canBeEdited {
            SwiftUI.Button(action: viewModel.openEditAccount) {
                accountSectionContent
            }
        } else {
            accountSectionContent
        }
    }

    private var accountSectionContent: some View {
        RowWithLeadingAndTrailingIcons(
            leadingIcon: {
                AccountIconView(data: viewModel.accountIconViewData)
            },
            content: {
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(Localization.accountFormName)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                    Text(viewModel.accountName)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                        .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountDetailsAccountName)
                }
            },
            trailingIcon: {
                if viewModel.canBeEdited {
                    CapsuleButton(
                        title: Localization.commonEdit,
                        action: viewModel.openEditAccount
                    )
                    .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountDetailsEditButton)
                }
            }
        )
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    @ViewBuilder
    private var supportedNetworksHint: some View {
        if viewModel.isSupportedNetworksHintVisible {
            HStack(spacing: 4) {
                Text(Localization.jointAccountSettingsNetworksInfo)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                SwiftUI.Button(action: viewModel.openSupportedNetworks) {
                    Text(Localization.jointAccountMoreInfo)
                        .style(Fonts.Regular.caption1, color: Colors.Text.accent)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
        }
    }

    @ViewBuilder
    private var jointAccountMembersSection: some View {
        if let membersText = viewModel.jointAccountMembersText {
            SwiftUI.Button(action: viewModel.openJointAccountMembers) {
                HStack(spacing: 8) {
                    Text(Localization.jointAccountMembersTitle)
                        .style(Fonts.Regular.callout, color: Colors.Text.primary1)

                    Spacer()

                    Text(membersText)
                        .style(Fonts.Regular.callout, color: Colors.Text.tertiary)

                    Assets.chevronRight.image
                        .foregroundColor(Colors.Icon.informative)
                }
                .defaultRoundedBackground(with: Colors.Background.action)
            }
            .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountDetailsJointMembersButton)
        }
    }

    @ViewBuilder
    private var manageTokensSection: some View {
        if viewModel.canManageTokens {
            SwiftUI.Button(action: viewModel.openManageTokens) {
                HStack(spacing: 0) {
                    Text(Localization.addTokensTitle)
                        .style(Fonts.Regular.callout, color: Colors.Text.primary1)

                    Spacer()

                    Assets.chevronRight.image
                        .foregroundColor(Colors.Icon.informative)
                }
                .defaultRoundedBackground(with: Colors.Background.action)
            }
            .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountDetailsManageTokensButton)
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
        SwiftUI.Button(action: viewModel.showShouldArchiveDialog) {
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
        .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountDetailsArchiveButton)
        .defaultRoundedBackground(with: Colors.Background.action)
        .animation(.default, value: viewModel.archivingState)
        .confirmationDialog(
            Localization.accountDetailsArchiveDescription,
            isPresented: $viewModel.archiveAccountDialogPresented,
            titleVisibility: .visible
        ) {
            SwiftUI.Button(Localization.accountDetailsArchive, role: .destructive) {
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
