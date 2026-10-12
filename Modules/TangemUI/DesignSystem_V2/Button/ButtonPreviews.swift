//
//  ButtonPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct ButtonShowcase: View {
    @State private var styleKind: StyleKind = .material
    @State private var material: Button.Material = .glass
    @State private var appearance: Button.Appearance = .default
    @State private var size: Button.Size = .x12
    @State private var isEnabled: Bool = true
    @State private var loadingKind: LoadingKind = .none
    @State private var loadingMessage: String = "Loading test"
    @State private var simulatedLoadDuration: Double = 2
    @State private var simulatedLoadTask: Task<Void, Never>?
    @State private var horizontalLayout: Button.HorizontalLayout = .intrinsic
    @State private var contentKind: ContentKind = .label
    @State private var iconStartEnabled = false
    @State private var iconEndEnabled = false
    @State private var customText: String = "Button"
    @State private var dynamicTypeIndex: Int = Self.dynamicTypeAllCases.firstIndex(of: .large) ?? 0
    @State private var tapCount = 0
    @State private var backdropMoves = false
    @State private var darkMode = false

    private enum ContentKind: String, CaseIterable {
        case label
        case longLabel
        case iconOnly
    }

    private enum StyleKind: String, CaseIterable {
        case brand
        case `default`
        case secondary
        case material
        case outline
        case ghost
        case positive
    }

    private var styleType: Button.StyleType {
        switch styleKind {
        case .brand: .brand
        case .default: .default
        case .secondary: .secondary(appearance)
        case .material: .material(material)
        case .outline: .outline
        case .ghost: .ghost
        case .positive: .positive
        }
    }

    private enum LoadingKind: String, CaseIterable {
        case none
        case spinner
        case message
    }

    private var loading: Button.Loading? {
        switch loadingKind {
        case .none: nil
        case .spinner: .spinner
        case .message: .spinnerWithMessage(loadingMessage)
        }
    }

    private func startSimulatedLoad() {
        simulatedLoadTask?.cancel()
        simulatedLoadTask = Task { @MainActor in
            loadingKind = loadingKind == .none ? .message : loadingKind
            try? await Task.sleep(for: .seconds(simulatedLoadDuration))

            guard !Task.isCancelled else { return }

            loadingKind = .none
            simulatedLoadTask = nil
        }
    }

    private static let dynamicTypeAllCases: [DynamicTypeSize] = Array(DynamicTypeSize.allCases)

    private var dynamicTypeSize: DynamicTypeSize {
        Self.dynamicTypeAllCases[dynamicTypeIndex]
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                previewStage(stage: "backdrop", background: materialBackdrop)
                previewStage(stage: "clear", background: Color.clear)

                Text("taps: \(tapCount)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Divider()

                menuPickerRow(
                    title: "style",
                    cases: StyleKind.allCases,
                    binding: $styleKind,
                    label: { $0.rawValue }
                )
                pickerRow(
                    title: "size",
                    cases: Button.Size.allCases,
                    binding: $size,
                    label: { String(describing: $0) }
                )
                Toggle("isEnabled", isOn: $isEnabled)
                Toggle("dark mode", isOn: $darkMode)
                pickerRow(
                    title: "loading",
                    cases: LoadingKind.allCases,
                    binding: $loadingKind,
                    label: { $0.rawValue }
                )

                HStack(spacing: 8) {
                    Text("loading message:").font(.caption)
                    TextField("Enter loading message", text: $loadingMessage)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 8) {
                    SwiftUI.Button("simulate load") { startSimulatedLoad() }
                        .buttonStyle(.bordered)
                        .tint(.blue)

                    Stepper(
                        "\(simulatedLoadDuration, specifier: "%.1f")s",
                        value: $simulatedLoadDuration,
                        in: 0.5 ... 5,
                        step: 0.5
                    )
                }

                pickerRow(
                    title: "layout",
                    cases: Button.HorizontalLayout.allCases,
                    binding: $horizontalLayout,
                    label: { String(describing: $0) }
                )
                pickerRow(
                    title: "content",
                    cases: ContentKind.allCases,
                    binding: $contentKind,
                    label: { $0.rawValue }
                )

                HStack(spacing: 8) {
                    Text("custom text:").font(.caption)
                    TextField("Enter button text", text: $customText)
                        .textFieldStyle(.roundedBorder)
                }

                Stepper(
                    "DT: \(String(describing: dynamicTypeSize))",
                    value: $dynamicTypeIndex,
                    in: 0 ... (Self.dynamicTypeAllCases.count - 1)
                )

                if styleKind == .material {
                    pickerRow(
                        title: "material",
                        cases: Button.Material.allCases,
                        binding: $material,
                        label: { String(describing: $0) }
                    )
                }

                if styleKind == .secondary {
                    pickerRow(
                        title: "appearance",
                        cases: Button.Appearance.allCases,
                        binding: $appearance,
                        label: { String(describing: $0) }
                    )
                }

                if contentKind != .iconOnly {
                    Toggle("icon start", isOn: $iconStartEnabled)
                    Toggle("icon end", isOn: $iconEndEnabled)
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
        .environment(\.colorScheme, darkMode ? .dark : .light)
    }

    private func previewStage(stage: String, background: some View) -> some View {
        preview
            // Force a fresh mount whenever the size changes. The system's Glass
            // press-indicator caches its geometry on first mount and doesn't recompute
            // when @ScaledMetric values inside `Style` change due to a size switch —
            // leaving a stale press-shape inside the new outer capsule. Showcase-only
            // concern: production never resizes a live button. The `stage` prefix keeps
            // the two sibling stages distinctly identified.
            .id("\(stage)-\(size)")
            .dynamicTypeSize(dynamicTypeSize)
            .padding(.vertical, 32)
            // Colorful backdrop so blur (`.regularMaterial`) and solid (no backdrop)
            // are visually distinct — on a flat background they both collapse to
            // ~white capsules and become indistinguishable.
            .frame(maxWidth: .infinity, minHeight: 220)
            .background(background)
    }

    @ViewBuilder
    private var preview: some View {
        let action: () -> Void = { tapCount += 1 }
        let iconStart: ImageType? = iconStartEnabled ? DesignSystem.Icons.ArrowUp.regular20 : nil
        let iconEnd: ImageType? = iconEndEnabled ? DesignSystem.Icons.ArrowDown.regular20 : nil
        let button: Button = {
            switch contentKind {
            case .label:
                return Button(
                    label: customText,
                    accessibilityLabel: nil,
                    action: action
                )
                .iconStart(iconStart)
                .iconEnd(iconEnd)
            case .longLabel:
                return Button(
                    label: "This is a very long button label that may wrap or truncate",
                    accessibilityLabel: nil,
                    action: action
                )
                .iconStart(iconStart)
                .iconEnd(iconEnd)
            case .iconOnly:
                return Button(
                    icon: DesignSystem.Icons.ArrowDown.regular24,
                    accessibilityLabel: "Arrow down",
                    action: action
                )
            }
        }()

        button
            .size(size)
            .styleType(styleType)
            .horizontalLayout(horizontalLayout)
            .loading(loading)
            .disabled(!isEnabled)
    }

    private var materialBackdrop: some View {
        let colors: [Color] = [
            Color(red: 0.2, green: 0.5, blue: 0.95),
            Color(red: 0.85, green: 0.3, blue: 0.6),
            Color(red: 0.95, green: 0.7, blue: 0.2),
            Color(red: 0.2, green: 0.8, blue: 0.5),
        ]

        return HStack(spacing: 0) {
            ForEach(0 ..< 16, id: \.self) { index in
                colors[index % colors.count]
            }
        }
        .frame(width: 1600)
        .offset(x: backdropMoves ? -260 : 260)
        .animation(.linear(duration: 3).repeatForever(autoreverses: true), value: backdropMoves)
        .onAppear { backdropMoves = true }
    }

    private func pickerRow<Value: Hashable>(
        title: String,
        cases: [Value],
        binding: Binding<Value>,
        label: @escaping (Value) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption)
            Picker(title, selection: binding) {
                ForEach(cases, id: \.self) { value in
                    Text(label(value)).tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    /// Dropdown variant — used when the option set is too long for a segmented row.
    private func menuPickerRow<Value: Hashable>(
        title: String,
        cases: [Value],
        binding: Binding<Value>,
        label: @escaping (Value) -> String
    ) -> some View {
        HStack {
            Text(title).font(.caption)
            Spacer()
            Menu {
                ForEach(cases, id: \.self) { value in
                    SwiftUI.Button(label(value)) { binding.wrappedValue = value }
                }
            } label: {
                Text(label(binding.wrappedValue))
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.1), in: Capsule())
            }
        }
    }
}
