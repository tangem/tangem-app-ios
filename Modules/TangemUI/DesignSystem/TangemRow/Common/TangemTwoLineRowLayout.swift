//
//  TangemTwoLineRowLayout.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

/// Defines how trailing content is displayed in the row layout.
public enum TangemRowTrailingMode {
    /// Separate trailing views for primary (top) and secondary (bottom) lines.
    case stacked

    /// A single trailing view centered vertically across both lines.
    case centered
}

/// A reusable two-line row layout template that handles compression behavior.
///
/// This layout provides slots for icon, leading content, and trailing content.
/// Trailing content can be displayed in two modes:
/// - `.stacked`: Separate trailing views for top and bottom lines (default)
/// - `.centered`: A single trailing view centered vertically
///
/// The layout automatically applies `layoutPriority()` and minimum width constraints
/// based on the configured compression policy.
///
/// Usage with stacked trailing:
/// ```swift
/// TangemTwoLineRowLayout(
///     icon: { TokenIcon(...) },
///     primaryLeading: { Text("Bitcoin") },
///     primaryTrailing: { Text("$45,000") },
///     secondaryLeading: { Text("$45,000.00") },
///     secondaryTrailing: { Text("1.234 BTC") }
/// )
/// .compressionPolicy(.trailingPreserved)
/// ```
///
/// Usage with centered trailing:
/// ```swift
/// TangemTwoLineRowLayout(
///     icon: { TokenIcon(...) },
///     primaryLeading: { Text("Bitcoin") },
///     secondaryLeading: { Text("$45,000.00") },
///     centeredTrailing: { Image(systemName: "chevron.right") }
/// )
/// ```
public struct TangemTwoLineRowLayout<
    Icon: View,
    PrimaryLeading: View,
    PrimaryTrailing: View,
    SecondaryLeading: View,
    SecondaryTrailing: View
>: View {
    private typealias Constants = TangemRowConstants

    private let icon: Icon
    private let primaryLeading: PrimaryLeading
    private let primaryTrailing: PrimaryTrailing
    private let secondaryLeading: SecondaryLeading
    private let secondaryTrailing: SecondaryTrailing
    private let trailingMode: TangemRowTrailingMode

    @ScaledMetric private var iconSpacing: CGFloat = Constants.Spacings.imageSpacing.value
    @ScaledMetric private var linesSpacing: CGFloat = Constants.Spacings.multilineSpacing.value
    @ScaledMetric private var innerSpacing: CGFloat = Constants.Spacings.topLineInnerSpacing.value

    @State private var contentWidth: CGFloat = 0

    private var compressionPolicy: TangemRowCompressionPolicy = .trailingPreserved

    public init(
        @ViewBuilder icon: () -> Icon,
        @ViewBuilder primaryLeading: () -> PrimaryLeading,
        @ViewBuilder primaryTrailing: () -> PrimaryTrailing,
        @ViewBuilder secondaryLeading: () -> SecondaryLeading,
        @ViewBuilder secondaryTrailing: () -> SecondaryTrailing
    ) {
        self.icon = icon()
        self.primaryLeading = primaryLeading()
        self.primaryTrailing = primaryTrailing()
        self.secondaryLeading = secondaryLeading()
        self.secondaryTrailing = secondaryTrailing()

        trailingMode = .stacked
    }

    private init(
        icon: Icon,
        primaryLeading: PrimaryLeading,
        primaryTrailing: PrimaryTrailing,
        secondaryLeading: SecondaryLeading,
        secondaryTrailing: SecondaryTrailing,
        trailingMode: TangemRowTrailingMode
    ) {
        self.icon = icon
        self.primaryLeading = primaryLeading
        self.primaryTrailing = primaryTrailing
        self.secondaryLeading = secondaryLeading
        self.secondaryTrailing = secondaryTrailing
        self.trailingMode = trailingMode
    }

    public var body: some View {
        HStack(spacing: iconSpacing) {
            icon

            contentView
        }
        .readGeometry(\.size.width, bindTo: $contentWidth)
    }

    @ViewBuilder
    private var contentView: some View {
        switch trailingMode {
        case .stacked:
            stackedContentView
        case .centered:
            centeredContentView
        }
    }

    private var stackedContentView: some View {
        let priorities = compressionPolicy.priorities

        return VStack(spacing: linesSpacing) {
            // Primary line
            HStack(spacing: innerSpacing) {
                primaryLeading
                    .layoutPriority(priorities.primaryLeading)
                    .frame(
                        minWidth: contentWidth * Constants.Layout.MinWidthRatio.primaryLeading,
                        alignment: .leading
                    )

                Spacer(minLength: 0)

                primaryTrailing
                    .layoutPriority(priorities.primaryTrailing)
            }

            // Secondary line
            HStack(spacing: innerSpacing) {
                secondaryLeading
                    .layoutPriority(priorities.secondaryLeading)
                    .frame(
                        minWidth: contentWidth * Constants.Layout.MinWidthRatio.secondaryLeading,
                        alignment: .leading
                    )

                Spacer(minLength: 0)

                secondaryTrailing
                    .layoutPriority(priorities.secondaryTrailing)
            }
        }
    }

    private var centeredContentView: some View {
        let priorities = compressionPolicy.priorities

        return HStack(spacing: innerSpacing) {
            VStack(alignment: .leading, spacing: linesSpacing) {
                primaryLeading
                    .layoutPriority(priorities.primaryLeading)

                secondaryLeading
                    .layoutPriority(priorities.secondaryLeading)
            }
            .frame(
                minWidth: contentWidth * Constants.Layout.MinWidthRatio.primaryLeading,
                alignment: .leading
            )

            Spacer(minLength: 0)

            // In centered mode, primaryTrailing is used as the centered view
            primaryTrailing
                .layoutPriority(priorities.primaryTrailing)
        }
    }
}

