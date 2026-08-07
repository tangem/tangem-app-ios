//
//  TokenRowTitleAccessory.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public enum TokenRowAccent: Sendable, Hashable, CaseIterable {
    case yield
    case staking
}

public struct TokenRowTitleAccessory: View {
    private let model: Model

    public init(_ model: Model) {
        self.model = model
    }

    @ViewBuilder
    public var body: some View {
        switch model {
        case .reward(let reward):
            rewardChip(reward)

        case .pending(let accessibilityLabel):
            pendingDots(accessibilityLabel: accessibilityLabel)
        }
    }
}

// MARK: - Leaves

private extension TokenRowTitleAccessory {
    func rewardChip(_ reward: Model.Reward) -> some View {
        Badge(label: reward.label, accessibilityLabel: reward.accessibilityLabel)
            .size(.x4)
            .variant(.tinted)
            .appearance(appearance(for: reward))
            .tangemShimmer()
            .environment(\.isShimmerActive, reward.isUpdating)
    }

    func pendingDots(accessibilityLabel: String?) -> some View {
        ProgressDots(style: .small, color: DesignSystem.Color.iconStatusInfo)
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHidden(accessibilityLabel == nil)
    }

    func appearance(for reward: Model.Reward) -> BadgeAppearance {
        guard reward.isActive else {
            return .neutral
        }

        switch reward.accent {
        case .yield: return .success
        case .staking: return .info
        }
    }
}

// MARK: - Model

public extension TokenRowTitleAccessory {
    typealias Accent = TokenRowAccent

    enum Model: Equatable, Hashable, Sendable {
        case reward(Reward)
        case pending(accessibilityLabel: String? = nil)
    }
}

public extension TokenRowTitleAccessory.Model {
    struct Reward: Equatable, Hashable, Sendable {
        public let label: String
        public let accent: TokenRowAccent
        public let isActive: Bool
        public let isUpdating: Bool
        public let accessibilityLabel: String?

        public init(
            label: String,
            accent: TokenRowAccent,
            isActive: Bool,
            isUpdating: Bool = false,
            accessibilityLabel: String? = nil
        ) {
            self.label = label
            self.accent = accent
            self.isActive = isActive
            self.isUpdating = isUpdating
            self.accessibilityLabel = accessibilityLabel
        }
    }
}
