//
//  View+BuildThumbnailShape.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func buildFilledThumbnailShape(
        context: GraphicsContext,
        parts: [ThumbnailPathFillMode]
    ) {
        parts
            .forEach { mode in
                switch mode {
                case .fill(let path, let color, let stroke):
                    context
                        .fill(path, with: .color(color))
                    context
                        .drawStrokeBorder(path: path, stroke: stroke)

                case .subtracting(let origin, let subtracting, let color, let stroke):
                    let path = Path(
                        origin.cgPath
                            .subtracting(
                                subtracting.cgPath,
                                using: .winding
                            )
                    )
                    context.fill(
                        path,
                        with: .color(color)
                    )
                    context.drawStrokeBorder(path: path, stroke: stroke)
                }
            }
    }
}

private extension GraphicsContext {
    func drawStrokeBorder(
        path: Path,
        stroke: ThumbnailPathFillMode.Stroke?
    ) {
        guard let stroke else { return }
        drawStrokeInside(path, with: .color(stroke.color), lineWidth: stroke.style.lineWidth)
    }

    func drawStrokeInside(
        _ path: Path,
        with shading: Shading,
        lineWidth: CGFloat,
        lineCap: CGLineCap = .butt,
        lineJoin: CGLineJoin = .miter,
        miterLimit: CGFloat = 10
    ) {
        let strokeCGPath = path.cgPath.copy(
            strokingWithWidth: lineWidth,
            lineCap: lineCap,
            lineJoin: lineJoin,
            miterLimit: miterLimit
        )

        let insidePath = Path(
            path.cgPath.intersection(strokeCGPath, using: .winding)
        )
        fill(insidePath, with: shading)
    }
}
