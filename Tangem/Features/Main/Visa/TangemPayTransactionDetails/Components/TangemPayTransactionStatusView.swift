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
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: model.style.contentColor)

                if let reason = model.reason {
                    Text(reason)
                        .style(DesignSystem.Font.captionMediumToken, color: model.style.contentColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .infinityFrame(axis: .horizontal, alignment: .leading)

            if let icon = model.style.icon {
                icon.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(model.style.iconColor)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.vertical, 12)
        .background(
            model.style.backgroundColor,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
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
            case .inProgress: DesignSystem.Color.bgStatusInfoSubtle
            case .completed: DesignSystem.Color.bgStatusSuccessSubtle
            case .rejected: DesignSystem.Color.bgStatusErrorSubtle
            case .reversed: DesignSystem.Color.bgOpaquePrimary
            }
        }

        var contentColor: Color {
            switch self {
            case .inProgress: DesignSystem.Color.textStatusInfo
            case .completed: DesignSystem.Color.textStatusSuccess
            case .rejected: DesignSystem.Color.textStatusError
            case .reversed: DesignSystem.Color.textSecondary
            }
        }

        var iconColor: Color {
            switch self {
            case .inProgress: DesignSystem.Color.iconStatusInfo
            case .completed: DesignSystem.Color.iconStatusSuccess
            case .rejected: DesignSystem.Color.iconStatusError
            case .reversed: DesignSystem.Color.iconSecondary
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
        VStack(spacing: 12) {
            TangemPayTransactionStatusView(model: .init(style: .inProgress, title: "In progress", reason: nil))
            TangemPayTransactionStatusView(model: .init(style: .completed, title: "Completed", reason: nil))
            TangemPayTransactionStatusView(
                model: .init(style: .rejected, title: "Declined", reason: "Reason: account credit limit exceeded")
            )
            TangemPayTransactionStatusView(model: .init(style: .reversed, title: "Reversed", reason: nil))
        }
        .padding()
        .background(DesignSystem.Color.bgSecondary)
    }
}
#endif // DEBUG
