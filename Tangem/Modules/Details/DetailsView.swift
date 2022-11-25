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
    @State private var socialNetworksViewSize: CGSize = .zero

    init(viewModel: DetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            GroupedScrollView {
                walletConnectSection

                GroupedSection(viewModel.supportSectionModels) {
                    DefaultRowView(viewModel: $0)
                }

                settingsSection

                legalSection

                environmentSetupSection

                Color.clear.frame(height: socialNetworksViewSize.height)
            }

            socialNetworks
                .readSize { socialNetworksViewSize = $0 }
        }
        .ignoresBottomArea()
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .navigationBarBackButtonHidden(false)
        .navigationBarHidden(false)
        .alert(item: $viewModel.error) { $0.alert }
        .navigationBarTitle("details_title", displayMode: .inline)
    }

    // MARK: - Wallet Connect Section

    @ViewBuilder
    private var walletConnectSection: some View {
        GroupedSection(viewModel.walletConnectRowViewModel) {
            WalletConnectRowView(viewModel: $0)
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
        GroupedSection(viewModel.legalSectionViewModel) {
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
        .padding(.top, 16)
        .padding(.bottom, max(16, UIApplication.safeAreaInsets.bottom))
        .background(Colors.Background.secondary)
    }

    @ViewBuilder
    private var environmentSetupSection: some View {
        GroupedSection(viewModel.environmentSetupViewModel) {
            DefaultRowView(viewModel: $0)
        } header: {
            DefaultHeaderView("Setup environment in app")
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
            DetailsView(
                viewModel: DetailsViewModel(cardModel: PreviewCard.tangemWalletEmpty.cardModel,
                                            coordinator: DetailsCoordinator())
            )
        }
        .navigationViewStyle(.stack)
    }
}
