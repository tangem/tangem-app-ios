//
//  TangemRow+Modifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

// MARK: - Public types

public enum TangemRowContentLead: Sendable, Hashable, CaseIterable {
    case equal
    case start
    case end
}

public enum TangemRowVerticalAlignment: Sendable, Hashable, CaseIterable {
    case top
    case center

    var stackAlignment: VerticalAlignment {
        switch self {
        case .top: .top
        case .center: .center
        }
    }
}

public enum TangemRowLineOrder: Sendable, Hashable, CaseIterable {
    case primaryFirst
    case secondaryFirst
}

public struct TangemRowOverrideTextColors {
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

struct TangemRowConfiguration {
    var contentLead: TangemRowContentLead = .equal
    var verticalAlignment: TangemRowVerticalAlignment = .top
    var lineOrder: TangemRowLineOrder = .primaryFirst
    var titleLineLimit: Int = 1
    var subtitleLineLimit: Int = 1
    var valueLineLimit: Int = 1
    var subvalueLineLimit: Int = 1
    var showsDivider: Bool = false
    var includesInnerPadding: Bool = true
    var focusRingEnabled: Bool = false
    var overrideTextColors: TangemRowOverrideTextColors = .init()
    var onTap: (() -> Void)?
    var accessibilityLabel: String?
    var accessibilityHint: String?
}

public extension TangemRow {
    typealias ContentLead = TangemRowContentLead
    typealias VerticalAlignment = TangemRowVerticalAlignment
    typealias LineOrder = TangemRowLineOrder
}

// MARK: - Entry point

public extension TangemRow where
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

public extension TangemRow {
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

    func overrideTextColors(_ colors: TangemRowOverrideTextColors) -> Self {
        map { $0.config.overrideTextColors = colors }
    }
}

// MARK: - Slot transforms (type-changing, no AnyView)

public extension TangemRow {
    func titleAccessory<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> TangemRow<V, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, End, ExtraBottom> {
        TangemRow<V, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, End, ExtraBottom>(
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
    ) -> TangemRow<TitleAccessory, V, ValueAccessory, SubvalueAccessory, Start, End, ExtraBottom> {
        TangemRow<TitleAccessory, V, ValueAccessory, SubvalueAccessory, Start, End, ExtraBottom>(
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
    ) -> TangemRow<TitleAccessory, SubtitleAccessory, V, SubvalueAccessory, Start, End, ExtraBottom> {
        TangemRow<TitleAccessory, SubtitleAccessory, V, SubvalueAccessory, Start, End, ExtraBottom>(
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
    ) -> TangemRow<TitleAccessory, SubtitleAccessory, ValueAccessory, V, Start, End, ExtraBottom> {
        TangemRow<TitleAccessory, SubtitleAccessory, ValueAccessory, V, Start, End, ExtraBottom>(
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
    ) -> TangemRow<TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, V, End, ExtraBottom> {
        TangemRow<TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, V, End, ExtraBottom>(
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
    ) -> TangemRow<TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, V, ExtraBottom> {
        TangemRow<TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, V, ExtraBottom>(
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
    ) -> TangemRow<TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, End, V> {
        TangemRow<TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, End, V>(
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

public extension TangemRow {
    func start(icon: ImageType?) -> TangemRow<
        TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, some View, End, ExtraBottom
    > {
        start {
            if let icon {
                TangemRowSlotIcon(icon: icon)
            }
        }
    }

    func end(icon: ImageType?) -> TangemRow<
        TitleAccessory, SubtitleAccessory, ValueAccessory, SubvalueAccessory, Start, some View, ExtraBottom
    > {
        end {
            if let icon {
                TangemRowSlotIcon(icon: icon)
            }
        }
    }
}

// MARK: - Slot icon

private struct TangemRowSlotIcon: View {
    let icon: ImageType

    @ScaledMetric private var iconSize = TangemRowMetrics.iconSize

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
