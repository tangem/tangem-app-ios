//
//  HighPriceImpactWarningSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct HighPriceImpactWarningSheetView: View {
    @ObservedObject var viewModel: HighPriceImpactWarningSheetViewModel

    var body: some View {
        BottomSheetErrorContentView(
            title: Localization.swappingHighPriceImpactTitle,
            subtitle: viewModel.subtitle,
            closeAction: viewModel.cancel,
            primaryButton: .init(
                title: Localization.commonCancel,
                style: .primary,
                action: viewModel.cancel
            ),
            secondaryButton: .init(
                title: Localization.commonSend,
                icon: viewModel.mainButtonIcon,
                style: .secondary,
                isLoading: viewModel.isActionProcessing,
                action: viewModel.sendAnyway
            )
        )
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}
