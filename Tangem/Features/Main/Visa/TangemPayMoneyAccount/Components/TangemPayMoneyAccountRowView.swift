//
//  TangemPayMoneyAccountRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TangemPayMoneyAccountRowView: View {
    let state: TangemPayMoneyAccountRowState
    let onTap: () -> Void

    var body: some View {
        Row(
            title: Localization.moneyAccountMainName,
            subtitle: subtitle
        )
        .start { avatar }
        .includeInnerPadding(false)
        .onTap(action: onTap)
        .padding(12)
        .background(
            DesignSystem.Color.bgSecondary,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private var avatar: some View {
        Assets.Visa.accountMoneyAvatar.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 40, height: 40)
    }

    private var subtitle: String {
        switch state {
        case .activating:
            Localization.moneyAccountMainStatusActivating
        case .awaitingDeposit:
            Localization.moneyAccountMainStatusAwaitingDeposit
        case .failed:
            Localization.moneyAccountMainStatusFailed
        case .active:
            Localization.moneyAccountMainStatusActiveV2
        }
    }
}

// MARK: - Previews

#Preview {
    TangemPayMoneyAccountRowView(state: .awaitingDeposit, onTap: {})
        .padding(.horizontal, 12)
}
