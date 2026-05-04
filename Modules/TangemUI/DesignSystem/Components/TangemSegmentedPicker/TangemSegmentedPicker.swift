//
//  TangemSegmentedPicker.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public struct TangemSegmentedPicker<Data>: View, Setupable
    where Data: RandomAccessCollection, Data.Element: TangemSegmentedPickerTextProvider {
    fileprivate typealias Item = Data.Element

    @Environment(\.isEnabled) private var isEnabled

    @ScaledMetric private var spacing: CGFloat
    @ScaledMetric private var padding: CGFloat
    @ScaledMetric private var separatorWidth: CGFloat
    @ScaledMetric private var separatorPadding: CGFloat
    @ScaledMetric private var shadowRadius: CGFloat
    @ScaledMetric private var shadowY: CGFloat
    @ScaledMetric private var contentHorizontalPadding: CGFloat
    @ScaledMetric private var contentVerticalPadding: CGFloat

    private let data: Data
    @Binding private var selection: Data.Element

    private var style: TangemSegmentedPickerStyle = .fixed
    private var showSeparators: Bool = true

    @State private var frameHeight: CGFloat?
    @State private var segmentsPreference: [SegmentPreference] = []
    private let coordinateSpaceName = "TangemSegmentedPickerCoordinateSpace"

    @State private var geometricId = "geometricId"
    @Namespace private var geometricNamespace

    private var segmentMaxWidth: CGFloat? {
        switch style {
        case .fixed: nil
        case .flexible: .infinity
        }
    }

    private var segmentHorizontalPadding: CGFloat? {
        switch style {
        case .fixed: contentHorizontalPadding
        case .flexible: .zero
        }
    }

    private var segmentVerticalPadding: CGFloat {
        contentVerticalPadding
    }

    private let animation: Animation = .spring

    public init(
        data: Data,
        selection: Binding<Data.Element>
    ) {
        self.data = data
        _selection = selection

        _spacing = ScaledMetric(wrappedValue: .unit(.x1))
        _padding = ScaledMetric(wrappedValue: .unit(.half))
        _separatorWidth = ScaledMetric(wrappedValue: .unit(.eighth))
        _separatorPadding = ScaledMetric(wrappedValue: .unit(.x2))
        _shadowRadius = ScaledMetric(wrappedValue: .unit(.half))
        _shadowY = ScaledMetric(wrappedValue: .unit(.half))
        _contentHorizontalPadding = ScaledMetric(wrappedValue: .unit(.x3))
        _contentVerticalPadding = ScaledMetric(wrappedValue: .unit(.x2))
    }

    public var body: some View {
        content
            .readGeometry(
                \.frame.height,
                inCoordinateSpace: .named(coordinateSpaceName),
                onChange: { frameHeight = $0 }
            )
            .padding(padding)
            .coordinateSpace(name: coordinateSpaceName)
            .background(separators, alignment: .leading)
            .background(Color.Tangem.Tabs.backgroundSecondary, in: .capsule)
            .onPreferenceChange(SegmentPreferenceKey.self) { segmentsPreference = $0 }
            .disabled(!isEnabled)
            .animation(animation, value: selection)
    }
}

// MARK: - Subviews

private extension TangemSegmentedPicker {
    var content: some View {
        HStack(spacing: spacing) {
            ForEach(data, id: \.self) { item in
                HStack(spacing: spacing) {
                    segment(item)

                    if hasSeparator(item) {
                        stubSeparator
                            .modifier(SegmentPreferenceModifier(
                                coordinateSpace: .named(coordinateSpaceName),
                                separatorOpacity: separatorOpacity(item)
                            ))
                    }
                }
            }
        }
    }

    func segment(_ item: Item) -> some View {
        itemContent(item)
            .padding(.horizontal, segmentHorizontalPadding)
            .padding(.vertical, segmentVerticalPadding)
            .frame(maxWidth: segmentMaxWidth, alignment: .center)
            .background(
                ZStack {
                    if isItemSelected(item) {
                        Capsule()
                            .fill(Color.Tangem.Tabs.backgroundTertiary)
                            .shadow(
                                color: .Tangem.Border.Neutral.tertiary,
                                radius: shadowRadius,
                                x: 0,
                                y: shadowY
                            )
                            .frame(height: frameHeight)
                            .matchedGeometryEffect(id: geometricId, in: geometricNamespace)
                    }
                }
            )
            .contentShape(.rect)
            .onTapGesture { selection = item }
    }

    func itemContent(_ item: Item) -> some View {
        Text(item.text)
            .style(.Tangem.Body15.semibold, color: .Tangem.Tabs.textSecondary)
    }

    var separators: some View {
        ForEach(Array(segmentsPreference.enumerated()), id: \.offset) { index, preference in
            separator(
                offsetX: preference.frame.maxX,
                opacity: preference.separatorOpacity
            )
        }
    }

    func separator(offsetX: CGFloat, opacity: CGFloat) -> some View {
        Separator(
            height: .exact(separatorWidth),
            color: .Tangem.Border.Neutral.tertiary,
            axis: .vertical
        )
        .offset(x: offsetX)
        .padding(.vertical, separatorPadding)
        .opacity(opacity)
        .animation(animation, value: opacity)
    }

    var stubSeparator: some View {
        Color.clear
            .frame(width: separatorWidth, height: 0)
    }
}

// MARK: - Calculations

private extension TangemSegmentedPicker {
    func isItemSelected(_ item: Item) -> Bool {
        item == selection
    }

    func hasSeparator(_ item: Item) -> Bool {
        item != data.last
    }

    func separatorOpacity(_ item: Item) -> CGFloat {
        guard
            showSeparators,
            !isItemSelected(item),
            let index = data.firstIndex(of: item)
        else {
            return 0
        }

        let nextIndex = data.index(after: index)
        guard let nextItem = data[safe: nextIndex] else {
            return 0
        }

        return isItemSelected(nextItem) ? 0 : 1
    }
}

// MARK: - SegmentPreference

private struct SegmentPreference: Hashable {
    let frame: CGRect
    let separatorOpacity: CGFloat
}

private struct SegmentPreferenceKey: PreferenceKey {
    typealias Value = [SegmentPreference]

    static var defaultValue: Value = []

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue())
    }
}

private struct SegmentPreferenceModifier: ViewModifier {
    @State private var frame: CGRect = .zero

    let coordinateSpace: CoordinateSpace
    let separatorOpacity: CGFloat

    private var preference: SegmentPreference {
        SegmentPreference(frame: frame, separatorOpacity: separatorOpacity)
    }

    func body(content: Content) -> some View {
        content
            .readGeometry(
                \.frame,
                inCoordinateSpace: coordinateSpace,
                bindTo: $frame
            )
            .preference(key: SegmentPreferenceKey.self, value: [preference])
    }
}

// MARK: - Setupable

public extension TangemSegmentedPicker {
    func showSeparators(_ value: Bool) -> Self {
        map { $0.showSeparators = value }
    }

    func style(_ style: TangemSegmentedPickerStyle) -> Self {
        map { $0.style = style }
    }
}

// MARK: - TextProvider

public protocol TangemSegmentedPickerTextProvider: Hashable {
    var text: String { get }
}