// MARK: - Setupable

extension TangemTwoLineRowLayout: Setupable {
    /// Sets the compression policy for the layout.
    /// - Parameter policy: The compression policy to apply.
    /// - Returns: A modified layout with the specified compression policy.
    public func compressionPolicy(_ policy: TangemRowCompressionPolicy) -> Self {
        map { $0.compressionPolicy = policy }
    }
}

// MARK: - Convenience Initializers

public extension TangemTwoLineRowLayout where Icon == EmptyView {
    /// Creates a two-line row layout without an icon.
    init(
        @ViewBuilder primaryLeading: () -> PrimaryLeading,
        @ViewBuilder primaryTrailing: () -> PrimaryTrailing,
        @ViewBuilder secondaryLeading: () -> SecondaryLeading,
        @ViewBuilder secondaryTrailing: () -> SecondaryTrailing
    ) {
        self.init(
            icon: { EmptyView() },
            primaryLeading: primaryLeading,
            primaryTrailing: primaryTrailing,
            secondaryLeading: secondaryLeading,
            secondaryTrailing: secondaryTrailing
        )
    }
}

public extension TangemTwoLineRowLayout where SecondaryTrailing == EmptyView {
    /// Creates a two-line row layout with a single centered trailing view.
    ///
    /// Use this initializer when you want a single accessory (like a chevron or icon)
    /// centered vertically across both lines instead of separate trailing content.
    init(
        @ViewBuilder icon: () -> Icon,
        @ViewBuilder primaryLeading: () -> PrimaryLeading,
        @ViewBuilder secondaryLeading: () -> SecondaryLeading,
        @ViewBuilder centeredTrailing: () -> PrimaryTrailing
    ) {
        self.init(
            icon: icon(),
            primaryLeading: primaryLeading(),
            primaryTrailing: centeredTrailing(),
            secondaryLeading: secondaryLeading(),
            secondaryTrailing: EmptyView(),
            trailingMode: .centered
        )
    }
}

public extension TangemTwoLineRowLayout where Icon == EmptyView, SecondaryTrailing == EmptyView {
    /// Creates a two-line row layout without an icon and with a single centered trailing view.
    init(
        @ViewBuilder primaryLeading: () -> PrimaryLeading,
        @ViewBuilder secondaryLeading: () -> SecondaryLeading,
        @ViewBuilder centeredTrailing: () -> PrimaryTrailing
    ) {
        self.init(
            icon: EmptyView(),
            primaryLeading: primaryLeading(),
            primaryTrailing: centeredTrailing(),
            secondaryLeading: secondaryLeading(),
            secondaryTrailing: EmptyView(),
            trailingMode: .centered
        )
    }
}

// MARK: - Previews

#if DEBUG

private var previewIcon: some View {
    Circle()
        .fill(Color.orange)
        .frame(size: .init(bothDimensions: 36))
}

