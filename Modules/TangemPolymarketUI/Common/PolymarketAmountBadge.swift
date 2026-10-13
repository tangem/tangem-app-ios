//
//  PolymarketAmountBadge.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

public struct PolymarketAmountBadge: View, Setupable {
    private let state: State
    private let appearance: Appearance
    private let label: (String) -> String

    private var typographyToken: TangemTypographyToken = DesignSystem.Font.captionMediumToken

    public init(state: State, appearance: Appearance, label: @escaping (String) -> String) {
        self.state = state
        self.appearance = appearance
        self.label = label
    }

    public var body: some View {
        text
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.verticalPadding)
            .frame(minHeight: Constants.minHeight)
            .background(appearance.backgroundColor, in: Capsule())
    }

    private var text: some View {
        Text(label(amountText))
            .style(typographyToken, color: appearance.foregroundColor)
            .lineLimit(1)
            .shimmering()
            .environment(\.isShimmerActive, isLoading)
    }

    private var amountText: String {
        switch state {
        case .value(let value): value
        case .loading(.some(let previousValue)): previousValue
        case .loading(.none), .unavailable: String.enDashSign
        }
    }

    private var isLoading: Bool {
        if case .loading = state {
            return true
        }

        return false
    }
}

// MARK: - Setupable Modifiers

public extension PolymarketAmountBadge {
    func typography(_ token: TangemTypographyToken) -> Self {
        map { $0.typographyToken = token }
    }
}

// MARK: - Appearance

public extension PolymarketAmountBadge {
    enum Appearance: Hashable, Sendable {
        case info
        case warning

        var backgroundColor: Color {
            switch self {
            case .info: DesignSystem.Color.bgStatusInfoSubtle
            case .warning: DesignSystem.Color.bgStatusWarningSubtle
            }
        }

        var foregroundColor: Color {
            switch self {
            case .info: DesignSystem.Color.textStatusInfo
            case .warning: DesignSystem.Color.textStatusWarning
            }
        }
    }
}

// MARK: - State

public extension PolymarketAmountBadge {
    enum State: Hashable {
        case value(String)
        case loading(previousValue: String?)
        case unavailable
    }
}

// MARK: - Constants

private extension PolymarketAmountBadge {
    enum Constants {
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 2
        static let minHeight: CGFloat = 24
    }
}

// MARK: - Badges

public extension PolymarketAmountBadge {
    static func toWin(state: State) -> PolymarketAmountBadge {
        PolymarketAmountBadge(state: state, appearance: .info, label: Localization.predictionPlaceToWin)
    }

    static func payout(state: State) -> PolymarketAmountBadge {
        PolymarketAmountBadge(state: state, appearance: .info, label: Localization.predictionPositionsPayout)
    }
}
