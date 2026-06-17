//
//  TangemPayTransactionStatusView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TangemPayTransactionStatusView: View {
    let model: Model

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Tokens.Spacing.s100) {
            VStack(alignment: .leading, spacing: DesignSystem.Tokens.Spacing.s050) {
                Text(model.title)
                    .style(DesignSystem.Tokens.Font.Body.medium, color: model.style.contentColor)

                if let reason = model.reason {
                    Text(reason)
                        .style(DesignSystem.Tokens.Font.Caption.medium, color: model.style.contentColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .infinityFrame(axis: .horizontal, alignment: .leading)

            if let icon = model.style.icon {
                icon.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: DesignSystem.Tokens.Size.s250, height: DesignSystem.Tokens.Size.s250)
                    .foregroundStyle(model.style.iconColor)
            }
        }
        .padding(.leading, DesignSystem.Tokens.Spacing.s200)
        .padding(.trailing, DesignSystem.Tokens.Spacing.s150)
        .padding(.vertical, DesignSystem.Tokens.Spacing.s150)
        .background(
            model.style.backgroundColor,
            in: RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._300, style: .continuous)
        )
    }
}

extension TangemPayTransactionStatusView {
    struct Model: Equatable {
        let style: Style
        let title: String
        let reason: String?
    }

    enum Style: Equatable {
        case inProgress
        case completed
        case rejected
        case reversed

        var backgroundColor: Color {
            switch self {
            case .inProgress: DesignSystem.Tokens.Theme.Bg.Status.infoSubtle
            case .completed: DesignSystem.Tokens.Theme.Bg.Status.successSubtle
            case .rejected: DesignSystem.Tokens.Theme.Bg.Status.errorSubtle
            case .reversed: DesignSystem.Tokens.Theme.Bg.Opaque.primary
            }
        }

        var contentColor: Color {
            switch self {
            case .inProgress: DesignSystem.Tokens.Theme.Text.Status.info
            case .completed: DesignSystem.Tokens.Theme.Text.Status.success
            case .rejected: DesignSystem.Tokens.Theme.Text.Status.error
            case .reversed: DesignSystem.Tokens.Theme.Text.secondary
            }
        }

        var iconColor: Color {
            switch self {
            case .inProgress: DesignSystem.Tokens.Theme.Icon.Status.info
            case .completed: DesignSystem.Tokens.Theme.Icon.Status.success
            case .rejected: DesignSystem.Tokens.Theme.Icon.Status.error
            case .reversed: DesignSystem.Tokens.Theme.Icon.secondary
            }
        }

        var icon: ImageType? {
            switch self {
            case .inProgress: DesignSystem.Icons.Clock.regular20
            case .completed: DesignSystem.Icons.Success.regular20
            case .rejected: DesignSystem.Icons.Error.regular20
            case .reversed: nil
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
struct TangemPayTransactionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignSystem.Tokens.Spacing.s150) {
            TangemPayTransactionStatusView(model: .init(style: .inProgress, title: "In progress", reason: nil))
            TangemPayTransactionStatusView(model: .init(style: .completed, title: "Completed", reason: nil))
            TangemPayTransactionStatusView(
                model: .init(style: .rejected, title: "Declined", reason: "Reason: account credit limit exceeded")
            )
            TangemPayTransactionStatusView(model: .init(style: .reversed, title: "Reversed", reason: nil))
        }
        .padding()
        .background(DesignSystem.Tokens.Theme.Bg.secondary)
    }
}
#endif // DEBUG
