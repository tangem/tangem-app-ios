//
//  TransferFailedStatusView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TransferFailedStatusView: View {
    let model: Model
    let onRetry: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        if let onRetry {
            screen.secondaryAction(title: Localization.commonRetry, action: onRetry)
        } else {
            screen
        }
    }

    private var screen: StatusScreen<StatusIcon, EmptyView, EmptyView> {
        StatusScreen(
            title: model.title,
            description: model.description,
            actionTitle: Localization.commonClose,
            action: onClose
        )
        .appearance(.warning)
        .assetSlot {
            StatusIcon(model.style.glyph)
                .tint(DesignSystem.Color.iconStatusWarning)
        }
    }
}

// MARK: - Model

extension TransferFailedStatusView {
    struct Model: Identifiable {
        let id = UUID()
        let title: String
        let description: String?
        let style: Style
    }

    enum Style {
        case generic
        case unavailableRegion
    }
}

// MARK: - Appearance

private extension TransferFailedStatusView.Style {
    var glyph: StatusIcon.Glyph {
        switch self {
        case .generic: .warning
        case .unavailableRegion: .heartBroken
        }
    }
}

// MARK: - Previews

#Preview("Generic with retry") {
    TransferFailedStatusView(
        model: TransferFailedStatusView.Model(
            title: "Something went wrong",
            description: nil,
            style: .generic
        ),
        onRetry: {},
        onClose: {}
    )
}

#Preview("Generic") {
    TransferFailedStatusView(
        model: TransferFailedStatusView.Model(
            title: "Something went wrong",
            description: nil,
            style: .generic
        ),
        onRetry: nil,
        onClose: {}
    )
}

#Preview("Unavailable region") {
    TransferFailedStatusView(
        model: TransferFailedStatusView.Model(
            title: "Transfers are not available",
            description: "Please try again later",
            style: .unavailableRegion
        ),
        onRetry: nil,
        onClose: {}
    )
}
