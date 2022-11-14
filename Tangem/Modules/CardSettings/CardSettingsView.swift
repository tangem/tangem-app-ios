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

    var firstSectionFooterTitle: String {
        if viewModel.isChangeAccessCodeVisible {
            return "card_settings_change_access_code_footer".localized
        } else {
            return "card_settings_security_mode_footer".localized
        }
    }

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
                    DefaultFooterView(firstSectionFooterTitle)
                }

                GroupedSection(viewModel.resetToFactoryViewModel) {
                    DefaultRowView(viewModel: $0)
                } footer: {
                    DefaultFooterView("card_settings_reset_card_to_factory_footer".localized)
                }
            }
        }
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationBarTitle("card_settings_title", displayMode: .inline)
    }
}
