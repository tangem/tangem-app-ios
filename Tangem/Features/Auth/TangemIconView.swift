//
//  TangemIconView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemIconView: View {
    var body: some View {
        Assets.tangemIconBig.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 96, height: 96)
            .foregroundColor(Colors.Text.primary1)
            .padding(.bottom, 48)
    }

    static var namespaceId: String { "TangemIconViewAuth" }
}
