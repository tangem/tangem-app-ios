//
//  ScanCardSettingsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ScanCardSettingsView: View {
    @ObservedObject private var viewModel: ScanCardSettingsViewModel

    init(viewModel: ScanCardSettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    Assets.cards
                        .padding(.vertical, 32)

                    VStack(alignment: .center, spacing: 16) {
                        Text(L10n.scanCardSettingsTitle)
                            .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                            .multilineTextAlignment(.center)

                        Text(L10n.scanCardSettingsMessage)
                            .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            MainButton(
                title: L10n.scanCardSettingsButton,
                icon: .trailing(Assets.tangemIcon),
                isLoading: viewModel.isLoading,
                action: viewModel.scanCard
            )
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
        .alert(item: $viewModel.alert) { $0.alert }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .navigationBarTitle(Text(L10n.cardSettingsTitle), displayMode: .inline)
    }
}

struct ScanCardSettingsView_Preview: PreviewProvider {
    static let viewModel = ScanCardSettingsViewModel(expectedUserWalletId: Data(), coordinator: DetailsCoordinator())

    static var previews: some View {
        ScanCardSettingsView(viewModel: viewModel)
            .deviceForPreview(.iPhone7)
    }
}
