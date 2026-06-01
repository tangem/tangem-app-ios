//
//  ValidatorCompactView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct StakingTargetCompactViewData: Identifiable, Hashable {
    var id: Int { hashValue }

    let address: String
    let name: String
    let image: StakingTargetIconViewData
    let aprFormatted: String?
}

struct StakingTargetCompactView: View {
    let data: StakingTargetCompactViewData

    var body: some View {
        HStack(spacing: 12) {
            StakingTargetIconView(data: data.image, size: CGSize(width: 24, height: 24))

            HStack(spacing: 0) {
                Text(data.name)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                if let aprFormatted = data.aprFormatted {
                    Spacer()

                    Text(aprFormatted)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                        .animation(nil, value: aprFormatted)
                }
            }
        }
        .infinityFrame(axis: .horizontal)
        .padding(.vertical, 12)
        .accessibilityIdentifier(SendAccessibilityIdentifiers.validatorBlock)
    }
}
