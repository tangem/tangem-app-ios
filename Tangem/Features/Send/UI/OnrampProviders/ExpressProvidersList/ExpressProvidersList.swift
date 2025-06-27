//
//  ExpressProvidersList.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets
import TangemUI

struct ExpressProvidersList: View {
    let selectedProviderID: Int
    let providersViewData: [OnrampProviderRowViewData]

    var body: some View {
        SelectableSection(providersViewData) { providerData in
            OnrampProviderRowView(isSelected: providerData.id == selectedProviderID, data: providerData)
        }
        .separatorPadding(.init(leading: 62, trailing: SelectionOverlay.Constants.secondStrokeLineWidth))
    }
}
