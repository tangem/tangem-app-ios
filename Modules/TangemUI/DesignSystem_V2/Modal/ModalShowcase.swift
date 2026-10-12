//
//  ModalShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct ModalShowcase: View {
    @State private var configuration = ModalShowcaseConfiguration()
    @State private var isPresented = false

    public init() {}

    public var body: some View {
        Form {
            Section("Configuration") {
                Picker("Size", selection: $configuration.size) {
                    Text("Flexible").tag(ModalSize.flexible)
                    Text("Full").tag(ModalSize.full)
                }
                .pickerStyle(.segmented)

                Picker("Content layout", selection: $configuration.contentLayout) {
                    Text("Scrollable").tag(ModalContentLayout.scrollable)
                    Text("Intrinsic").tag(ModalContentLayout.intrinsic)
                    Text("Fill").tag(ModalContentLayout.fill)
                }
                .pickerStyle(.segmented)
                .onChange(of: configuration.contentLayout) { layout in
                    if layout != .fill {
                        configuration.callerManagedScrolling = false
                    }
                }

                Picker("Dynamic Type", selection: $configuration.dynamicTypeSize) {
                    Text("System").tag(nil as DynamicTypeSize?)
                    Text("Small").tag(DynamicTypeSize.small as DynamicTypeSize?)
                    Text("Large").tag(DynamicTypeSize.large as DynamicTypeSize?)
                    Text("XXX Large").tag(DynamicTypeSize.xxxLarge as DynamicTypeSize?)
                    Text("Accessibility 1").tag(DynamicTypeSize.accessibility1 as DynamicTypeSize?)
                    Text("Accessibility 3").tag(DynamicTypeSize.accessibility3 as DynamicTypeSize?)
                    Text("Accessibility 5").tag(DynamicTypeSize.accessibility5 as DynamicTypeSize?)
                }
                .pickerStyle(.menu)

                Toggle("Header", isOn: $configuration.showsHeader)
                Toggle("Header actions", isOn: $configuration.showsActions)
                Toggle("Footer slot", isOn: $configuration.showsFooter)
                Toggle("Short content", isOn: $configuration.shortContent)
                    .disabled(configuration.callerManagedScrolling)
                Toggle("Long content", isOn: $configuration.longContent)
                    .disabled(configuration.shortContent || configuration.callerManagedScrolling)
                Toggle("Caller-managed List", isOn: $configuration.callerManagedScrolling)
                    .disabled(configuration.contentLayout != .fill)
                Toggle("Prevent swipe dismissal", isOn: $configuration.preventsDismissal)

                Button(label: "Present modal", accessibilityLabel: nil) {
                    isPresented = true
                }
                .horizontalLayout(.infinity)
            }
        }
        .navigationTitle("Modal")
        .modifier(ModalShowcaseModifier(isPresented: $isPresented, configuration: configuration))
    }
}

private struct ModalShowcaseConfiguration {
    var size: ModalSize = .flexible
    var contentLayout: ModalContentLayout = .scrollable
    var dynamicTypeSize: DynamicTypeSize?
    var showsHeader = true
    var showsActions = false
    var showsFooter = true
    var shortContent = false
    var longContent = false
    var callerManagedScrolling = false
    var preventsDismissal = false
}

private struct ModalShowcaseModifier: ViewModifier {
    @Binding var isPresented: Bool
    let configuration: ModalShowcaseConfiguration
    var depth = 1

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsNestedModal = false
    @State private var actionCount = 0
    @State private var showsDetails = false
    @State private var showsAccountSelection = false

    func body(content: Content) -> some View {
        // Isolate the override from the form while passing it to all sheet slots, including the standard header.
        content.background {
            presentation(from: Color.clear)
                .dynamicTypeSize(configuration.dynamicTypeSize ?? dynamicTypeSize)
        }
    }

    @ViewBuilder
    private func presentation(from presenter: some View) -> some View {
        if configuration.showsHeader {
            presenter.modal(
                isPresented: $isPresented,
                size: configuration.size,
                contentLayout: configuration.contentLayout,
                title: showsAccountSelection ? "Choose an account" : "Modal \(depth)",
                subtitle: showsAccountSelection ? "Select an account to continue" : "A reusable sheet",
                leading: configuration.showsActions ? .custom(.back { isPresented = false }) : .none,
                actions: configuration.showsActions ? .one(.init(title: "Add") { actionCount += 1 }) : nil,
                onDismiss: reset,
                content: { presentedContent },
                footer: { footer }
            )
        } else {
            presenter.modal(
                isPresented: $isPresented,
                size: configuration.size,
                contentLayout: configuration.contentLayout,
                onDismiss: reset,
                content: { presentedContent },
                footer: { footer }
            )
        }
    }

