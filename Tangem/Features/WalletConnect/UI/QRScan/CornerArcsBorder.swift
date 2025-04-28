//
//  CornerArcsBorder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct CornerArcsBorder: Shape {
    let cornerSize: CGSize
    let cornerRadius: CGFloat
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let insetRect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)

        // top left corner
        path.move(to: CGPoint(x: insetRect.minX, y: insetRect.minY + cornerSize.height))
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.minY + cornerRadius))
        path.addArc(
            tangent1End: CGPoint(x: insetRect.minX, y: insetRect.minY),
            tangent2End: CGPoint(x: insetRect.minX + cornerRadius, y: insetRect.minY),
            radius: cornerRadius
        )
        path.addLine(to: CGPoint(x: insetRect.minX + cornerSize.width, y: insetRect.minY))

        // top right corner
        path.move(to: CGPoint(x: insetRect.maxX - cornerSize.width, y: insetRect.minY))
        path.addLine(to: CGPoint(x: insetRect.maxX - cornerRadius, y: insetRect.minY))
        path.addArc(
            tangent1End: CGPoint(x: insetRect.maxX, y: insetRect.minY),
            tangent2End: CGPoint(x: insetRect.maxX, y: insetRect.minY + cornerRadius),
            radius: cornerRadius
        )
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.minY + cornerSize.height))

        // bottom right corner
        path.move(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - cornerSize.height))
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - cornerRadius))
        path.addArc(
            tangent1End: CGPoint(x: insetRect.maxX, y: insetRect.maxY),
            tangent2End: CGPoint(x: insetRect.maxX - cornerRadius, y: insetRect.maxY),
            radius: cornerRadius
        )
        path.addLine(to: CGPoint(x: insetRect.maxX - cornerSize.width, y: insetRect.maxY))

        // bottom left corner
        path.move(to: CGPoint(x: insetRect.minX + cornerSize.width, y: insetRect.maxY))
        path.addLine(to: CGPoint(x: insetRect.minX + cornerRadius, y: insetRect.maxY))
        path.addArc(
            tangent1End: CGPoint(x: insetRect.minX, y: insetRect.maxY),
            tangent2End: CGPoint(x: insetRect.minX, y: insetRect.maxY - cornerRadius),
            radius: cornerRadius
        )
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.maxY - cornerSize.height))

        return path
    }
}
