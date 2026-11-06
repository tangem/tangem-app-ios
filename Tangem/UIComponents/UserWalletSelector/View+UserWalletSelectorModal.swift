//
//  View+UserWalletSelectorModal.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

extension UserWalletSelectorViewModel: Identifiable {}

extension View {
    func userWalletSelectorModal(
        item: Binding<UserWalletSelectorViewModel?>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modal(
            item: item,
            contentLayout: .scrollable,
            dragIndicator: .hidden,
            navigation: .title(Localization.commonChooseWallet),
            onDismiss: onDismiss
        ) {
            UserWalletSelectorView(viewModel: $0)
        }
    }
}
