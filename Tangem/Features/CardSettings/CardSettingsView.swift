//
//  CardSettingsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct CardSettingsView: View {
    @ObservedObject var viewModel: CardSettingsViewModel

    var body: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            GroupedScrollView(contentType: .lazy(alignment: .center, spacing: 24)) {
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
                        .appearance(.destructiveButton)
                } footer: {
                    DefaultFooterView(viewModel.resetToFactoryFooterMessage)
                }
            }
            .interContentPadding(8)
        }
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationBarTitle(Text(Localization.cardSettingsTitle), displayMode: .inline)
    }
}
