//
//  FloatingSheetRegistry+AccountSelection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

extension FloatingSheetRegistry {
    func registerForYouAccountSelectorSheets() {
        register(ForYouAccountSelectorViewModel.self) { viewModel in
            VStack(spacing: 0) {
                BottomSheetHeaderView(
                    title: Localization.commonSelectAccount,
                    trailing: {
                        NavigationBarButton.close(action: viewModel.close)
                    }
                )
                .padding(.horizontal, 16)
                ForYouAccountSelectorView(viewModel: viewModel)
            }
            .floatingSheetConfiguration { configuration in
                configuration.backgroundInteractionBehavior = .tapToDismiss
            }
        }
    }
}
