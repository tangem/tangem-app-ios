//
//  SecurityPrivacyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SecurityPrivacyView: View {
    @ObservedObject var viewModel: SecurityPrivacyViewModel

    var firstSectionFooterTitle: String {
        if viewModel.isChangeAccessCodeVisible {
            return "security_and_privacy_change_access_code_footer".localized
        } else {
            return "security_and_privacy_security_mode_footer".localized
        }
    }

    var body: some View {
        List {
            securityModeSection

            savingWalletSection

            savingAccessCodesSection
        }
        .listStyle(DefaultListStyle())
        .alert(item: $viewModel.alert) { $0.alert }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("security_and_privacy_title", displayMode: .inline)
    }

    private var securityModeSection: some View {
        Section(content: {
            RowView(
                title: "security_and_privacy_security_mode".localized,
                details: viewModel.securityModeTitle,
                isTappable: !viewModel.hasSingleSecurityMode,
                action: viewModel.openChangeAccessMethod
            )
            if viewModel.isChangeAccessCodeVisible {
                RowView(
                    title: "security_and_privacy_change_access_code".localized,
                    action: viewModel.openChangeAccessCode
                )
            }
        }, footer: {
            FooterView(title: firstSectionFooterTitle)
        })
    }

    private var savingWalletSection: some View {
        Section(content: {
            ToggleRowView(
                title: "security_and_privacy_saved_wallet".localized,
                isOn: $viewModel.isSavingWallet
            )
        }, footer: {
            FooterView(title: "security_and_privacy_saved_wallet_footer".localized)
        })
    }

    private var savingAccessCodesSection: some View {
        Section(content: {
            ToggleRowView(
                title: "security_and_privacy_saved_access_codes".localized,
                isOn: $viewModel.isSavingAccessCodes
            )
        }, footer: {
            FooterView(title: "security_and_privacy_saved_access_codes_footer".localized)
        })
    }
}

private extension SecurityPrivacyView {
    struct FooterView: View {
        let title: String

        var body: some View {
            Text(title)
                .font(.regular13)
                .foregroundColor(Colors.Text.tertiary)
        }
    }

    struct RowView: View {
        let title: String
        let details: String?
        let isTappable: Bool
        let action: () -> Void

        init(
            title: String,
            details: String? = nil,
            isTappable: Bool = true,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.details = details
            self.isTappable = isTappable
            self.action = action
        }

        var body: some View {
            Button(action: action) {
                HStack {
                    Text(title)
                        .font(.regular17)
                        .foregroundColor(Colors.Text.primary1)

                    Spacer()

                    if let details = details {
                        Text(details)
                            .font(.regular17)
                            .foregroundColor(Colors.Text.tertiary)
                            .layoutPriority(1)
                    }

                    if isTappable {
                        Image("chevron")
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
                    .font(.regular17)
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
