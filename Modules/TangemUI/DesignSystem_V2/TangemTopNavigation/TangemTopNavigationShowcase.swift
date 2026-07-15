//
//  TangemTopNavigationShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct TangemTopNavigationShowcase: View {
    @State private var usesSlot = false
    @State private var usesLongTitle = false
    @State private var contentPosition: TangemTopNavigation.ContentPosition = .center
    @State private var showsSubtitle = true
    @State private var animatesSubtitleAppearance = true
    @State private var subtitleValueToggle = false
    @State private var showsBack = true
    @State private var actionCount = 2
    @State private var usesTextAction = false
    @State private var showsClose = false
    @State private var showsSheet = false
    @State private var dynamicTypeSize: DynamicTypeSize = .large
    @State private var isDarkMode = false
    @State private var background: ShowcaseBackground = .primary

    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        screen
            .dynamicTypeSize(dynamicTypeSize)
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .sheet(isPresented: $showsSheet) {
                sheet
                    .dynamicTypeSize(dynamicTypeSize)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            }
    }

    @ViewBuilder
    private var screen: some View {
        if usesSlot {
            controls
                .tangemTopNavigation(
                    contentPosition: contentPosition,
                    leading: leadingButton,
                    actions: actions,
                    onClose: closeAction
                ) {
                    slotContent
                }
        } else {
            controls
                .tangemTopNavigation(
                    title: titleValue,
                    subtitle: showsSubtitle ? subtitleValue : nil,
                    animatesSubtitleAppearance: animatesSubtitleAppearance,
                    contentPosition: contentPosition,
                    leading: leadingButton,
                    actions: actions,
                    onClose: closeAction
                )
        }
    }

    private var controls: some View {
        List {
            Section("Content") {
                Toggle("Slot instead of title", isOn: $usesSlot)

                Toggle("Long title", isOn: $usesLongTitle)
                    .disabled(usesSlot)

                Picker("Position", selection: $contentPosition) {
                    Text("Start").tag(TangemTopNavigation.ContentPosition.start)
                    Text("Center").tag(TangemTopNavigation.ContentPosition.center)
                }
                .pickerStyle(.segmented)
            }

            Section("Subtitle") {
                Toggle("Subtitle", isOn: $showsSubtitle)
                Toggle("Animates appearance", isOn: $animatesSubtitleAppearance)
                Toggle("Alternate value", isOn: $subtitleValueToggle)
            }
            .disabled(usesSlot)

            Section("Buttons") {
                Toggle("Back", isOn: $showsBack)

                Stepper("Actions: \(actionCount)", value: $actionCount, in: 0 ... 3)
                    .disabled(usesTextAction)

                Toggle("Text action", isOn: $usesTextAction)

                Toggle("Close", isOn: $showsClose)
            }

            Section("Sheet mode") {
                Button("Present as sheet") { showsSheet = true }
            }

            Section("Display") {
                Stepper(
                    "Dynamic Type: \(String(describing: dynamicTypeSize))",
                    onIncrement: { stepDynamicType(by: 1) },
                    onDecrement: { stepDynamicType(by: -1) }
                )

                Toggle("Dark mode", isOn: $isDarkMode)

                Picker("Background", selection: $background) {
                    ForEach(ShowcaseBackground.allCases, id: \.self) { background in
                        Text(background.title).tag(background)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Navigation") {
                NavigationLink("Push screens (watch push / pop)") {
                    TangemTopNavigationPushDemo(depth: 1, config: config)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(background.color.ignoresSafeArea())
    }

    @ViewBuilder
    private var sheet: some View {
        let dismissSheet = { showsSheet = false }
        let sheetLeading: TangemTopNavigation.Action? = showsBack ? .back(action: dismissSheet) : nil

        NavigationStack {
            Group {
                if usesSlot {
                    sheetScroll
                        .tangemTopNavigation(
                            contentPosition: contentPosition,
                            leading: sheetLeading,
                            actions: actions,
                            onClose: dismissSheet
                        ) {
                            slotContent
                        }
                } else {
                    sheetScroll
                        .tangemTopNavigation(
                            title: titleValue,
                            subtitle: showsSubtitle ? subtitleValue : nil,
                            animatesSubtitleAppearance: animatesSubtitleAppearance,
                            contentPosition: contentPosition,
                            leading: sheetLeading,
                            actions: actions,
                            onClose: dismissSheet
                        )
                }
            }
            .background(background.color.ignoresSafeArea())
        }
    }

    private var sheetScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0 ..< 30, id: \.self) { index in
                    Text("Scrollable content line \(index + 1)")
                        .font(token: DesignSystem.Font.bodyMediumToken)
                        .foregroundStyle(DesignSystem.Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                }
            }
        }
    }

    private func stepDynamicType(by delta: Int) {
        let sizes = DynamicTypeSize.allCases

        guard let current = sizes.firstIndex(of: dynamicTypeSize) else { return }

        let next = min(max(current + delta, 0), sizes.count - 1)
        dynamicTypeSize = sizes[next]
    }

    private var slotContent: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(DesignSystem.Color.bgBrand)
                .frame(width: 20, height: 20)

            Text("Custom slot")
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)
        }
    }

    private var titleValue: String {
        usesLongTitle ? "A Very Long Navigation Title That Does Not Fit" : "Title"
    }

    private var subtitleValue: String {
        subtitleValueToggle ? "Alternate subtitle" : "Subtitle"
    }

    private var leadingButton: TangemTopNavigation.Action? {
        showsBack ? .back { dismiss() } : nil
    }

    private var closeAction: (() -> Void)? {
        showsClose ? { dismiss() } : nil
    }

    private var actions: [TangemTopNavigation.Action] {
        config.actions
    }

    private var config: Config {
        Config(
            contentPosition: contentPosition,
            showsSubtitle: showsSubtitle,
            animatesSubtitleAppearance: animatesSubtitleAppearance,
            actionCount: actionCount,
            usesTextAction: usesTextAction,
            showsClose: showsClose,
            dynamicTypeSize: dynamicTypeSize
        )
    }
}

