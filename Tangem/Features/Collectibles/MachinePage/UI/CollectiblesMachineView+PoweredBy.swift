//
//  CollectiblesMachineView+PoweredBy.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

extension CollectiblesMachineView {
    struct PoweredBy: View {
        var body: some View {
            Text(Self.text)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }
}

// MARK: - Calculations

private extension CollectiblesMachineView.PoweredBy {
    static let text: AttributedString = {
        let partner = Constants.partnerName
        var text = AttributedString(Localization.collectiblesMachinePoweredBy(partner))

        if let range = text.range(of: partner) {
            text[range].foregroundColor = DesignSystem.Color.textPrimary
        }

        return text
    }()

    enum Constants {
        static let partnerName = "Collector Crypt"
    }
}
