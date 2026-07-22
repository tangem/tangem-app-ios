//
//  Row+Modifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

// MARK: - Public types

public enum RowContentLead: Sendable, Hashable, CaseIterable {
    case equal
    case start
    case end
}

public enum RowVerticalAlignment: Sendable, Hashable, CaseIterable {
    case top
    case center

    var stackAlignment: VerticalAlignment {
        switch self {
        case .top: .top
        case .center: .center
        }
    }
}

public enum RowLineOrder: Sendable, Hashable, CaseIterable {
    case primaryFirst
    case secondaryFirst
}

public struct RowOverrideTextColors {
    public var title: Color?
    public var subtitle: Color?
    public var value: Color?
    public var subvalue: Color?

    public init(title: Color? = nil, subtitle: Color? = nil, value: Color? = nil, subvalue: Color? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.subvalue = subvalue
    }
}

public struct RowTruncationModes {
    public var title: Text.TruncationMode
    public var subtitle: Text.TruncationMode
    public var value: Text.TruncationMode
    public var subvalue: Text.TruncationMode

    public init(
        title: Text.TruncationMode = .tail,
        subtitle: Text.TruncationMode = .tail,
        value: Text.TruncationMode = .tail,
        subvalue: Text.TruncationMode = .tail
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.subvalue = subvalue
    }
}

struct RowConfiguration {
    var contentLead: RowContentLead = .equal
    var verticalAlignment: RowVerticalAlignment = .center
    var lineOrder: RowLineOrder = .primaryFirst
    var titleLineLimit: Int = 1
    var subtitleLineLimit: Int = 1
    var valueLineLimit: Int = 1
    var subvalueLineLimit: Int = 1
    var showsDivider: Bool = false
    var includesInnerPadding: Bool = true
    var focusRingEnabled: Bool = false
    var overrideTextColors: RowOverrideTextColors = .init()
    var truncationModes: RowTruncationModes = .init()
    var onTap: (() -> Void)?
    var accessibilityLabel: String?
    var accessibilityHint: String?
}

public extension Row {
    typealias ContentLead = RowContentLead
    typealias VerticalAlignment = RowVerticalAlignment
    typealias LineOrder = RowLineOrder
}

// MARK: - Entry point

public extension Row where
    TitleAccessory == EmptyView,
    SubtitleAccessory == EmptyView,
    ValueAccessory == EmptyView,
    SubvalueAccessory == EmptyView,
    Start == EmptyView,
    End == EmptyView,
    ExtraBottom == EmptyView {
    init(
        title: String? = nil,
        subtitle: String? = nil,
        value: String? = nil,
        subvalue: String? = nil
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            value: value,
            subvalue: subvalue,
            titleAccessory: EmptyView(),
            subtitleAccessory: EmptyView(),
            valueAccessory: EmptyView(),
            subvalueAccessory: EmptyView(),
            start: EmptyView(),
            end: EmptyView(),
            extraBottom: EmptyView()
        )
    }
}

// MARK: - Config modifiers (Setupable, same-type)

public extension Row {
    func contentLead(_ contentLead: ContentLead) -> Self {
        map { $0.config.contentLead = contentLead }
    }

    func verticalAlignment(_ verticalAlignment: VerticalAlignment) -> Self {
        map { $0.config.verticalAlignment = verticalAlignment }
    }

    func lineOrder(_ lineOrder: LineOrder) -> Self {
        map { $0.config.lineOrder = lineOrder }
    }

    func titleLineLimit(_ limit: Int) -> Self {
        map { $0.config.titleLineLimit = limit }
    }

    func subtitleLineLimit(_ limit: Int) -> Self {
        map { $0.config.subtitleLineLimit = limit }
    }

    func valueLineLimit(_ limit: Int) -> Self {
        map { $0.config.valueLineLimit = limit }
    }

    func subvalueLineLimit(_ limit: Int) -> Self {
        map { $0.config.subvalueLineLimit = limit }
    }

    func showDivider(_ show: Bool = true) -> Self {
        map { $0.config.showsDivider = show }
    }

    func includeInnerPadding(_ include: Bool) -> Self {
        map { $0.config.includesInnerPadding = include }
    }

    func focusRing(_ on: Bool) -> Self {
        map { $0.config.focusRingEnabled = on }
    }

    func onTap(_ action: @escaping () -> Void) -> Self {
        map { $0.config.onTap = action }
    }

    func accessibilityLabel(_ label: String?) -> Self {
        map { $0.config.accessibilityLabel = label }
    }

    func accessibilityHint(_ hint: String?) -> Self {
        map { $0.config.accessibilityHint = hint }
    }

    func overrideTextColors(_ colors: RowOverrideTextColors) -> Self {
        map { $0.config.overrideTextColors = colors }
    }

    func truncationModes(_ modes: RowTruncationModes) -> Self {
        map { $0.config.truncationModes = modes }
    }
}

