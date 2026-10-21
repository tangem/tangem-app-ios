//
//  ModalShowcase.swift
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

struct ModalShowcase: View {
    @State private var size: ModalSize = .flexible
    @State private var contentLayout: ModalContentLayout = .scrollable
    @State private var showsHeader = true
    @State private var showsActions = false
    @State private var showsFooter = true
    @State private var shortContent = false
    @State private var longContent = false
    @State private var callerManagedList = false
    @State private var preventsDismissal = false
    @State private var actionTaps = 0
    @State private var isPresented = false

    var body: some View {
        DSShowcase("Modal", layout: .fill) { controls in
            controls.picker("Size", $size)
            controls.picker("Content layout", $contentLayout, options: [.scrollable, .intrinsic, .fill])
            controls.toggle("Header", $showsHeader)

            if showsHeader {
                controls.toggle("Header actions", $showsActions)
            }

            controls.toggle("Footer slot", $showsFooter)

            if contentLayout == .fill {
                controls.toggle("Caller-managed List", $callerManagedList)
            }

            if !configuration.callerManagedList {
                controls.toggle("Short content", $shortContent)

                if !shortContent {
                    controls.toggle("Long content", $longContent)
                }
            }

            controls.toggle("Prevent swipe dismissal", $preventsDismissal)

            if configuration.showsActions {
                controls.readout("Header action taps", "\(actionTaps)")
            }

            controls.action("Present modal") { isPresented = true }
            controls.note("Dynamic Type, RTL and appearance from the Environment panel reach the presented modal. Nested modals reuse the same configuration.")
        } stage: {
            VStack(spacing: 16) {
                Text(configuration.summary)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)

                TangemUI.Button(label: "Present modal", accessibilityLabel: nil) {
                    isPresented = true
                }
            }
            .padding(16)
            .modifier(ModalShowcasePresenter(
                isPresented: $isPresented,
                actionTaps: $actionTaps,
                configuration: configuration
            ))
        }
    }

    private var configuration: ModalShowcaseConfiguration {
        let isListManaged = contentLayout == .fill && callerManagedList
        return ModalShowcaseConfiguration(
            size: size,
            contentLayout: contentLayout,
            showsHeader: showsHeader,
            showsActions: showsHeader && showsActions,
            showsFooter: showsFooter,
            shortContent: shortContent && !isListManaged,
            longContent: longContent && !shortContent && !isListManaged,
            callerManagedList: isListManaged,
            preventsDismissal: preventsDismissal
        )
    }
}

private struct ModalShowcaseConfiguration {
    let size: ModalSize
    let contentLayout: ModalContentLayout
    let showsHeader: Bool
    let showsActions: Bool
    let showsFooter: Bool
    let shortContent: Bool
    let longContent: Bool
    let callerManagedList: Bool
    let preventsDismissal: Bool

    var summary: String {
        "\(size) size, \(contentLayout) layout"
    }
}

