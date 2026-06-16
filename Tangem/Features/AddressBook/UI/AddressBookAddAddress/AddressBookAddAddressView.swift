//
//  AddressBookAddAddressView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct AddressBookAddAddressView: View {
    @ObservedObject var viewModel: AddressBookAddAddressViewModel

    var body: some View {
        Color.clear
            .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
            .navigationTitle(Text(Localization.addressBookAddAddress))
            .navigationBarTitleDisplayMode(.inline)
    }
}
