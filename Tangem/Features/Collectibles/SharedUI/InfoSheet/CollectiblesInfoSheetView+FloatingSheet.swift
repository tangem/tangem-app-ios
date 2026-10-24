//
//  CollectiblesInfoSheetView+FloatingSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension CollectiblesInfoSheetView {
    struct FloatingSheet: View {
        let viewModel: CollectiblesInfoSheetViewModel

        var body: some View {
            CollectiblesInfoSheetView(model: viewModel.model, onClose: viewModel.close)
                .floatingSheetConfiguration { configuration in
                    configuration.sheetBackgroundColor = DesignSystem.Color.bgPrimary
                    configuration.backgroundInteractionBehavior = .tapToDismiss
                }
        }
    }
}
