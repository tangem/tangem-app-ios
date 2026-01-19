//
//  SwiftUIView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets
import TangemUI

public struct NFTAssetExtendedInfoView: View {
    private let viewData: NFTAssetExtendedInfoViewData
    private let dismissAction: () -> Void

    public init(viewData: NFTAssetExtendedInfoViewData, dismissAction: @escaping () -> Void) {
        self.viewData = viewData
        self.dismissAction = dismissAction
    }

    public var body: some View {
        VStack(spacing: 10) {
            NavigationBar(settings: .init(backgroundColor: .clear)) {
                Text(viewData.title)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)
            } rightButtons: {
                CloseTextButton(action: dismissAction)
            }

            Text(viewData.text)
                .style(Fonts.Regular.callout, color: Colors.Text.primary1)
        }
        .padding(.horizontal, 16)
    }
}

#if DEBUG
#Preview {
    NFTAssetExtendedInfoView(
        viewData: NFTAssetExtendedInfoViewData(
            title: "Extended view title",
            text: "You have taken a step into a world where the boundaries between reality and physical world blur. You now possess a unique NFT, shrouded in a mystical aura. This is not just a digital artifact — it's a key to the secrets hidden in our realm. Fate has smiled upon you, for you have received a Cyber Demorph. The Cyber Demorphs come from the oldest captured civilization, which went too far with tech and lost their identity. Demorphs took them over early on, merging their advanced tech into themselves. They're a reminder of what happens when you lose yourself to technology. Let your NFT be a guide into a world of wonders and discoveries. Keep it close, as it is the key to the unseen, and prepare yourself for new mysteries that await you. Welcome to the unknown!"
        ),
        dismissAction: {}
    )
}
#endif
