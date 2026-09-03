//
//  PolymarketToWinBadge.swift
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

public struct PolymarketToWinBadge: View, Setupable {
    private let state: State

    private var typographyToken: TangemTypographyToken = DesignSystem.Font.captionMediumToken

    public init(state: State) {
        self.state = state
    }

    public var body: some View {
        label
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.verticalPadding)
            .background(DesignSystem.Color.bgStatusInfoSubtle, in: Capsule())
    }

    private var label: some View {
        Text(Localization.predictionPlaceToWin(amountText))
            .style(typographyToken, color: DesignSystem.Color.textStatusInfo)
            .lineLimit(1)
            .tangemShimmer()
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

public extension PolymarketToWinBadge {
    func typography(_ token: TangemTypographyToken) -> Self {
        map { $0.typographyToken = token }
    }
}

// MARK: - State

public extension PolymarketToWinBadge {
    enum State: Hashable {
        case value(String)
        case loading(previousValue: String?)
        case unavailable
    }
}

// MARK: - Constants

private extension PolymarketToWinBadge {
    enum Constants {
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 2
    }
}
