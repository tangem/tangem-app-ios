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

    @ScaledMetric private var horizontalSpacing: CGFloat
    @ScaledSize private var arrowSize: CGSize
    @ScaledSize private var iconSize: CGSize
    @ScaledInsets private var padding: EdgeInsets
    @ScaledInsets private var buttonPadding: EdgeInsets

    private var icon: Image?
    private var color: CalloutColor = .green

    public init(
        text: String,
        arrowAlignment: ArrowAlignment,
        action: Action
    ) {
        self.text = text
        self.arrowAlignment = arrowAlignment
        self.action = action

        _horizontalSpacing = ScaledMetric(wrappedValue: SizeUnit.x1.value)
        _arrowSize = ScaledSize(wrappedValue: CGSize(bothDimensions: SizeUnit.x2.value))
        _iconSize = ScaledSize(wrappedValue: CGSize(bothDimensions: SizeUnit.x3.value))
        _padding = ScaledInsets(wrappedValue: EdgeInsets(
            top: SizeUnit.half.value,
            leading: SizeUnit.x2.value,
            bottom: SizeUnit.half.value,
            trailing: SizeUnit.half.value
        ))
        _buttonPadding = ScaledInsets(wrappedValue: EdgeInsets(
            top: SizeUnit.half.value,
            leading: SizeUnit.x1_5.value,
            bottom: SizeUnit.half.value,
            trailing: SizeUnit.x1_5.value
        ))
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
        HStack(spacing: horizontalSpacing) {
            if let icon {
                iconView(icon)
            }

            Text(text)
                .style(textFont, color: textColor(color: color))

            actionView(action)
        }
        .padding(padding)
        .background(backgroundColor(color: color), in: shape)
    }

    var arrowView: some View {
        ArrowShape()
            .fill(backgroundColor(color: color))
            .alignmentGuide(.leading) { arrowLeadingOffset(dimensions: $0) }
            .alignmentGuide(.top) { $0.height }
            .alignmentGuide(.bottom) { _ in .zero }
            .scaleEffect(x: 1, y: arrowScaleFactorY, anchor: .center)
            .frame(size: arrowSize)
    }

    func iconView(_ icon: Image) -> some View {
        icon
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(iconColor(color: color))
            .frame(size: iconSize)
    }

    func actionView(_ action: Action) -> some View {
        iconView(action.icon)
            .padding(buttonPadding)
            .background(backgroundColor(color: color), in: shape)
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

    func color(_ color: CalloutColor) -> Self {
        map { $0.color = color }
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
