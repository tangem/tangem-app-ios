//
//  CollectiblesAddFundsSheetView+FloatingSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension CollectiblesAddFundsSheetView {
    struct FloatingSheet: View {
        let viewModel: CollectiblesAddFundsSheetViewModel

        var body: some View {
            CollectiblesAddFundsSheetView(viewModel: viewModel)
                .floatingSheetConfiguration { configuration in
                    configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
                    configuration.backgroundInteractionBehavior = .tapToDismiss
                }
        }
    }
}
