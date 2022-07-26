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
        VStack(alignment: .center, spacing: 0) {

            Assets.cards
                .padding(.vertical, 32)

            VStack(alignment: .center, spacing: 16) {
                Text("Get your card ready!")
                    .font(.title1.bold)
                    .foregroundColor(Colors.Text.primary1)

                Text(" Scan the card to change its settings. The changes will impact only the card you’ve scanned and will not affect other cards tied to your wallet.")
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .foregroundColor(Colors.Text.primary1)
            }

            Spacer()

            TangemButton(title: "Scan card") {

            }
            .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth))
        }
        .padding([.bottom, .horizontal], 16)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("card_settings_title", displayMode: .inline)
    }
}
