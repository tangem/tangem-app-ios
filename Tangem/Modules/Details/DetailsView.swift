//
//  DetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct DetailsView: View {
    @ObservedObject var viewModel: DetailsViewModel

    var body: some View {
        List {
            if viewModel.shouldShowWC {
                walletConnectSection
            }

            supportSection

            settingsSection

            legalSection
        }
        .groupedListStyleCompatibility()
        .alert(item: $viewModel.error) { $0.alert }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("details_title", displayMode: .inline)
        .navigationBarBackButtonHidden(false)
        .navigationBarHidden(false)
    }

    // MARK: - Wallet Connect Section

    private var walletConnectSection: some View {
        Section {
            Button(action: {
                viewModel.openWalletConnect()
            }) {
                HStack(spacing: 12) {
                    Assets.walletConnect
                        .resizable()
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("wallet_connect_title")
                            .font(.body)
                            .foregroundColor(Colors.Text.primary1)

                        Text("wallet_connect_subtitle")
                            .font(.footnote)
                            .foregroundColor(Colors.Text.tertiary)
                    }
                    .lineLimit(1)

                    Spacer()

                    Assets.chevron
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Wallet Connect Section

    private var supportSection: some View {
        Section {
            DefaultRowView(title: "details_chat".localized) {
                viewModel.openSupportChat()
            }

            DefaultRowView(title: "details_row_title_send_feedback".localized) {
                viewModel.openMail()
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        Section(content: {
            DefaultRowView(title: "details_row_title_card_settings".localized) {
                viewModel.openCardSettings()
            }

//            DefaultRowView(title: "details_row_title_app_settings".localized, isTappable: true) {
//                viewModel.openAppSettings()
//            }

            if viewModel.canCreateBackup {
                DefaultRowView(title: "details_row_title_create_backup".localized) {
                    viewModel.prepareBackup()
                }
            }
        }, footer: {
            if viewModel.canCreateBackup {
                DefaultFooterView(title: "details_row_title_create_backup_footer".localized)
            }
        })
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        Section(content: {
            DefaultRowView(title: "disclaimer_title".localized) {
                viewModel.openDisclaimer()
            }

            if let url = viewModel.cardTOUURL {
                DefaultRowView(title: "details_row_title_card_tou".localized) {
                    viewModel.openCardTOU(url: url)
                }
            }

        }, footer: {
            HStack {
                Spacer()

                VStack(alignment: .center, spacing: 20) {
                    HStack(spacing: 16) {
                        ForEach(SocialNetwork.allCases) { network in
                            socialNetworkView(network: network)
                        }
                    }

                    if let applicationInfoFooter = viewModel.applicationInfoFooter {
                        Text(applicationInfoFooter)
                            .font(.footnote)
                            .foregroundColor(Colors.Text.tertiary)
                    }
                }

                Spacer()
            }
            .padding(.top, 40)
        })
    }

    private func socialNetworkView(network: SocialNetwork) -> some View {
        Button(action: {
            viewModel.openSocialNetwork(network: network)
        }) {
            network.icon
                .resizable()
                .frame(width: 24, height: 24)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DetailsView(viewModel: DetailsViewModel(cardModel: PreviewCard.cardanoNote.cardModel,
                                                    coordinator: DetailsCoordinator()))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