@available(iOS 17, *)
#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        // Trailing preserved (default)
        TangemTwoLineRowLayout(
            icon: { previewIcon },
            primaryLeading: { Text("Bitcoin Very Long Name").lineLimit(1) },
            primaryTrailing: { Text("$45,123.45").lineLimit(1) },
            secondaryLeading: { Text("$45,000.00").lineLimit(1) },
            secondaryTrailing: { Text("1.234567890 BTC").lineLimit(1) }
        )
        .compressionPolicy(.trailingPreserved)

        Divider()

        // Leading preserved
        TangemTwoLineRowLayout(
            icon: { previewIcon },
            primaryLeading: { Text("Bitcoin Very Long Name").lineLimit(1) },
            primaryTrailing: { Text("$45,123.45").lineLimit(1) },
            secondaryLeading: { Text("$45,000.00").lineLimit(1) },
            secondaryTrailing: { Text("1.234567890 BTC").lineLimit(1) }
        )
        .compressionPolicy(.leadingPreserved)

        Divider()

        // Without icon
        TangemTwoLineRowLayout(
            primaryLeading: { Text("No Icon Row").lineLimit(1) },
            primaryTrailing: { Text("$1,000.00").lineLimit(1) },
            secondaryLeading: { Text("Price").lineLimit(1) },
            secondaryTrailing: { Text("100 TOKEN").lineLimit(1) }
        )
    }
    .padding()
}

@available(iOS 17, *)
#Preview("Huge Dynamic Type", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        TangemTwoLineRowLayout(
            icon: { previewIcon },
            primaryLeading: { Text("Bitcoin Very Long Name").lineLimit(1) },
            primaryTrailing: { Text("$45,123.45").lineLimit(1) },
            secondaryLeading: { Text("$45,000.00").lineLimit(1) },
            secondaryTrailing: { Text("1.234567890 BTC").lineLimit(1) }
        )
        .compressionPolicy(.trailingPreserved)

        Divider()

        TangemTwoLineRowLayout(
            icon: { previewIcon },
            primaryLeading: { Text("Ethereum").lineLimit(1) },
            primaryTrailing: { Text("$3,200.00").lineLimit(1) },
            secondaryLeading: { Text("$2,133.33").lineLimit(1) },
            secondaryTrailing: { Text("1.5 ETH").lineLimit(1) }
        )
        .compressionPolicy(.trailingPreserved)
    }
    .padding()
    .environment(\.dynamicTypeSize, .accessibility5)
}

@available(iOS 17, *)
#Preview("Centered Trailing", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        // With chevron accessory
        TangemTwoLineRowLayout(
            icon: { previewIcon },
            primaryLeading: { Text("Bitcoin").lineLimit(1) },
            secondaryLeading: { Text("$45,000.00").lineLimit(1) },
            centeredTrailing: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        )

        Divider()

        // With checkmark accessory
        TangemTwoLineRowLayout(
            icon: { previewIcon },
            primaryLeading: { Text("Ethereum Very Long Name").lineLimit(1) },
            secondaryLeading: { Text("Selected Network").lineLimit(1) },
            centeredTrailing: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        )

        Divider()

        // Without icon, with centered trailing
        TangemTwoLineRowLayout(
            primaryLeading: { Text("Settings Option").lineLimit(1) },
            secondaryLeading: { Text("Description text").lineLimit(1) },
            centeredTrailing: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        )
    }
    .padding()
}

@available(iOS 17, *)
#Preview("Centered Trailing Dynamic Type", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        TangemTwoLineRowLayout(
            icon: { previewIcon },
            primaryLeading: { Text("Bitcoin").lineLimit(1) },
            secondaryLeading: { Text("$45,000.00").lineLimit(1) },
            centeredTrailing: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        )
    }
    .padding()
    .environment(\.dynamicTypeSize, .accessibility5)
}

@available(iOS 17, *)
#Preview("Dark Mode", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        TangemTwoLineRowLayout(
            icon: { previewIcon },
            primaryLeading: { Text("Bitcoin").lineLimit(1) },
            primaryTrailing: { Text("$45,123.45").lineLimit(1) },
            secondaryLeading: { Text("$45,000.00").lineLimit(1) },
            secondaryTrailing: { Text("1.234567890 BTC").lineLimit(1) }
        )
        .compressionPolicy(.trailingPreserved)

        Divider()

        TangemTwoLineRowLayout(
            icon: { previewIcon },
            primaryLeading: { Text("Ethereum").lineLimit(1) },
            secondaryLeading: { Text("Selected Network").lineLimit(1) },
            centeredTrailing: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        )
    }
    .padding()
    .preferredColorScheme(.dark)
}

#endif // DEBUG
