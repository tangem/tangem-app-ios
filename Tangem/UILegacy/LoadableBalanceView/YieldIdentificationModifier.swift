//
//  YieldIdentificationModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct YieldIdentificationModifier: ViewModifier {
    let showInfoAction: () -> Void

    func body(content: Content) -> some View {
        HStack(spacing: 4) {
            exchangeIcon
            content
            infoButton
        }
    }

    private var exchangeIcon: some View {
        Assets.exchangeMini.image
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(Colors.Icon.informative)
            .frame(size: .init(bothDimensions: 16))
            .rotationEffect(.degrees(90))
    }

    @ViewBuilder
    private var infoButton: some View {
        Button(action: { showInfoAction() }) {
            Assets.infoCircle16.image
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.informative)
        }
    }
}

// MARK: - Convenience

extension LoadableBalanceView {
    func yieldIdentificationIfNeeded(showInfoAction: @escaping () -> Void) -> some View {
        modifier(YieldIdentificationModifier(showInfoAction: showInfoAction))
    }
}
