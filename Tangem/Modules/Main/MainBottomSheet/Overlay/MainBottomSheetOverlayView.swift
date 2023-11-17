//
//  MainBottomSheetOverlayView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainBottomSheetOverlayView: View {
    let viewModel: MainBottomSheetOverlayViewModel

    var body: some View {
        switch viewModel {
        case .generateAddresses(let viewModel):
            GenerateAddressesView(viewModel: viewModel)
        }
    }
}
