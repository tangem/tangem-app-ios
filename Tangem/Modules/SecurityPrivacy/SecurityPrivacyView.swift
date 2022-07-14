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
            firstSection

            savedCardsSection

            saveAccessCodeSection
        }
        .listStyle(DefaultListStyle())
        .alert(item: $viewModel.alert) { $0.alert }
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("security_and_privacy_title", displayMode: .inline)
    }

    private var firstSection: some View {
        Section(content: {
            RowView(
                title: "security_and_privacy_security_mode".localized,
                details: viewModel.securityModeTitle,
                isEnable: !viewModel.isOnceOptionSecurityMode,
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

    private var savedCardsSection: some View {
        Section(content: {
            ToggleRowView(
                title: "security_and_privacy_saved_wallet".localized,
                isOn: $viewModel.isSaveCards
            )
        }, footer: {
            FooterView(title: "security_and_privacy_saved_wallet_footer".localized)
        })
    }

    private var saveAccessCodeSection: some View {
        Section(content: {
            ToggleRowView(
                title: "security_and_privacy_saved_access_codes".localized,
                isOn: $viewModel.isSaveAccessCodes
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
                .foregroundColor(.textTertiary)
        }
    }

    struct RowView: View {
        let title: String
        let details: String?
        let isEnable: Bool
        let action: () -> Void

        init(
            title: String,
            details: String? = nil,
            isEnable: Bool = true,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.details = details
            self.isEnable = isEnable
            self.action = action
        }

        var body: some View {
            Button(action: action) {
                HStack {
                    Text(title)
                        .font(.regular17)
                        .foregroundColor(.tangemGrayDark6)

                    Spacer()

                    if let details = details {
                        Text(details)
                            .font(.regular17)
                            .foregroundColor(.textTertiary)
                            .layoutPriority(1)
                    }

                    if isEnable {
                        Image("chevron")
                    }
                }
                .lineLimit(1)
            }
            .disabled(!isEnable)
        }
    }

    struct ToggleRowView: View {
        let title: String
        let isOn: Binding<Bool>

        var body: some View {
            HStack {
                Text(title)
                    .font(.regular17)
                    .foregroundColor(.tangemGrayDark6)

                Spacer()

                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .toggleStyleCompat(.tangemGreen)
                    .disabled(true)
            }
        }
    }
}

struct SecurityPrivacyView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SecurityPrivacyView(viewModel: .mock)
        }
    }
}

private extension SecurityPrivacyViewModel {
    static let mock = SecurityPrivacyViewModel(
        inputModel: .init(currentSecOption: .longTap,
                          availableSecOptions: [.longTap, .accessCode],
                          cardModel: nil),
        coordinator: SecurityPrivacyCoordinator()
    )

    /*
     CardViewModel(cardInfo: CardInfo(card: .card, walletData: nil, artwork: .noArtwork, twinCardInfo: nil, isTangemNote: false, isTangemWallet: false, derivedKeys: [:], primaryCard: nil)))
     */
}
