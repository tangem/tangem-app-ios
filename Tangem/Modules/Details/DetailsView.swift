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

    /// Change to @AppStorage and move to model with IOS 14.5 minimum deployment target
    @AppStorageCompat(StorageType.selectedCurrencyCode)
    private var selectedCurrencyCode: String = "USD"

    var body: some View {
        List {
            if viewModel.shouldShowWC {
                walletConnectSection
            }

            supportSection

            settingsSection

            legalSection

            if !AppEnvironment.current.isProduction {
                setupEnvironmentSection
            }
        }
        .groupedListStyleCompatibility(background: Colors.Background.secondary)
        .alert(item: $viewModel.error) { $0.alert }
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
                            .style(Fonts.Regular.body, color: Colors.Text.primary1)

                        Text("wallet_connect_subtitle")
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
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

            if viewModel.canSendMail {
                DefaultRowView(title: "details_row_title_send_feedback".localized) {
                    viewModel.openMail()
                }
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        Section(content: {
            if !viewModel.isMultiWallet {
                DefaultRowView(title: "details_row_title_currency".localized,
                               detailsType: .text(selectedCurrencyCode)) {
                    viewModel.openCurrencySelection()
                }
            }

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
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }
                }

                Spacer()
            }
            .padding(.top, 40)
        })
    }

    private var setupEnvironmentSection: some View {
        Section {
            DefaultRowView(title: "Environment setup") {
                viewModel.openEnvironmentSetup()
            }
        }
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

