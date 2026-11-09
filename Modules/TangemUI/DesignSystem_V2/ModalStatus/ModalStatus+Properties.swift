//
//  ModalStatus+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public enum ModalStatusAppearance: Hashable, Sendable {
    case neutral(ImageType)
    case success
    case error
    case warning
    case info
}

extension ModalStatusAppearance {
    var glyph: ImageType {
        switch self {
        case .neutral(let icon):
            icon
        case .success:
            DesignSystem.Icons.Success.regular32
        case .error:
            DesignSystem.Icons.HeartBroken.regular32
        case .warning:
            // [REDACTED_TODO_COMMENT]
            DesignSystem.Icons.Warning.regular28
        case .info:
            DesignSystem.Icons.Info.regular32
        }
    }

    var avatarAppearance: Avatar.IconAppearance {
        switch self {
        case .neutral: .neutral
        case .success: .success
        case .error: .error
        case .warning: .warning
        case .info: .info
        }
    }
}

public enum ModalStatusTitleStyle: Hashable, Sendable, CaseIterable {
    case status
    case amountMessage
    case amount
}

extension ModalStatusTitleStyle {
    var font: TangemTypographyToken {
        switch self {
        case .status: DesignSystem.Font.headingSmallToken
        case .amountMessage: DesignSystem.Font.headingMediumToken
        case .amount: DesignSystem.Font.displayMediumToken
        }
    }
}

struct ModalStatusActions {
    let primary: Button
    let secondary: Button?
}
