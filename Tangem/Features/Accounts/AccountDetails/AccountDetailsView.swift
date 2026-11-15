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
        GroupedScrollView(contentType: .plain(spacing: Constants.sectionSpacing)) {
            accountSection

            managementSection

            archiveSection
        }
        .horizontalPadding(0)
        .interContentPadding(Constants.contentVerticalPadding)
        .navigationTitle(viewModel.navigationTitle)
        .alert(item: $viewModel.alert) { $0.alert }
        .onFirstAppear(perform: viewModel.onFirstAppear)
    }

    // MARK: - Account

    private var accountSection: some View {
        VStack(spacing: .zero) {
            accountRow

            ForEach(indexed: viewModel.additionalAccountInfo, id: \.0) { index, info in
                additionalAccountInfoRow(info)
            }
        }
        .sectionBackground()
    }

    private var accountRow: some View {
        Row(title: viewModel.accountName, subtitle: accountSubtitleText)
            .lineOrder(accountLineOrder)
            .start { AccountIconView(data: viewModel.accountIconViewData, settings: .redesignDefaultSized) }
            .end { editButton }
            .showDivider(viewModel.additionalAccountInfo.isNotEmpty)
            .onTap(action: viewModel.canBeEdited ? viewModel.openEditAccount : nil)
            .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountDetailsAccountName)
    }

    private var accountSubtitleText: String {
        switch viewModel.accountSubtitle {
        case .nameLabel: Localization.accountFormName
        case .membersCount(let count): Localization.jointAccountMembersCount(count)
        }
    }

    private var accountLineOrder: RowLineOrder {
        switch viewModel.accountSubtitle {
        case .nameLabel: .secondaryFirst
        case .membersCount: .primaryFirst
        }
    }

    @ViewBuilder
    private var editButton: some View {
        if viewModel.canBeEdited {
            TangemUI.Button(label: Localization.commonEdit, accessibilityLabel: nil, action: viewModel.openEditAccount)
                .styleType(.secondary(.default))
                .size(.x8)
                .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountDetailsEditButton)
        }
    }

    @ViewBuilder
    private func additionalAccountInfoRow(_ info: AccountDetailsViewModel.AdditionalAccountInfo) -> some View {
        switch info {
        case .jointSignaturesCount(let signersCount, let membersCount, _):
            Row(
                title: Localization.jointAccountInviteMembersRequiredApprovals,
                value: Localization.jointAccountInviteMembersApprovalsValue(signersCount, membersCount)
            )
            .valueAccessory { infoIcon }
            .overrideTextColors(RowOverrideTextColors(value: DesignSystem.Color.textSecondary))
            .showDivider(false)
            .onTap(action: { viewModel.onAdditionalAccountInfoTap(info) })
            .accessibilityHint(Localization.jointAccountInviteMembersAboutSignaturesTitle)
        }
    }

    private var infoIcon: some View {
        DesignSystem.Icons.Info.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .accessibilityHidden(true)
    }

    // MARK: - Management

    @ViewBuilder
    private var managementSection: some View {
        let actions = viewModel.managementActions

        if actions.isNotEmpty {
            VStack(alignment: .leading, spacing: Constants.footerSpacing) {
                VStack(spacing: .zero) {
                    ForEach(indexed: actions, id: \.0) { index, action in
                        managementRow(action, showsDivider: index < actions.count - 1)
                    }
                }
                .sectionBackground()

                managementFooter
            }
        }
    }

    @ViewBuilder
    private func managementRow(_ action: AccountDetailsViewModel.Action, showsDivider: Bool) -> some View {
        switch action {
        case .jointMembers(let value, _):
            Row(title: Localization.jointAccountMembersTitle, value: value)
                .valueAccessory { chevronIcon }
                .overrideTextColors(RowOverrideTextColors(value: DesignSystem.Color.textSecondary))
                .showDivider(showsDivider)
                .onTap(action: { viewModel.onActionTap(action) })
                .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountDetailsJointMembersButton)
        case .manageTokens:
            Row(title: Localization.addTokensTitle)
                .valueAccessory { chevronIcon }
                .showDivider(showsDivider)
                .onTap(action: { viewModel.onActionTap(action) })
                .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountDetailsManageTokensButton)
        case .edit, .archive:
            EmptyView()
        }
    }

    @ViewBuilder
    private var managementFooter: some View {
        if let managementFooter = viewModel.managementFooter {
            Text(managementFooter)
                .font(token: DesignSystem.Font.captionMediumToken)
                .environment(\.openURL, OpenURLAction { _ in
                    viewModel.openSupportedNetworks()
                    return .handled
                })
        }
    }

    private var chevronIcon: some View {
        DesignSystem.Icons.ChevronRight.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .accessibilityHidden(true)
    }

    // MARK: - Archive

    @ViewBuilder
    private var archiveSection: some View {
        if let archivingState = viewModel.archivingState {
            VStack(alignment: .leading, spacing: Constants.footerSpacing) {
                archiveRow(state: archivingState)
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
                    .sectionBackground()

                Text(Localization.accountDetailsArchiveDescription)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .animation(.default, value: archivingState)
        }
    }

    @ViewBuilder
    private func archiveRow(state: AccountDetailsViewModel.ArchivingState) -> some View {
        switch state {
        case .readyToBeArchived:
            Row(title: Localization.accountDetailsArchive)
                .end { trashIcon }
                .overrideTextColors(RowOverrideTextColors(title: DesignSystem.Color.textStatusError))
                .onTap(action: viewModel.showShouldArchiveDialog)
                .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountDetailsArchiveButton)
        case .archivingInProgress:
            Row(title: Localization.accountDetailsArchiving)
                .overrideTextColors(RowOverrideTextColors(title: DesignSystem.Color.textSecondary))
                .end { Loader().loaderSize(.size20) }
                .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountDetailsArchiveButton)
        }
    }

    private var trashIcon: some View {
        DesignSystem.Icons.TrashBin.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconStatusError)
            .accessibilityHidden(true)
    }
}

// MARK: - Section background

private extension View {
    func sectionBackground() -> some View {
        background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: AccountDetailsView.Constants.cornerRadius, style: .continuous))
    }
}

// MARK: - Constants

private extension AccountDetailsView {
    enum Constants {
        static let contentVerticalPadding: CGFloat = 12
        static let sectionSpacing: CGFloat = 20
        static let footerSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 24
    }
}
