//
//  AddressesInfoView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct AddressesInfoView: View {
    @ObservedObject var viewModel: AddressesInfoViewModel

    var body: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)
            ScrollView {
                Text(viewModel.text)
                    .font(.system(.footnote, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.addressesInfoText)
            }
        }
        .navigationTitle("Addresses info")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: viewModel.copyToClipboard) {
                    Image(systemName: "doc.on.doc")
                }
                .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.addressesInfoCopyButton)
            }
        }
    }
}
