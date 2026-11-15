//
//  View+AccountPickerModal.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

extension AccountPickerViewModel: Identifiable {}

extension View {
    func accountPickerModal(
        item: Binding<AccountPickerViewModel?>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modal(
            item: item,
            contentLayout: .scrollable,
            dragIndicator: .hidden,
            navigation: .title(item.wrappedValue?.title ?? Localization.commonChooseAccount),
            onDismiss: onDismiss
        ) {
            AccountPickerView(viewModel: $0)
        }
    }
}
