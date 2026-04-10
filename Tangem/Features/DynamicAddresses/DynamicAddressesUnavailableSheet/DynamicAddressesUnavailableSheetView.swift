//
//  DynamicAddressesUnavailableSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct DynamicAddressesUnavailableSheetView: View {
    let viewModel: DynamicAddressesUnavailableSheetViewModel

    var body: some View {
        BottomSheetErrorContentView(
            icon: viewModel.icon,
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            closeAction: viewModel.close,
            primaryButton: viewModel.primaryButtonSettings
        )
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}
