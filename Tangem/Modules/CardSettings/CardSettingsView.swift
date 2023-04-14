//
//  CardSettingsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardSettingsView: View {
    @ObservedObject var viewModel: CardSettingsViewModel

    var body: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView {
                GroupedSection(viewModel.cardInfoSection) {
                    DefaultRowView(viewModel: $0)
                }

                GroupedSection(viewModel.securityModeSection) {
                    DefaultRowView(viewModel: $0)
                } footer: {
                    DefaultFooterView(viewModel.securityModeFooterMessage)
                }

                GroupedSection(viewModel.accessCodeRecoverySection) {
                    DefaultRowView(viewModel: $0)
                } footer: {
                    DefaultFooterView(Localization.cardSettingsAccessCodeRecoveryFooter)
                }

                GroupedSection(viewModel.resetToFactoryViewModel) {
                    DefaultRowView(viewModel: $0)
                } footer: {
                    DefaultFooterView(viewModel.resetToFactoryFooterMessage)
                }
            }
        }
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationBarTitle(Text(Localization.cardSettingsTitle), displayMode: .inline)
    }
}
