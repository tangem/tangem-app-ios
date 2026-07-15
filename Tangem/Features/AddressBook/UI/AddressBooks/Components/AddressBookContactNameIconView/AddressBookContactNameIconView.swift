//
//  AddressBookContactNameIconView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct AddressBookContactNameIconView: View {
    let viewData: AddressBookContactNameIconViewData
    @ScaledMetric private var size: CGFloat

    init(viewData: AddressBookContactNameIconViewData, size: CGFloat = 40) {
        self.viewData = viewData
        _size = ScaledMetric(wrappedValue: size)
    }

    var body: some View {
        viewData.color
            .frame(width: size, height: size)
            .overlay {
                Text(viewData.letter)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textStaticDarkPrimary)
            }
            .clipShape(.circle)
    }
}
