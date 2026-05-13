//
//  TokenDetailsBalanceStateView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TokenDetailsBalanceStateView: View {
    let state: TokenDetailsBalanceState
    let skeletonSize: CGSize

    var body: some View {
        switch state {
        case .loaded(let text):
            textView(text)

        case .loadingCached(let text):
            textView(text)
                .shimmer()

        case .loading:
            skeletonView(size: skeletonSize)

        case .failed(let text):
            textView(text)
        }
    }
}

// MARK: - Subviews

private extension TokenDetailsBalanceStateView {
    func textView(_ text: TokenDetailsBalanceState.Text) -> some View {
        SensitiveText(text)
    }

    func skeletonView(size: CGSize) -> some View {
        SkeletonView()
            .frame(size: size)
            .clipShape(.capsule)
    }
}
