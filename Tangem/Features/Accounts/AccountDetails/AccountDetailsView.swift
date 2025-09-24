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
        VStack(spacing: 24) {
            accountSection

            manageTokensSection

            archiveAccountSection

            Spacer()
        }
    }

    private var accountSection: some View {
        RowWithLeadingAndTrailingIcons(
            leadingIcon: {
                AccountIconView(
                    backgroundColor: viewModel.accountIconColor,
                    nameMode: viewModel.accountIconNameMode
                )
                .padding(8)
                .cornerRadius(10)
                .letterFontStyle(Fonts.BoldStatic.title3)
                .size(.init(bothDimensions: 20))
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
                    RoundedButton(
                        style: .string(Localization.commonEdit),
                        action: viewModel.openEditAccount
                    )
                }
            }
        )
        .defaultRoundedBackground()
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
                .defaultRoundedBackground()
            }
        }
    }

    @ViewBuilder
    private var archiveAccountSection: some View {
        if viewModel.canBeArchived {
            VStack(alignment: .leading, spacing: 8) {
                Button(action: viewModel.archiveAccount) {
                    Text(Localization.accountDetailsArchive)
                        .style(Fonts.Regular.callout, color: Colors.Text.warning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .defaultRoundedBackground()
                }

                Text(Localization.accountDetailsArchiveDescription)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .padding(.leading, 14)
            }
        }
    }
}
