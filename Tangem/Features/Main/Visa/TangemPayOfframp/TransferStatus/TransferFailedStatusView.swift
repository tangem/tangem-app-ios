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
        .appearance(model.style.appearance)
        .assetSlot {
            StatusIcon(model.style.glyph)
                .tint(model.style.tint)
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
        case technicalIssue
    }
}

// MARK: - Appearance

private extension TransferFailedStatusView.Style {
    var appearance: StatusScreenAppearance {
        switch self {
        case .generic, .unavailableRegion: .warning
        case .technicalIssue: .error
        }
    }

    var glyph: StatusIcon.Glyph {
        switch self {
        case .generic: .warning
        case .unavailableRegion, .technicalIssue: .heartBroken
        }
    }

    var tint: Color {
        switch self {
        case .generic, .unavailableRegion: DesignSystem.Color.iconStatusWarning
        case .technicalIssue: DesignSystem.Color.iconStatusError
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

#Preview("Technical issue") {
    TransferFailedStatusView(
        model: TransferFailedStatusView.Model(
            title: "Unable to perform the operation",
            description: "Please try again later.",
            style: .technicalIssue
        ),
        onRetry: {},
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
