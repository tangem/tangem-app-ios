//
//  AddressBookContactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct AddressBookContactView: View {
    let viewModel: AddressBookContactViewModel

    var body: some View {
        TangemRow(title: viewModel.title, subtitle: viewModel.subtitle)
            .verticalAlignment(.center)
            .start { AddressBookContactNameIconView(viewData: viewModel.iconViewData) }
            .onTap(viewModel.action)
    }
}
