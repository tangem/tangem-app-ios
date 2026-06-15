//
//  AddressBookView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct AddressBookView: View {
    @ObservedObject var viewModel: AddressBookViewModel

    var body: some View {
        Color.clear
            .navigationTitle(Text(Localization.addressBookTitle))
            .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
