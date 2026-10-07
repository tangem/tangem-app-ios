//
//  DSShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUIUtils

struct DSShowcase<Controls: View, Stage: View, Matrix: View>: View {
    private let title: String
    private let layout: DSShowcaseLayout
    private let controls: Controls
    private let stage: Stage
    private let matrix: Matrix
    private let hasControls: Bool
    private let hasMatrix: Bool

    @State private var mode: Mode = .live
    @State private var isControlsExpanded = false
    @State private var environment: DSShowcaseEnvironment

    @Environment(\.dsShowcaseVersion) private var version

    init(
        _ title: String,
        layout: DSShowcaseLayout = .scroll,
        background: DSShowcaseStageBackground = .primary,
        @ViewBuilder controls: (DSShowcaseControls) -> Controls,
        @ViewBuilder stage: () -> Stage,
        @ViewBuilder matrix: () -> Matrix
    ) {
        self.init(
            title: title,
            layout: layout,
            background: background,
            controls: controls(DSShowcaseControls()),
            stage: stage(),
            matrix: matrix(),
            hasControls: true,
            hasMatrix: true
        )
    }

    private init(
        title: String,
        layout: DSShowcaseLayout,
        background: DSShowcaseStageBackground,
        controls: Controls,
        stage: Stage,
        matrix: Matrix,
        hasControls: Bool,
        hasMatrix: Bool
    ) {
        self.title = title
        self.layout = layout
        self.controls = controls
        self.stage = stage
        self.matrix = matrix
        self.hasControls = hasControls
        self.hasMatrix = hasMatrix
        _environment = State(initialValue: DSShowcaseEnvironment(background: background))
    }

    var body: some View {
        content
            .background(DesignSystem.Color.bgSecondary.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let version {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text(verbatim: "v\(version)")
                            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                            .monospacedDigit()
                    }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch (layout, mode) {
        case (.scroll, .live):
            ScrollView {
                VStack(spacing: 16) {
                    header
                    stageBox
                    controlsPanel
                }
                .padding(16)
            }
        case (.fill, .live):
            VStack(spacing: 0) {
                header
                    .padding(16)

                stage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(environment.background.view)
                    .showcaseEnvironment(environment)

                if hasControls {
                    collapsibleControlsPanel
                        .padding(16)
                }
            }
        case (_, .matrix):
            ScrollView {
                VStack(spacing: 16) {
                    header
                    matrixBox
                }
                .padding(16)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            if hasMatrix {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { mode in
                        Text(DSShowcaseLabel.text(mode)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            DSShowcaseEnvironmentPanel(environment: $environment)
        }
    }

    private var stageBox: some View {
        stage
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(16)
            .background(environment.background.view)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .showcaseEnvironment(environment)
    }

    private var matrixBox: some View {
        VStack(alignment: .leading, spacing: 24) {
            matrix
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(environment.background.view)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .showcaseEnvironment(environment)
    }

    @ViewBuilder
    private var controlsPanel: some View {
        if hasControls {
            controlsStack
                .showcasePanel()
        }
    }

    private var collapsibleControlsPanel: some View {
        DisclosureGroup(isExpanded: $isControlsExpanded) {
            ScrollView {
                controlsStack
                    .padding(.top, 12)
            }
            .frame(maxHeight: 240)
        } label: {
            DSShowcaseRowTitle("Controls")
        }
        .showcasePanel()
    }

    private var controlsStack: some View {
        VStack(alignment: .leading, spacing: 12) {
            controls
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension DSShowcase where Matrix == EmptyView {
    init(
        _ title: String,
        layout: DSShowcaseLayout = .scroll,
        background: DSShowcaseStageBackground = .primary,
        @ViewBuilder controls: (DSShowcaseControls) -> Controls,
        @ViewBuilder stage: () -> Stage
    ) {
        self.init(
            title: title,
            layout: layout,
            background: background,
            controls: controls(DSShowcaseControls()),
            stage: stage(),
            matrix: EmptyView(),
            hasControls: true,
            hasMatrix: false
        )
    }
}

extension DSShowcase where Controls == EmptyView {
    init(
        _ title: String,
        layout: DSShowcaseLayout = .scroll,
        background: DSShowcaseStageBackground = .primary,
        @ViewBuilder stage: () -> Stage,
        @ViewBuilder matrix: () -> Matrix
    ) {
        self.init(
            title: title,
            layout: layout,
            background: background,
            controls: EmptyView(),
            stage: stage(),
            matrix: matrix(),
            hasControls: false,
            hasMatrix: true
        )
    }
}

extension DSShowcase where Controls == EmptyView, Matrix == EmptyView {
    init(
        _ title: String,
        layout: DSShowcaseLayout = .scroll,
        background: DSShowcaseStageBackground = .primary,
        @ViewBuilder stage: () -> Stage
    ) {
        self.init(
            title: title,
            layout: layout,
            background: background,
            controls: EmptyView(),
            stage: stage(),
            matrix: EmptyView(),
            hasControls: false,
            hasMatrix: false
        )
    }
}

enum DSShowcaseLayout {
    case scroll
    case fill
}

private extension DSShowcase {
    enum Mode: CaseIterable {
        case live
        case matrix
    }
}

private struct DSShowcaseEnvironmentPanel: View {
    @Binding var environment: DSShowcaseEnvironment

    @State private var isExpanded = false

    private let controls = DSShowcaseControls()

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                controls.toggle("Right-to-left", $environment.isRTL)
                controls.picker("Appearance", $environment.appearance)
                controls.picker("Dynamic Type", $environment.dynamicTypeSize, options: [nil] + DynamicTypeSize.allCases) { size in
                    size.map { DSShowcaseLabel.text($0) } ?? "system"
                }
                controls.picker("Reduce Motion", $environment.reduceMotion, options: [nil, false, true]) { isOn in
                    isOn.map { $0 ? "on" : "off" } ?? "system"
                }
                controls.picker("Background", $environment.background)
            }
            .padding(.top, 12)
        } label: {
            DSShowcaseRow("Environment") {
                Text(environment.summary)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                    .lineLimit(1)
            }
        }
        .showcasePanel()
    }
}

private extension View {
    func showcasePanel() -> some View {
        padding(16)
            .background(DesignSystem.Color.bgPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
#endif
