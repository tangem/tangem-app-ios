//
//  DetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct DetailsView: View {
    @ObservedObject private var viewModel: DetailsViewModel

    init(viewModel: DetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView {
                walletConnectSection

                GroupedSection(viewModel.supportSectionModels) {
                    DefaultRowView(viewModel: $0)
                }

                settingsSection

                legalSection

                environmentSetupSection
            }

            socialNetworks
        }
        .edgesIgnoringSafeArea(.bottom)
        .alert(item: $viewModel.error) { $0.alert }
        .navigationBarTitle("details_title", displayMode: .inline)
        .navigationBarBackButtonHidden(false)
        .navigationBarHidden(false)
    }

    // MARK: - Wallet Connect Section

    @ViewBuilder
    private var walletConnectSection: some View {
        if let viewModel = viewModel.walletConnectRowViewModel {
            GroupedSection(viewModel) {
                WalletConnectRowView(viewModel: $0)
            }
        }
    }

    private var settingsSection: some View {
        GroupedSection(viewModel.settingsSectionViewModels) {
            DefaultRowView(viewModel: $0)
        } footer: {
            if viewModel.canCreateBackup {
                DefaultFooterView("details_row_title_create_backup_footer".localized)
            }
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        GroupedSection(viewModel.legalSectionViewModels) {
            DefaultRowView(viewModel: $0)
        }
    }

    private var socialNetworks: some View {
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
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.bottom, UIApplication.safeAreaInsets.bottom)
        .background(Colors.Background.secondary)
    }

    @ViewBuilder
    private var environmentSetupSection: some View {
        if let viewModel = viewModel.environmentSetupViewModel {
            GroupedSection(viewModel) {
                DefaultRowView(viewModel: $0)
            } header: {
                DefaultHeaderView("Setup environment in app")
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
