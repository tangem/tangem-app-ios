//
//  ProgressDots.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct ProgressDots: View {
    let style: Style
    @State private var loading = false

    var body: some View {
        HStack(spacing: style.spacing) {
            ForEach(0 ..< 3) { index in
                Circle()
                    .fill(Colors.Icon.accent)
                    .frame(width: style.size, height: style.size)
                    .scaleEffect(loading ? 0.75 : 1)
                    .opacity(loading ? 0.25 : 1)
                    .animation(animation(index: index), value: loading)
            }
        }
        .onAppear {
            if !loading {
                loading = true
            }
        }
        .onDisappear {
            if loading {
                loading = false
            }
        }
    }

    func animation(index: Int) -> Animation {
        .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
            // Start animation with delay depends of index
            // Index(0) -> delay(0)
            // Index(1) -> delay(0.3)
            // Index(2) -> delay(0.6)
            .delay(CGFloat(index) * 0.3)
    }
}

extension ProgressDots {
    enum Style: Hashable {
        case small
        case large

        var size: CGFloat {
            switch self {
            case .small: 3
            case .large: 8
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: 3
            case .large: 6
            }
        }
    }
}

#Preview {
    ProgressDots(style: .small)

    ProgressDots(style: .large)
}