    private var presentedContent: some View {
        bodyContent
            .animation(
                reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 1),
                value: showsAccountSelection
            )
            .interactiveDismissDisabled(configuration.preventsDismissal)
            .modifier(ModalShowcaseModifier(
                isPresented: $showsNestedModal,
                configuration: configuration,
                depth: depth + 1
            ))
    }

    @ViewBuilder
    private var footer: some View {
        if configuration.showsFooter {
            Button(label: showsAccountSelection ? "Back" : "Done", accessibilityLabel: nil) {
                if showsAccountSelection {
                    showsAccountSelection = false
                } else {
                    isPresented = false
                }
            }
            .horizontalLayout(.infinity)
            .padding(16)
        }
    }

    @ViewBuilder
    private var bodyContent: some View {
        if configuration.contentLayout == .fill, !configuration.callerManagedScrolling {
            ScrollView {
                sheetContent
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        } else {
            sheetContent
        }
    }

    @ViewBuilder
    private var sheetContent: some View {
        if showsAccountSelection {
            VStack(spacing: 16) {
                ForEach(["Main account", "Savings account"], id: \.self) { account in
                    Button(label: account, accessibilityLabel: nil) {
                        showsAccountSelection = false
                    }
                    .horizontalLayout(.infinity)
                }
            }
            .padding(16)
        } else if configuration.callerManagedScrolling {
            List {
                controls
                ForEach(1 ... 30, id: \.self) { index in
                    Text("List item \(index)")
                        .font(token: DesignSystem.Font.bodyMediumToken)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        } else {
            VStack(alignment: .leading, spacing: 24) {
                if configuration.shortContent {
                    Text("A short message that does not need scrolling.")
                        .font(token: DesignSystem.Font.bodyMediumToken)
                        .foregroundStyle(DesignSystem.Color.textPrimary)
                } else {
                    controls
                }

                Toggle("Show details", isOn: $showsDetails)

                if configuration.shortContent, !configuration.showsHeader, !configuration.showsFooter {
                    Button(label: "Close", accessibilityLabel: nil) { isPresented = false }
                        .horizontalLayout(.infinity)
                }

                if showsDetails {
                    Text("The flexible sheet follows content changes while it is presented. Hide these details to restore the shorter height.")
                        .font(token: DesignSystem.Font.bodyMediumToken)
                        .foregroundStyle(DesignSystem.Color.textPrimary)
                }

                if configuration.longContent, !configuration.shortContent {
                    ForEach(1 ... 20, id: \.self) { index in
                        Text("Paragraph \(index). Scroll to see the remaining content.")
                            .font(token: DesignSystem.Font.bodyMediumToken)
                            .foregroundStyle(DesignSystem.Color.textPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private func reset() {
        showsNestedModal = false
        actionCount = 0
        showsDetails = false
        showsAccountSelection = false
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(configuration.preventsDismissal
                ? "Swipe dismissal is disabled. Use a button to close the modal."
                : "Swipe down or use a button to dismiss. Dragging up keeps the current sheet height.")
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)

            if configuration.showsActions {
                Text("Header action taps: \(actionCount)")
                    .font(token: DesignSystem.Font.captionMediumToken)
            }

            Button(label: "Open another modal", accessibilityLabel: nil) {
                showsNestedModal = true
            }
            .horizontalLayout(.infinity)

            if configuration.showsHeader {
                NavigationLink {
                    Text("This screen uses the modal's NavigationStack.")
                        .font(token: DesignSystem.Font.bodyMediumToken)
                        .foregroundStyle(DesignSystem.Color.textPrimary)
                        .padding(16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .topNavigation(title: "Details", onClose: { isPresented = false })
                } label: {
                    Text("Open details")
                        .font(token: DesignSystem.Font.bodyMediumToken)
                }
            }

            if !configuration.callerManagedScrolling {
                Button(label: "Change content", accessibilityLabel: nil) {
                    showsAccountSelection = true
                }
                .horizontalLayout(.infinity)
            }

            if !configuration.showsHeader, !configuration.showsFooter {
                Button(label: "Close", accessibilityLabel: nil) { isPresented = false }
                    .horizontalLayout(.infinity)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ModalShowcase()
    }
}
