//
//  ProgressArc.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// Circular arc drawn clockwise from 12 o'clock; `progress == 1` closes the full circle.
public struct ProgressArc: Shape {
    /// Arc fill fraction; values outside `0...1` are clamped at render time.
    public var progress: Double

    private var insetAmount: CGFloat = 0

    public init(progress: Double) {
        self.progress = progress
    }

    public var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    public func path(in rect: CGRect) -> Path {
        // Clamped here rather than in the initializer: spring animations drive
        // `animatableData` slightly past the endpoints, and an overshoot
        // beyond 1.0 would wrap the arc over its own start.
        let progress = min(max(progress, 0), 1)
        let startAngle = Angle.degrees(-90)

        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2 - insetAmount,
            startAngle: startAngle,
            endAngle: startAngle + .degrees(360 * progress),
            // SwiftUI's Y axis is flipped relative to Core Graphics,
            // so `clockwise: false` renders clockwise on screen.
            clockwise: false
        )
        return path
    }
}

// MARK: - InsettableShape

extension ProgressArc: InsettableShape {
    public func inset(by amount: CGFloat) -> Self {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}
