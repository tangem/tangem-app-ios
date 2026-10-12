//
//  CollectiblesRegionRestrictionsView+FloatingSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension CollectiblesRegionRestrictionsView {
    struct FloatingSheet: View {
        let viewModel: CollectiblesGeoblockViewModel

        var body: some View {
            CollectiblesRegionRestrictionsView(onClose: viewModel.close)
                .floatingSheetConfiguration { configuration in
                    configuration.sheetBackgroundColor = DesignSystem.Color.bgPrimary
                    configuration.backgroundInteractionBehavior = .tapToDismiss
                }
        }
    }
}

// MARK: - Previews

#Preview {
    CollectiblesRegionRestrictionsView.FloatingSheet(viewModel: CollectiblesGeoblockViewModel())
}
