//
//  TopNavigationShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TopNavigationShowcase: View {
    @State private var usesSlot = false
    @State private var usesLongTitle = false
    @State private var contentPosition: TopNavigation.ContentPosition = .center
    @State private var showsSubtitle = true
    @State private var animatesSubtitleAppearance = true
    @State private var subtitleValueToggle = false
    @State private var showsBack = true
    @State private var actionsKind: ActionsKind = .two
    @State private var actionsHaveBackground = true
    @State private var showsClose = false
    @State private var showsSheet = false
    @State private var isPushed = false
    @State private var actionTaps = 0

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DSShowcase("TopNavigation", layout: .fill) { controls in
            controls.toggle("Slot instead of title", $usesSlot)
            controls.picker("Position", $contentPosition)

            if !usesSlot {
                controls.toggle("Long title", $usesLongTitle)
                controls.toggle("Subtitle", $showsSubtitle)
                controls.toggle("Animates subtitle appearance", $animatesSubtitleAppearance)
                controls.toggle("Alternate subtitle value", $subtitleValueToggle)
            }

            controls.toggle("Back", $showsBack)
            controls.picker("Actions", $actionsKind)
            controls.toggle("Actions have background", $actionsHaveBackground)
            controls.toggle("Close", $showsClose)
            controls.readout("Action taps", "\(actionTaps)")
            controls.action("Present as sheet") { showsSheet = true }
            controls.action("Push screens (watch push / pop)") { isPushed = true }
            controls.note("The bar is this page's own navigation bar. Back and Close leave the showcase; switch to Matrix to get the plain bar back.")
        } stage: {
            stageContent
                .modifier(barModifier(leading: showsBack ? .automatic : .none, onClose: showsClose ? { dismiss() } : nil))
                .sheet(isPresented: $showsSheet) {
                    sheet
                }
                .navigationDestination(isPresented: $isPushed) {
                    TopNavigationPushDemo(depth: 1, config: config)
                }
        } matrix: {
            DSShowcaseGroup("Title content") {
                DSShowcaseMatrix(rows: TitleSample.allCases) { sample in
                    TopNavigationTitleContent(title: sample.title, subtitle: sample.subtitle)
                        .frame(maxWidth: 240)
                }
            }

            DSShowcaseGroup("Actions") {
                DSShowcaseMatrix(
                    rows: ActionsKind.allCases.filter { $0 != .none },
                    columns: [true, false],
                    columnLabel: { $0 ? "background" : "bare" }
                ) { kind, hasBackground in
                    if let actions = config.actions(kind) {
                        TopNavigationActions(actions: actions, hasBackground: hasBackground)
                    }
                }
            }
        }
    }

    private var stageContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Self.transactions, id: \.self) { transaction in
                    Text(transaction)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
        }
    }

    private var sheet: some View {
        NavigationStack {
            stageContent
                .modifier(barModifier(
                    leading: showsBack ? .custom(.back { showsSheet = false }) : .none,
                    onClose: { showsSheet = false }
                ))
                .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        }
    }

    private func barModifier(leading: TopNavigation.LeadingPolicy, onClose: (() -> Void)?) -> TopNavigationShowcaseBar {
        TopNavigationShowcaseBar(
            usesSlot: usesSlot,
            title: usesLongTitle ? TitleSample.long.title : TitleSample.short.title,
            subtitle: showsSubtitle ? (subtitleValueToggle ? "$2,922.14 · +2.08%" : "0x71C7…976F") : nil,
            animatesSubtitleAppearance: animatesSubtitleAppearance,
            contentPosition: contentPosition,
            leading: leading,
            actions: config.actions(actionsKind),
            actionsHaveBackground: actionsHaveBackground,
            onClose: onClose
        )
    }

    private var config: Config {
        Config(
            contentPosition: contentPosition,
            showsSubtitle: showsSubtitle,
            animatesSubtitleAppearance: animatesSubtitleAppearance,
            actionsKind: actionsKind,
            actionsHaveBackground: actionsHaveBackground,
            showsClose: showsClose,
            onAction: { actionTaps += 1 }
        )
    }

    private static var transactions: [String] {
        (1 ... 30).map { index in
            index.isMultiple(of: 3)
                ? "Received \(index * 3) USDT from 0x9f2c…41aB"
                : "Sent 0.0\(index) ETH to vitalik.eth"
        }
    }
}

