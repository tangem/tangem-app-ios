//
//  ButtonShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct ButtonShowcase: View {
    @State private var styleKind: StyleKind = .brand
    @State private var material: TangemUI.Button.Material = .glass
    @State private var appearance: TangemUI.Button.Appearance = .default
    @State private var size: TangemUI.Button.Size = .x12
    @State private var horizontalLayout: TangemUI.Button.HorizontalLayout = .intrinsic
    @State private var confirmation: Confirmation = .tap
    @State private var contentKind: ContentKind = .label
    @State private var label = "Send"
    @State private var iconStartEnabled = false
    @State private var iconEndEnabled = false
    @State private var isEnabled = true
    @State private var loadingKind: LoadingKind = .none
    @State private var loadingMessage = "Signing transaction"
    @State private var simulatedLoadDuration: Double = 2
    @State private var simulatedLoadTask: Task<Void, Never>?
    @State private var loadingHoldStyles: Set<TangemUI.Button.HoldStyle> = []
    @State private var tapCount = 0

    var body: some View {
        DSShowcase("Button") { controls in
            controls.picker("Style", $styleKind)

            switch styleKind {
            case .secondary:
                controls.picker("Appearance", $appearance)
            case .material:
                controls.picker("Material", $material)
                controls.note("Switch the stage background to gradient to tell glass from blur.")
            case .brand, .primary:
                controls.picker("Confirm", $confirmation)
            case .outline, .ghost, .success:
                EmptyView()
            }

            if holdStyle != nil {
                controls.note("Hold until the fill completes: the button turns into a spinner and the demo plays the caller's load for the simulated duration. Hold shows the spinner without a message.")
            }

            controls.picker("Size", $size)
            controls.picker("Layout", $horizontalLayout)
            controls.picker("Content", $contentKind)

            if contentKind == .label {
                controls.text("Label", $label)
            }

            if contentKind != .iconOnly {
                controls.toggle("Icon start", $iconStartEnabled)
                controls.toggle("Icon end", $iconEndEnabled)
            }

            controls.toggle("Enabled", $isEnabled)
            controls.picker("Loading", $loadingKind)

            if loadingKind == .message {
                controls.text("Loading message", $loadingMessage)
            }

            controls.value("Simulated load, s", $simulatedLoadDuration, in: 0.5 ... 5, step: 0.5)
            controls.action("Simulate load") { startSimulatedLoad() }
            controls.readout("Taps", "\(tapCount)")
        } stage: {
            liveButton
                .id(size)
        } matrix: {
            DSShowcaseGroup("Style") {
                DSShowcaseMatrix(rows: StyleKind.allCases, columns: MatrixState.allCases) { style, state in
                    sampleButton(style: style.styleType(appearance: .default, material: .glass))
                        .disabled(state == .disabled)
                }
            }

            DSShowcaseGroup("Secondary appearance") {
                DSShowcaseMatrix(rows: TangemUI.Button.Appearance.allCases, columns: MatrixState.allCases) { appearance, state in
                    sampleButton(style: .secondary(appearance))
                        .disabled(state == .disabled)
                }
            }

            DSShowcaseGroup("Material") {
                DSShowcaseMatrix(rows: TangemUI.Button.Material.allCases, columns: MatrixState.allCases) { material, state in
                    sampleButton(style: .material(material))
                        .disabled(state == .disabled)
                }
            }

            DSShowcaseGroup("Hold to confirm") {
                DSShowcaseMatrix(rows: TangemUI.Button.HoldStyle.allCases, columns: MatrixState.allCases) { style, state in
                    TangemUI.Button.holdToConfirm(
                        label: "Confirm",
                        style: style,
                        accessibilityLabel: nil,
                        isLoading: state == .enabled && loadingHoldStyles.contains(style),
                        action: {
                            tapCount += 1
                            startSimulatedHoldLoad(style: style)
                        }
                    )
                    .disabled(state == .disabled)
                }
            }

            DSShowcaseGroup("Size") {
                DSShowcaseMatrix(rows: TangemUI.Button.Size.allCases, columns: [ContentKind.label, .iconOnly]) { size, content in
                    sampleButton(size: size, content: content)
                }
            }

            DSShowcaseGroup("Loading") {
                DSShowcaseMatrix(rows: [LoadingKind.spinner, .message], columns: [StyleKind.brand, .primary, .outline]) { loading, style in
                    sampleButton(style: style.styleType(appearance: .default, material: .glass))
                        .loading(loading.loading(message: "Signing"))
                }
            }
        }
    }

    @ViewBuilder
    private var liveButton: some View {
        if let holdStyle {
            TangemUI.Button.holdToConfirm(
                label: contentKind == .longLabel ? Self.longLabel : label,
                style: holdStyle,
                accessibilityLabel: nil,
                size: size,
                horizontalLayout: horizontalLayout,
                iconStart: liveIconStart,
                iconEnd: liveIconEnd,
                isLoading: loadingKind != .none,
                action: {
                    tapCount += 1
                    startSimulatedLoad()
                }
            )
            .disabled(!isEnabled)
        } else {
            button(content: contentKind, iconStart: liveIconStart, iconEnd: liveIconEnd, action: { tapCount += 1 })
                .size(size)
                .styleType(styleKind.styleType(appearance: appearance, material: material))
                .horizontalLayout(horizontalLayout)
                .loading(loadingKind.loading(message: loadingMessage))
                .disabled(!isEnabled)
        }
    }

    private var liveIconStart: ImageType? {
        iconStartEnabled ? DesignSystem.Icons.ArrowUp.regular20 : nil
    }

    private var liveIconEnd: ImageType? {
        iconEndEnabled ? DesignSystem.Icons.ArrowDown.regular20 : nil
    }

    private var holdStyle: TangemUI.Button.HoldStyle? {
        guard confirmation == .hold, contentKind != .iconOnly else { return nil }

        switch styleKind {
        case .brand: return .brand
        case .primary: return .primary
        case .secondary, .material, .outline, .ghost, .success: return nil
        }
    }

    private func sampleButton(
        style: TangemUI.Button.StyleType = .brand,
        size: TangemUI.Button.Size = .x10,
        content: ContentKind = .label
    ) -> TangemUI.Button {
        button(content: content, iconStart: nil, iconEnd: nil, action: {})
            .size(size)
            .styleType(style)
    }

    private func button(
        content: ContentKind,
        iconStart: ImageType?,
        iconEnd: ImageType?,
        action: @escaping () -> Void
    ) -> TangemUI.Button {
        switch content {
        case .label:
            TangemUI.Button(label: label, accessibilityLabel: nil, action: action)
                .iconStart(iconStart)
                .iconEnd(iconEnd)
        case .longLabel:
            TangemUI.Button(label: Self.longLabel, accessibilityLabel: nil, action: action)
                .iconStart(iconStart)
                .iconEnd(iconEnd)
        case .iconOnly:
            TangemUI.Button(icon: DesignSystem.Icons.ArrowDown.regular24, accessibilityLabel: "Receive", action: action)
        }
    }

    private static let longLabel = "Swap 0.8421 ETH to USDT on Arbitrum One with the best available rate"

    private func startSimulatedLoad() {
        simulatedLoadTask?.cancel()
        simulatedLoadTask = Task { @MainActor in
            if loadingKind == .none {
                loadingKind = .message
            }

            try? await ContinuousClock().sleep(for: .seconds(simulatedLoadDuration))

            guard !Task.isCancelled else { return }

            loadingKind = .none
            simulatedLoadTask = nil
        }
    }

    private func startSimulatedHoldLoad(style: TangemUI.Button.HoldStyle) {
        loadingHoldStyles.insert(style)

        Task { @MainActor in
            try? await ContinuousClock().sleep(for: .seconds(simulatedLoadDuration))
            loadingHoldStyles.remove(style)
        }
    }
}

private extension ButtonShowcase {
    enum StyleKind: CaseIterable {
        case brand
        case primary
        case secondary
        case material
        case outline
        case ghost
        case success

        func styleType(appearance: TangemUI.Button.Appearance, material: TangemUI.Button.Material) -> TangemUI.Button.StyleType {
            switch self {
            case .brand: .brand
            case .primary: .primary
            case .secondary: .secondary(appearance)
            case .material: .material(material)
            case .outline: .outline
            case .ghost: .ghost
            case .success: .success
            }
        }
    }

    enum Confirmation: CaseIterable {
        case tap
        case hold
    }

    enum ContentKind: CaseIterable {
        case label
        case longLabel
        case iconOnly
    }

    enum LoadingKind: CaseIterable {
        case none
        case spinner
        case message

        func loading(message: String) -> TangemUI.Button.Loading? {
            switch self {
            case .none: nil
            case .spinner: .spinner
            case .message: .spinnerWithMessage(message)
            }
        }
    }

    enum MatrixState: CaseIterable {
        case enabled
        case disabled
    }
}

#endif
