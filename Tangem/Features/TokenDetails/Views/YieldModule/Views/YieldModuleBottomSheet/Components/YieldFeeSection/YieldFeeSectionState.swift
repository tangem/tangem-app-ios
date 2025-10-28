//
//  YieldFeeSectionState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct YieldFeeSectionState: Equatable {
    private(set) var feeState: LoadableTextView.State
    private(set) var footerText: String?
    private(set) var isLinkActive: Bool
    private(set) var isHighlighted: Bool

    init(
        feeState: LoadableTextView.State = .initialized,
        footerText: String? = nil,
        isLinkActive: Bool = false,
        isHighlighted: Bool = false
    ) {
        self.feeState = feeState
        self.footerText = footerText
        self.isLinkActive = isLinkActive
        self.isHighlighted = isHighlighted
    }
}

// MARK: - Mutating helpers

extension YieldFeeSectionState {
    func withFeeState(_ newState: LoadableTextView.State) -> Self {
        var copy = self
        copy.feeState = newState
        return copy
    }

    func withFooterText(_ newText: String?) -> Self {
        var copy = self
        copy.footerText = newText
        return copy
    }

    func withLinkActive(_ newValue: Bool) -> Self {
        var copy = self
        copy.isLinkActive = newValue
        return copy
    }

    func withHighlighted(_ newValue: Bool) -> Self {
        var copy = self
        copy.isHighlighted = newValue
        return copy
    }
}