// MARK: - Shared config

extension TangemTopNavigationShowcase {
    struct Config {
        var contentPosition: TangemTopNavigation.ContentPosition
        var showsSubtitle: Bool
        var animatesSubtitleAppearance: Bool
        var actionCount: Int
        var usesTextAction: Bool
        var showsClose: Bool
        var dynamicTypeSize: DynamicTypeSize

        var actions: [TangemTopNavigation.Action] {
            if usesTextAction {
                return [TangemTopNavigation.Action(title: "How it works?") {}]
            }

            let icons: [(icon: ImageType, label: String)] = [
                (DesignSystem.Icons.Bell.regular20, "Notifications"),
                (DesignSystem.Icons.Search.regular20, "Search"),
                (DesignSystem.Icons.DotsVertical.regular20, "More"),
            ]

            return icons.prefix(actionCount).map { icon, label in
                TangemTopNavigation.Action(icon: icon, accessibilityLabel: label) {}
            }
        }
    }
}

// MARK: - Push demo

private struct TangemTopNavigationPushDemo: View {
    let depth: Int
    let config: TangemTopNavigationShowcase.Config

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            NavigationLink("Push screen \(depth + 1)") {
                TangemTopNavigationPushDemo(depth: depth + 1, config: config)
            }

            Button("Pop", role: .destructive) { dismiss() }
        }
        .dynamicTypeSize(config.dynamicTypeSize)
        .tangemTopNavigation(
            title: "Screen \(depth)",
            subtitle: config.showsSubtitle ? "Depth \(depth)" : nil,
            animatesSubtitleAppearance: config.animatesSubtitleAppearance,
            contentPosition: config.contentPosition,
            leading: .back { dismiss() },
            actions: config.actions,
            onClose: config.showsClose ? { dismiss() } : nil
        )
    }
}

// MARK: - Background

extension TangemTopNavigationShowcase {
    enum ShowcaseBackground: CaseIterable {
        case primary
        case secondary
        case inverse

        var title: String {
            switch self {
            case .primary: "Primary"
            case .secondary: "Secondary"
            case .inverse: "Inverse"
            }
        }

        var color: Color {
            switch self {
            case .primary: DesignSystem.Color.bgPrimary
            case .secondary: DesignSystem.Color.bgSecondary
            case .inverse: DesignSystem.Color.bgInverse
            }
        }
    }
}

// MARK: - Previews

private struct TangemTopNavigationGallery: View {
    private let actions: [TangemTopNavigation.Action] = [
        TangemTopNavigation.Action(icon: DesignSystem.Icons.Bell.regular20, accessibilityLabel: "Notifications") {},
        TangemTopNavigation.Action(icon: DesignSystem.Icons.Search.regular20, accessibilityLabel: "Search") {},
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(0 ..< 20, id: \.self) { index in
                    Text("Row \(index + 1)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
            .tangemTopNavigation(
                title: "Title",
                subtitle: "Subtitle",
                leading: .back {},
                actions: actions,
                onClose: {}
            )
        }
    }
}

#Preview("Light") {
    TangemTopNavigationGallery()
}

#Preview("Dark") {
    TangemTopNavigationGallery()
        .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XXL") {
    TangemTopNavigationGallery()
        .dynamicTypeSize(.accessibility3)
}
