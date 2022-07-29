//
//  CardSettingsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardSettingsView: View {
    @ObservedObject var viewModel: CardSettingsViewModel

    var firstSectionFooterTitle: String {
        if viewModel.isChangeAccessCodeVisible {
            return "card_settings_change_access_code_footer".localized
        } else {
            return "card_settings_security_mode_footer".localized
        }
    }

    var body: some View {
        List {
            cardInfoSection

            securityModeSection
        }
        .listStyle(DefaultListStyle())
        .alert(item: $viewModel.alert) { $0.alert }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("card_settings_title", displayMode: .inline)
    }

    private var cardInfoSection: some View {
        Section(content: {
            RowView(
                title: "details_row_title_cid".localized,
                details: viewModel.cardId
            )

            RowView(
                title: "details_row_title_issuer".localized,
                details: viewModel.cardIssuer
            )

            if let cardSignedHashes = viewModel.cardSignedHashes {
                RowView(
                    title: "details_row_title_signed_hashes".localized,
                    details: "details_row_subtitle_signed_hashes_format".localized(cardSignedHashes)
                )
            }
        })
    }

    private var securityModeSection: some View {
        Section(content: {
            RowView(
                title: "card_settings_security_mode".localized,
                details: viewModel.securityModeTitle,
                action: viewModel.hasSingleSecurityMode ? nil : viewModel.openSecurityMode
            )
            if viewModel.isChangeAccessCodeVisible {
                RowView(
                    title: "card_settings_change_access_code".localized,
                    action: viewModel.openChangeAccessCodeWarningView
                )
            }
        }, footer: {
            FooterView(title: firstSectionFooterTitle)
        })
    }
}

private extension CardSettingsView {
    struct FooterView: View {
        let title: String

        var body: some View {
            Text(title)
                .font(.footnote)
                .foregroundColor(Colors.Text.tertiary)
        }
    }

    struct RowView: View {
        let title: String
        let details: String?
        let action: (() -> Void)?

        private var isTappable: Bool { action != nil }

        init(
            title: String,
            details: String? = nil,
            action: (() -> Void)? = nil
        ) {
            self.title = title
            self.details = details
            self.action = action
        }

        var body: some View {
            Button(action: { action?() }) {
                HStack {
                    Text(title)
                        .font(.body)
                        .foregroundColor(Colors.Text.primary1)

                    Spacer()

                    if let details = details {
                        Text(details)
                            .font(.body)
                            .foregroundColor(Colors.Text.tertiary)
                            .layoutPriority(1)
                    }

                    if isTappable {
                        Assets.chevron
                    }
                }
                .lineLimit(1)
            }
            .disabled(!isTappable)
        }
    }

    struct ToggleRowView: View {
        let title: String
        let isOn: Binding<Bool>

        var body: some View {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(Colors.Text.primary1)

                Spacer()

                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .toggleStyleCompat(Colors.Control.checked)
                    .disabled(true) // [REDACTED_TODO_COMMENT]
            }
        }
    }
}
