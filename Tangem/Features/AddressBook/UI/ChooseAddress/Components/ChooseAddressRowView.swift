//
//  ChooseAddressRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct ChooseAddressRowView: View {
    let viewModel: ChooseAddressRowViewModel

    var body: some View {
        TangemRow(title: viewModel.title, subtitle: viewModel.subtitle)
            .start {
                AddressBlockiesIconView(viewData: viewModel.addressIcon)
            }
            .onTap(viewModel.onTap)
    }
}
