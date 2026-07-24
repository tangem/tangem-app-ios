//
//  TopNavigationShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct TopNavigationShowcase: View {
    @State private var usesSlot = false
    @State private var usesLongTitle = false
    @State private var contentPosition: TopNavigation.ContentPosition = .center
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
                .topNavigation(
                    contentPosition: contentPosition,
                    leading: leadingPolicy,
                    actions: actions,
                    onClose: closeAction
                ) {
                    slotContent
                }
        } else {
            controls
                .topNavigation(
                    title: titleValue,
                    subtitle: showsSubtitle ? subtitleValue : nil,
                    animatesSubtitleAppearance: animatesSubtitleAppearance,
                    contentPosition: contentPosition,
                    leading: leadingPolicy,
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
                    Text("Start").tag(TopNavigation.ContentPosition.start)
                    Text("Center").tag(TopNavigation.ContentPosition.center)
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
                SwiftUI.Button("Present as sheet") { showsSheet = true }
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
                    TopNavigationPushDemo(depth: 1, config: config)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(background.color.ignoresSafeArea())
    }

    @ViewBuilder
    private var sheet: some View {
        let dismissSheet = { showsSheet = false }
        let sheetLeading: TopNavigation.LeadingPolicy = showsBack ? .custom(.back(action: dismissSheet)) : .none

        NavigationStack {
            Group {
                if usesSlot {
                    sheetScroll
                        .topNavigation(
                            contentPosition: contentPosition,
                            leading: sheetLeading,
                            actions: actions,
                            onClose: dismissSheet
                        ) {
                            slotContent
                        }
                } else {
                    sheetScroll
                        .topNavigation(
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

    private var leadingPolicy: TopNavigation.LeadingPolicy {
        showsBack ? .automatic : .none
    }

    private var closeAction: (() -> Void)? {
        showsClose ? { dismiss() } : nil
    }

    private var actions: TopNavigation.Actions? {
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

extension TopNavigationShowcase {
    struct Config {
        var contentPosition: TopNavigation.ContentPosition
        var showsSubtitle: Bool
        var animatesSubtitleAppearance: Bool
        var actionCount: Int
        var usesTextAction: Bool
        var showsClose: Bool
        var dynamicTypeSize: DynamicTypeSize

        var actions: TopNavigation.Actions? {
            if usesTextAction {
                return .one(TopNavigation.Action(title: "How it works?") {})
            }

            let icons: [(icon: ImageType, label: String)] = [
                (DesignSystem.Icons.Bell.regular20, "Notifications"),
                (DesignSystem.Icons.Search.regular20, "Search"),
                (DesignSystem.Icons.DotsVertical.regular20, "More"),
            ]

            let selected = icons.prefix(actionCount).map { icon, label in
                TopNavigation.Action(icon: icon, accessibilityLabel: label) {}
            }

            switch selected.count {
            case 1: return .one(selected[0])
            case 2: return .two(selected[0], selected[1])
            case 3: return .three(selected[0], selected[1], selected[2])
            default: return nil
            }
        }
    }
}

// MARK: - Push demo

private struct TopNavigationPushDemo: View {
    let depth: Int
    let config: TopNavigationShowcase.Config

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            NavigationLink("Push screen \(depth + 1)") {
                TopNavigationPushDemo(depth: depth + 1, config: config)
            }

            SwiftUI.Button("Pop", role: .destructive) { dismiss() }
        }
        .dynamicTypeSize(config.dynamicTypeSize)
        .topNavigation(
            title: "Screen \(depth)",
            subtitle: config.showsSubtitle ? "Depth \(depth)" : nil,
            animatesSubtitleAppearance: config.animatesSubtitleAppearance,
            contentPosition: config.contentPosition,
            leading: .automatic,
            actions: config.actions,
            onClose: config.showsClose ? { dismiss() } : nil
        )
    }
}

// MARK: - Background

extension TopNavigationShowcase {
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

private struct TopNavigationGallery: View {
    private let actions: TopNavigation.Actions = .two(
        TopNavigation.Action(icon: DesignSystem.Icons.Bell.regular20, accessibilityLabel: "Notifications") {},
        TopNavigation.Action(icon: DesignSystem.Icons.Search.regular20, accessibilityLabel: "Search") {}
    )

    var body: some View {
        NavigationStack {
            List {
                ForEach(0 ..< 20, id: \.self) { index in
                    Text("Row \(index + 1)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
            .topNavigation(
                title: "Title",
                subtitle: "Subtitle",
                leading: .automatic,
                actions: actions,
                onClose: {}
            )
        }
    }
}

#Preview("Light") {
    TopNavigationGallery()
}

#Preview("Dark") {
    TopNavigationGallery()
        .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XXL") {
    TopNavigationGallery()
        .dynamicTypeSize(.accessibility3)
}
