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
        }
        .listStyle(DefaultListStyle())
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
                    Assets.walletConnectIcon
                        .resizable()
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("WalletConnect")
                            .font(.body)
                            .foregroundColor(Colors.Text.primary1)

                        Text("Сonnect to decentralized Apps")
                            .font(.footnote)
                            .foregroundColor(Colors.Text.tertiary)
                    }

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
            DefaultRowView(title: "details_ask_a_question".localized, isTappable: true) {
                viewModel.openSupportChat()
            }

            DefaultRowView(title: "details_row_title_send_feedback".localized, isTappable: true) {
                viewModel.openMail()
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        Section(content: {
            DefaultRowView(title: "details_row_title_card_settings".localized, isTappable: true) {
                viewModel.openCardSettings()
            }

            DefaultRowView(title: "details_row_title_app_settings".localized, isTappable: true) {
                viewModel.openAppSettings()
            }
            if viewModel.isTwinCard {
                DefaultRowView(title: "details_row_title_twins_recreate".localized, isTappable: true) {
                    viewModel.prepareTwinOnboarding()
                }
            } else if viewModel.canCreateBackup {
                DefaultRowView(title: "details_row_title_create_backup".localized, isTappable: true) {
                    viewModel.prepareBackup()
                }
            }
        }, footer: {
            DefaultFooterView(title: "You can synchronize up to three cards into one wallet. It can only be done once.")
        })
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        Section(content: {
            DefaultRowView(title: "disclaimer_title".localized, isTappable: true) {
                viewModel.openDisclaimer()
            }
        }, footer: {
            HStack {
                Spacer()

                VStack(alignment: .center, spacing: 20) {
                    SocialNetworkStackView(networks: SocialNetwork.allCases) {
                        viewModel.openSocialNetwork(network: $0)
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
}

struct SocialNetworkStackView: View {
    let networks: [SocialNetwork]
    let tapNetworkAction: (SocialNetwork) -> Void

    var body: some View {
        HStack(spacing: 16) {
            ForEach(networks) { network in
                Button(action: {
                    tapNetworkAction(network)
                }) {
                    network.icon
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
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

