//
//  NFTAssetTraitsView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

public struct NFTAssetExtendedTraitsView: View {
    private let viewData: KeyValuePanelViewData

    public init(viewData: KeyValuePanelViewData) {
        self.viewData = viewData
    }

    public var body: some View {
        VStack(spacing: 0) {
            KeyValuePanelView(viewData: viewData)
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(Colors.Background.tertiary)
        .navigationTitle(Localization.nftTraitsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
