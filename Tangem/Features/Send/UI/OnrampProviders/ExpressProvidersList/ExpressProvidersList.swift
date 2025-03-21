//
//  ExpressProvidersList.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct ExpressProvidersList: View {
    let providersViewData: [OnrampProviderRowViewData]

    var body: some View {
        ForEach(providersViewData) { data in
            OnrampProviderRowView(data: data)

            if providersViewData.last?.id != data.id {
                Separator(height: .minimal, color: Colors.Stroke.primary)
                    .padding(.leading, 62)
            }
        }
    }
}