// MARK: - Bar

private struct TopNavigationShowcaseBar: ViewModifier {
    let usesSlot: Bool
    let title: String
    let subtitle: String?
    let animatesSubtitleAppearance: Bool
    let contentPosition: TopNavigation.ContentPosition
    let leading: TopNavigation.LeadingPolicy
    let actions: TopNavigation.Actions?
    let actionsHaveBackground: Bool
    let onClose: (() -> Void)?

    func body(content: Content) -> some View {
        if usesSlot {
            content
                .topNavigation(
                    contentPosition: contentPosition,
                    leading: leading,
                    actions: actions,
                    actionsHaveBackground: actionsHaveBackground,
                    onClose: onClose
                ) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(DesignSystem.Color.bgBrand)
                            .frame(width: 20, height: 20)

                        Text("Main wallet")
                            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    }
                }
        } else {
            content
                .topNavigation(
                    title: title,
                    subtitle: subtitle,
                    animatesSubtitleAppearance: animatesSubtitleAppearance,
                    contentPosition: contentPosition,
                    leading: leading,
                    actions: actions,
                    actionsHaveBackground: actionsHaveBackground,
                    onClose: onClose
                )
        }
    }
}

// MARK: - Shared config

private extension TopNavigationShowcase {
    enum ActionsKind: CaseIterable {
        case none
        case one
        case two
        case three
        case text
        case menu
    }

    enum TitleSample: CaseIterable {
        case short
        case withSubtitle
        case long

        var title: String {
            switch self {
            case .short, .withSubtitle: "Ethereum"
            case .long: "Family & friends shared savings wallet"
            }
        }

        var subtitle: String? {
            switch self {
            case .short: nil
            case .withSubtitle, .long: "0x71C7…976F"
            }
        }
    }

    struct Config {
        var contentPosition: TopNavigation.ContentPosition
        var showsSubtitle: Bool
        var animatesSubtitleAppearance: Bool
        var actionsKind: ActionsKind
        var actionsHaveBackground: Bool
        var showsClose: Bool
        var onAction: () -> Void

        func actions(_ kind: ActionsKind) -> TopNavigation.Actions? {
            let bell = TopNavigation.Action(icon: DesignSystem.Icons.Bell.regular24, accessibilityLabel: "Notifications", action: onAction)
            let search = TopNavigation.Action(icon: DesignSystem.Icons.Search.regular24, accessibilityLabel: "Search", action: onAction)
            let more = TopNavigation.Action(icon: DesignSystem.Icons.DotsVertical.regular24, accessibilityLabel: "More", action: onAction)

            switch kind {
            case .none:
                return nil
            case .one:
                return .one(bell)
            case .two:
                return .two(bell, search)
            case .three:
                return .three(bell, search, more)
            case .text:
                return .one(TopNavigation.Action(title: "How it works?", action: onAction))
            case .menu:
                return .two(
                    bell,
                    TopNavigation.Action(
                        icon: DesignSystem.Icons.DotsVertical.regular24,
                        accessibilityLabel: "More",
                        menu: [
                            TopNavigation.MenuItem(title: "Copy address", action: onAction),
                            TopNavigation.MenuItem(title: "Rename wallet", action: onAction),
                            TopNavigation.MenuItem(title: "Hide token", role: .destructive, action: onAction),
                        ]
                    )
                )
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
        .topNavigation(
            title: "Screen \(depth)",
            subtitle: config.showsSubtitle ? "Depth \(depth)" : nil,
            animatesSubtitleAppearance: config.animatesSubtitleAppearance,
            contentPosition: config.contentPosition,
            leading: .automatic,
            actions: config.actions(config.actionsKind),
            actionsHaveBackground: config.actionsHaveBackground,
            onClose: config.showsClose ? { dismiss() } : nil
        )
    }
}
#endif
