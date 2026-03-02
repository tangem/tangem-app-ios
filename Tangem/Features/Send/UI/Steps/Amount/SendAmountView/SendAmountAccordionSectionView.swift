//
//  SendAmountAccordionSectionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUI

struct SendAmountAccordionSectionView<ExpandedContent: View>: View {
    let isExpanded: Bool
    let expandedTokenData: SendAmountTokenViewData?
    let compactTokenData: SendAmountTokenViewData?
    let onTapCompact: () -> Void
    @ViewBuilder let expandedContent: () -> ExpandedContent

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {
            if isExpanded {
                expandedContent()
                    .padding(.vertical, 45)

                Separator(color: Colors.Stroke.primary)
            }

            if let tokenData = isExpanded ? expandedTokenData : compactTokenData {
                SendAmountTokenView(data: tokenData)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isExpanded else { return }
                        FeedbackGenerator.heavy()
                        onTapCompact()
                    }
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0)
    }
}
