//
//  TangemCallout.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public struct TangemCallout: View, Setupable {
    private let text: String
    private let arrowAlignment: ArrowAlignment
    private let action: Action

    @ScaledMetric private var scaleFactor: CGFloat = 1

    private var icon: Image?
    private var colorPalette: ColorPalette = .green

    public init(
        text: String,
        arrowAlignment: ArrowAlignment,
        action: Action
    ) {
        self.text = text
        self.arrowAlignment = arrowAlignment
        self.action = action
    }

    public var body: some View {
        ZStack(alignment: alignment) {
            contentView
            arrowView
        }
    }
}

// MARK: - Subviews

private extension TangemCallout {
    var contentView: some View {
        HStack(spacing: .unit(.x1) * scaleFactor) {
            if let icon {
                iconView(icon)
            }

            Text(text)
                .style(textFont, color: colorPalette.text)

            actionView(action)
        }
        .padding(
            EdgeInsets(
                top: SizeUnit.half.value,
                leading: SizeUnit.x2.value,
                bottom: SizeUnit.half.value,
                trailing: SizeUnit.half.value
            )
            .scaled(factor: scaleFactor)
        )
        .background(colorPalette.background, in: shape)
    }

    var arrowView: some View {
        ArrowShape()
            .fill(colorPalette.background)
            .alignmentGuide(.leading) { arrowLeadingOffset(dimensions: $0) }
            .alignmentGuide(.top) { $0.height }
            .alignmentGuide(.bottom) { _ in .zero }
            .scaleEffect(x: 1, y: arrowScaleFactorY, anchor: .center)
            .frame(width: Sizes.arrowSide * scaleFactor, height: Sizes.arrowSide * scaleFactor)
    }

    func iconView(_ icon: Image) -> some View {
        icon
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(colorPalette.icon)
            .frame(width: SizeUnit.x3.value * scaleFactor, height: SizeUnit.x3.value * scaleFactor)
    }

    func actionView(_ action: Action) -> some View {
        iconView(action.icon)
            .padding(
                EdgeInsets(
                    top: SizeUnit.half.value,
                    leading: SizeUnit.x1_5.value,
                    bottom: SizeUnit.half.value,
                    trailing: SizeUnit.x1_5.value
                )
                .scaled(factor: scaleFactor)
            )
            .background(colorPalette.background, in: shape)
            .contentShape(shape)
            .onTapGesture(perform: action.closure)
    }
}

// MARK: - Calculations

private extension TangemCallout {
    var alignment: Alignment {
        alignment(arrowAlignment: arrowAlignment)
    }

    var arrowScaleFactorY: CGFloat {
        switch arrowAlignment {
        case .top: 1
        case .bottom: -1
        }
    }

    func arrowLeadingOffset(dimensions: ViewDimensions) -> CGFloat {
        dimensions.width * -2
    }
}

// MARK: - Setupable

public extension TangemCallout {
    func icon(_ icon: Image?) -> Self {
        map { $0.icon = icon }
    }

    func colorPalette(_ colorPalette: ColorPalette) -> Self {
        map { $0.colorPalette = colorPalette }
    }
}

public extension TangemCallout {
    enum Sizes {
        public static let arrowSide = CGFloat.unit(.x2)
    }
}

// MARK: - Arrow shape

private struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let startPoint = CGPoint(x: rect.minX, y: rect.maxY)
        let curveStartPoint = CGPoint(x: rect.minX, y: rect.minY)
        let curveControlPoint = CGPoint(x: rect.maxX * 0.25, y: rect.maxY * 0.75)
        let curveEndPoint = CGPoint(x: rect.maxX, y: rect.maxY)

        path.move(to: startPoint)
        path.addLine(to: curveStartPoint)

        path.addQuadCurve(
            to: curveEndPoint,
            control: curveControlPoint
        )

        path.addLine(to: startPoint)
        path.closeSubpath()

        return path
    }
}

private extension EdgeInsets {
    func scaled(factor: CGFloat) -> EdgeInsets {
        EdgeInsets(top: top * factor, leading: leading * factor, bottom: bottom * factor, trailing: trailing * factor)
    }
}
