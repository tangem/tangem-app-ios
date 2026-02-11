//
//  DetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct DetailsView: View {
    @ObservedObject private var viewModel: DetailsViewModel

    init(viewModel: DetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GroupedScrollView(contentType: .lazy(alignment: .center, spacing: 24)) {
            walletConnectSection

            userWalletsSection

            buyWalletSection

            appSettingsSection

            supportSection

            environmentSetupSection

            socialNetworks
        }
        .interContentPadding(8)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationTitle(Localization.detailsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: viewModel.onAppear)
    }

    private var walletConnectSection: some View {
        GroupedSection(viewModel.walletConnectRowViewModel) {
            WalletConnectRowView(viewModel: $0)
        }
    }

    private var userWalletsSection: some View {
        GroupedSection(
            viewModel.walletsSectionTypes,
            content: { type in
                switch type {
                case .wallet(let viewModel):
                    SettingsUserWalletRowView(viewModel: viewModel)
                case .addOrScanNewUserWalletButton(let viewModel):
                    DefaultRowView(viewModel: viewModel)
                        .appearance(.addButton)
                }
            },
            footer: {
                viewModel.userWalletsSectionFooterString.map { DefaultFooterView($0) }
            }
        )
        .confirmationDialog(viewModel: $viewModel.scanTroubleshootingDialog)
    }

    private var buyWalletSection: some View {
        GroupedSection(viewModel.getSectionViewModels) {
            DefaultRowView(viewModel: $0)
                .appearance(.accentButton)
        }
    }

    private var appSettingsSection: some View {
        GroupedSection(viewModel.appSettingsViewModel) {
            DefaultRowView(viewModel: $0)
        }
    }

    private var supportSection: some View {
        GroupedSection(viewModel.supportSectionModels) {
            DefaultRowView(viewModel: $0)
        }
        .confirmationDialog(viewModel: $viewModel.chooseSupportTypeDialog)
    }

    private var socialNetworks: some View {
        VStack(alignment: .center, spacing: 16) {
            ForEach(SocialNetwork.list, id: \.hashValue) { networks in
                HStack(spacing: 16) {
                    ForEach(networks) { network in
                        socialNetworkView(network: network)
                    }
                }
            }

            if let applicationInfoFooter = viewModel.applicationInfoFooter {
                Text(applicationInfoFooter)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private var environmentSetupSection: some View {
        GroupedSection(viewModel.environmentSetupViewModel) {
            DefaultRowView(viewModel: $0)
        }
    }

    private func socialNetworkView(network: SocialNetwork) -> some View {
        Button(action: {
            viewModel.openSocialNetwork(network: network)
        }) {
            network.icon.image
                .resizable()
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DetailsView(
                viewModel: DetailsViewModel(
                    coordinator: DetailsCoordinator()
                )
            )
        }
    }
}
