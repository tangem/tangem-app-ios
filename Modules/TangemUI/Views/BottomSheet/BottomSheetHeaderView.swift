//
//  BottomSheetHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct BottomSheetHeaderView<Leading: View, Trailing: View>: View {
    @Environment(\.isRedesign) private var isRedesign: Bool
    @State private var sideWidth: CGFloat?

    private let title: String
    private let subtitle: String?
    private let leading: Leading
    private let trailing: Trailing
    private let titleAccessibilityIdentifier: String?

    private var titleStyle = TangemFontStyle(font: Fonts.Bold.body)
    private var titleColor: Color = Colors.Text.primary1
    private var horizontalSpacing: CGFloat = 8
    private var subtitleSpacing: CGFloat = 12
    private var verticalPadding: CGFloat = 12

    public init(
        title: String,
        subtitle: String? = nil,
        titleAccessibilityIdentifier: String? = nil,
        @ViewBuilder leading: @escaping (() -> Leading) = { EmptyView() },
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.titleAccessibilityIdentifier = titleAccessibilityIdentifier
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        if isRedesign {
            redesignBody
        } else {
            legacyBody
        }
    }
}

// MARK: - Subviews

private extension BottomSheetHeaderView {
    var redesignBody: some View {
        HStack(spacing: 0) {
            leading
                .onGeometryChange(for: CGFloat.self, of: \.size.width, action: updateSide(width:))
                .frame(width: sideWidth, alignment: .leading)

            Spacer(minLength: horizontalSpacing)

            VStack(spacing: subtitleSpacing) {
                Text(title)
                    .style(titleStyle, color: titleColor)
                    .accessibilityIdentifier(titleAccessibilityIdentifier)

                if let subtitle {
                    Text(subtitle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                }
            }
            .lineLimit(nil)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: horizontalSpacing)

            trailing
                .onGeometryChange(for: CGFloat.self, of: \.size.width, action: updateSide(width:))
                .frame(width: sideWidth, alignment: .trailing)
        }
        .padding(.vertical, verticalPadding)
    }

    var legacyBody: some View {
        ZStack(alignment: .center) {
            // Title layer
            VStack(spacing: subtitleSpacing) {
                Text(title)
                    .style(titleStyle, color: titleColor)
                    .accessibilityIdentifier(titleAccessibilityIdentifier)

                if let subtitle {
                    Text(subtitle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                }
            }

            // Buttons layer
            HStack(spacing: .zero) {
                leading

                Spacer()

                trailing
            }
        }
        .infinityFrame(axis: .horizontal)
        .multilineTextAlignment(.center)
        .padding(.vertical, verticalPadding)
    }
}

// MARK: - Layout update

private extension BottomSheetHeaderView {
    func updateSide(width: CGFloat) {
        sideWidth = max(sideWidth ?? 0, width.roundedToDeviceScale())
    }
}

// MARK: - Setupable

extension BottomSheetHeaderView: Setupable {
    public func titleFont(_ font: Font) -> Self {
        map { $0.titleStyle = TangemFontStyle(font: font) }
    }

    public func titleStyle(_ style: TangemFontStyle, color: Color) -> Self {
        map {
            $0.titleStyle = style
            $0.titleColor = color
        }
    }

    public func titleColor(_ color: Color) -> Self {
        map { $0.titleColor = color }
    }

    public func subtitleSpacing(_ spacing: CGFloat) -> Self {
        map { $0.subtitleSpacing = spacing }
    }

    public func verticalPadding(_ padding: CGFloat) -> Self {
        map { $0.verticalPadding = padding }
    }
}