// MARK: - Slot transforms (type-changing, no AnyView)

public extension Row {
    func titleAccessory<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> Row<V, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, End, ExtraBottom> {
        Row<V, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, End, ExtraBottom>(
            title: title,
            subtitle: subtitle,
            value: value,
            subvalue: subvalue,
            titleAccessory: content(),
            subtitleAccessory: subtitleAccessoryContent,
            valueAccessory: valueAccessoryContent,
            subvalueAccessory: subvalueAccessoryContent,
            start: startContent,
            end: endContent,
            extraBottom: extraBottomContent,
            config: config
        )
    }

    func subtitleAccessory<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> Row<TitleAccessory, V, ValueAccessory, SubvalueAccessory, Start, End, ExtraBottom> {
        Row<TitleAccessory, V, ValueAccessory, SubvalueAccessory, Start, End, ExtraBottom>(
            title: title,
            subtitle: subtitle,
            value: value,
            subvalue: subvalue,
            titleAccessory: titleAccessoryContent,
            subtitleAccessory: content(),
            valueAccessory: valueAccessoryContent,
            subvalueAccessory: subvalueAccessoryContent,
            start: startContent,
            end: endContent,
            extraBottom: extraBottomContent,
            config: config
        )
    }

    func valueAccessory<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> Row<TitleAccessory, SubtitleAccessory, V, SubvalueAccessory, Start, End, ExtraBottom> {
        Row<TitleAccessory, SubtitleAccessory, V, SubvalueAccessory, Start, End, ExtraBottom>(
            title: title,
            subtitle: subtitle,
            value: value,
            subvalue: subvalue,
            titleAccessory: titleAccessoryContent,
            subtitleAccessory: subtitleAccessoryContent,
            valueAccessory: content(),
            subvalueAccessory: subvalueAccessoryContent,
            start: startContent,
            end: endContent,
            extraBottom: extraBottomContent,
            config: config
        )
    }

    func subvalueAccessory<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> Row<TitleAccessory, SubtitleAccessory, ValueAccessory, V, Start, End, ExtraBottom> {
        Row<TitleAccessory, SubtitleAccessory, ValueAccessory, V, Start, End, ExtraBottom>(
            title: title,
            subtitle: subtitle,
            value: value,
            subvalue: subvalue,
            titleAccessory: titleAccessoryContent,
            subtitleAccessory: subtitleAccessoryContent,
            valueAccessory: valueAccessoryContent,
            subvalueAccessory: content(),
            start: startContent,
            end: endContent,
            extraBottom: extraBottomContent,
            config: config
        )
    }

    func start<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> Row<TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, V, End, ExtraBottom> {
        Row<TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, V, End, ExtraBottom>(
            title: title,
            subtitle: subtitle,
            value: value,
            subvalue: subvalue,
            titleAccessory: titleAccessoryContent,
            subtitleAccessory: subtitleAccessoryContent,
            valueAccessory: valueAccessoryContent,
            subvalueAccessory: subvalueAccessoryContent,
            start: content(),
            end: endContent,
            extraBottom: extraBottomContent,
            config: config
        )
    }

    func end<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> Row<TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, V, ExtraBottom> {
        Row<TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, V, ExtraBottom>(
            title: title,
            subtitle: subtitle,
            value: value,
            subvalue: subvalue,
            titleAccessory: titleAccessoryContent,
            subtitleAccessory: subtitleAccessoryContent,
            valueAccessory: valueAccessoryContent,
            subvalueAccessory: subvalueAccessoryContent,
            start: startContent,
            end: content(),
            extraBottom: extraBottomContent,
            config: config
        )
    }

    func extraBottom<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> Row<TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, End, V> {
        Row<TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, End, V>(
            title: title,
            subtitle: subtitle,
            value: value,
            subvalue: subvalue,
            titleAccessory: titleAccessoryContent,
            subtitleAccessory: subtitleAccessoryContent,
            valueAccessory: valueAccessoryContent,
            subvalueAccessory: subvalueAccessoryContent,
            start: startContent,
            end: endContent,
            extraBottom: content(),
            config: config
        )
    }
}

// MARK: - Icon slot convenience

public extension Row {
    func start(icon: ImageType?) -> Row<
        TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, some View, End, ExtraBottom
    > {
        start {
            if let icon {
                RowSlotIcon(icon: icon)
            }
        }
    }

    func end(icon: ImageType?) -> Row<
        TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, some View, ExtraBottom
    > {
        end {
            if let icon {
                RowSlotIcon(icon: icon)
            }
        }
    }
}

// MARK: - Slot icon

private struct RowSlotIcon: View {
    let icon: ImageType

    @ScaledMetric private var iconSize = RowMetrics.iconSize

    var body: some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .accessibilityHidden(true)
    }
}