private struct ModalShowcasePresenter: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var actionTaps: Int
    let configuration: ModalShowcaseConfiguration
    var depth = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsNestedModal = false
    @State private var showsDetails = false
    @State private var showsAccountSelection = false

    @ViewBuilder
    func body(content: Content) -> some View {
        if configuration.showsHeader {
            content.modal(
                isPresented: $isPresented,
                size: configuration.size,
                contentLayout: configuration.contentLayout,
                title: showsAccountSelection ? "Choose an account" : "Send to \(depth == 1 ? "Main account" : "account \(depth)")",
                subtitle: showsAccountSelection ? "Select an account to continue" : "Bitcoin · 0.0421 BTC",
                leading: configuration.showsActions ? .custom(.back { isPresented = false }) : .none,
                actions: configuration.showsActions ? .one(TopNavigation.Action(title: "Add") { actionTaps += 1 }) : nil,
                onDismiss: reset,
                content: { presentedContent.legacyFooter { footer } }
            )
        } else {
            content.modal(
                isPresented: $isPresented,
                size: configuration.size,
                contentLayout: configuration.contentLayout,
                onDismiss: reset,
                content: { presentedContent.legacyFooter { footer } }
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
            .modifier(ModalShowcasePresenter(
                isPresented: $showsNestedModal,
                actionTaps: $actionTaps,
                configuration: configuration,
                depth: depth + 1
            ))
    }

    @ViewBuilder
    private var footer: some View {
        if configuration.showsFooter {
            TangemUI.Button(label: showsAccountSelection ? "Back" : "Done", accessibilityLabel: nil) {
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
        if configuration.contentLayout == .fill, !configuration.callerManagedList {
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
                    TangemUI.Button(label: account, accessibilityLabel: nil) {
                        showsAccountSelection = false
                    }
                    .horizontalLayout(.infinity)
                }
            }
            .padding(16)
        } else if configuration.callerManagedList {
            List {
                controls
                ForEach(Self.transactions, id: \.self) { transaction in
                    Text(transaction)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        } else {
            VStack(alignment: .leading, spacing: 24) {
                if configuration.shortContent {
                    Text("Your transaction has been sent. It usually takes a few minutes to confirm.")
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                } else {
                    controls
                }

                Toggle("Show details", isOn: $showsDetails)

                if configuration.shortContent, !configuration.showsHeader, !configuration.showsFooter {
                    closeButton
                }

                if showsDetails {
                    Text("The network fee is paid to miners and depends on the current network load. The flexible sheet follows this content: hide the details to restore the shorter height.")
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                }

                if configuration.longContent {
                    ForEach(Self.transactions, id: \.self) { transaction in
                        Text(transaction)
                            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(configuration.preventsDismissal
                ? "Swipe dismissal is disabled. Use a button to close the modal."
                : "Swipe down or use a button to dismiss. Dragging up keeps the current sheet height.")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)

            if configuration.showsActions {
                Text("Header action taps: \(actionTaps)")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
            }

            TangemUI.Button(label: "Open another modal", accessibilityLabel: nil) {
                showsNestedModal = true
            }
            .horizontalLayout(.infinity)

            if configuration.showsHeader {
                NavigationLink {
                    Text("This screen uses the modal's NavigationStack.")
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .padding(16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .topNavigation(title: "Details", onClose: { isPresented = false })
                } label: {
                    Text("Open details")
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textAccentBlue)
                }
            }

            if !configuration.callerManagedList {
                TangemUI.Button(label: "Change content", accessibilityLabel: nil) {
                    showsAccountSelection = true
                }
                .horizontalLayout(.infinity)
            }

            if !configuration.showsHeader, !configuration.showsFooter {
                closeButton
            }
        }
    }

    private var closeButton: some View {
        TangemUI.Button(label: "Close", accessibilityLabel: nil) { isPresented = false }
            .horizontalLayout(.infinity)
    }

    private func reset() {
        showsNestedModal = false
        showsDetails = false
        showsAccountSelection = false
    }

    private static let transactions: [String] = [
        "Received 0.0120 BTC from bc1q…7x2f",
        "Sent 0.5000 ETH to 0x71C7…976F",
        "Swapped 120 USDT to 0.0018 BTC",
        "Received 36.17 SOL from 9WzD…AWWM",
        "Staked 412.9 TON",
        "Sent 880.4 POL to 0x4B20…02dA",
        "Received 2,031.6 ADA from addr1…q8vz",
        "Sent 9,412 DOGE to DH5y…m4fP",
        "Received 3.88 LTC from ltc1…k9w3",
        "Swapped 44.2 AVAX to 320.15 USDC",
        "Received 0.0103 WBTC from 0x9a3F…e1C4",
        "Sent 1,250.00 USDT to TN3W…4XpF",
        "Received 0.2210 ETH from 0xAb58…eC9B",
        "Unstaked 120.0 TON",
        "Sent 0.0040 BTC to bc1q…z0nd",
        "Received 15.00 USDC from 0x12F4…88aE",
        "Swapped 0.1000 ETH to 312.40 USDT",
        "Received 600.0 POL from 0x3C44…93BC",
        "Sent 18.40 SOL to 5Fh1…QwEr",
        "Received 1,000 DOGE from DQ9k…2LmN",
    ]
}
#endif
