//
//  HorizontalLine.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public struct HorizontalLine: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 24) {
        HorizontalLine()
            .stroke(Color.primary, lineWidth: 1)
            .frame(height: 1)

        HorizontalLine()
            .stroke(Color.primary, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .frame(height: 1)

        HorizontalLine()
            .stroke(Color.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [1, 7]))
            .frame(height: 3)
    }
    .padding()
}
