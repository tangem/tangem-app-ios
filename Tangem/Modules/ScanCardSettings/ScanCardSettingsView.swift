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
                        Text("scan_card_settings_title")
                            .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                            .multilineTextAlignment(.center)

                        Text("scan_card_settings_message")
                            .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 40)
            }

            TangemButton(title: "scan_card_settings_button", image: "tangemIcon", iconPosition: .trailing) {
                viewModel.scanCard()
            }
            .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth, isLoading: viewModel.isLoading))
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
        .alert(item: $viewModel.alert) { $0.alert }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("card_settings_title", displayMode: .inline)
    }
}

struct ScanCardSettingsView_Preview: PreviewProvider {
    static let viewModel = ScanCardSettingsViewModel(expectedUserWalletId: Data(), coordinator: DetailsCoordinator())

    static var previews: some View {
        ScanCardSettingsView(viewModel: viewModel)
            .deviceForPreview(.iPhone7)
    }
}
