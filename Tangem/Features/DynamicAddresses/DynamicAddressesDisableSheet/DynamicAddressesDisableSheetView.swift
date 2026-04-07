//
//  DynamicAddressesDisableSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct DynamicAddressesDisableSheetView: View {
    @ObservedObject var viewModel: DynamicAddressesDisableSheetViewModel

    var body: some View {
        BottomSheetErrorContentView(
            icon: viewModel.icon,
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            closeAction: viewModel.close,
            primaryButton: viewModel.primaryButtonSettings
        )
        .alert(item: $viewModel.alert) { $0.alert }
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}
