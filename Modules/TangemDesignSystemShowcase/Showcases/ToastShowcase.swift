//
//  ToastShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct ToastShowcase: View {
    @State private var label = "Address copied"
    @State private var appearance: Appearance = .neutral
    @State private var hasIcon = true
    @State private var hasAction = false
    @State private var actionTitle = "Undo"
    @State private var isClosable = true
    @State private var actionTaps = 0

    var body: some View {
        DSShowcase("Toast", background: .gradient) { controls in
            controls.text("Label", $label)
            controls.picker("Appearance", $appearance, options: Appearance.allCases, label: \.title)
            if appearance == .neutral {
                controls.toggle("Icon", $hasIcon)
            }
            controls.toggle("Action", $hasAction)
            if hasAction {
                controls.text("Action title", $actionTitle)
            }
            controls.toggle("Closable", $isClosable)
            controls.action("Show toast") {
                ToastPresenter.shared.show(currentToast)
            }
            controls.action("Show long toast") {
                ToastPresenter.shared.show(ToastView(Self.longLabel, appearance: .error))
            }
            controls.action("Dismiss all") {
                ToastPresenter.shared.dismissAll()
            }
            controls.readout("Action taps", "\(actionTaps)")
        } stage: {
            currentToast
        } matrix: {
            DSShowcaseGroup("Appearance") {
                DSShowcaseMatrix(rows: Appearance.allCases, rowLabel: \.title) { appearance in
                    ToastView(appearance.sampleLabel, appearance: appearance.toastAppearance(hasIcon: true))
                }
            }

            DSShowcaseGroup("Options") {
                DSShowcaseMatrix(rows: Option.allCases, rowLabel: \.title) { option in
                    option.toast
                }
            }
        }
    }

    private var currentToast: ToastView {
        let toast = ToastView(label, appearance: appearance.toastAppearance(hasIcon: hasIcon))
            .closable(isClosable)

        guard hasAction else {
            return toast
        }

        return toast.action(actionTitle) { actionTaps += 1 }
    }

    private static let longLabel = "WalletConnect couldn't sign the transaction: the dApp sent a request for a network this wallet doesn't support (code 5100)"
}

// MARK: - Sample data

private extension ToastShowcase {
    enum Appearance: CaseIterable, Hashable {
        case neutral
        case error
        case info
        case success

        var title: String {
            switch self {
            case .neutral: "Neutral"
            case .error: "Error"
            case .info: "Info"
            case .success: "Success"
            }
        }

        var sampleLabel: String {
            switch self {
            case .neutral: "Address copied"
            case .error: "Something went wrong"
            case .info: "Balance is currently hidden"
            case .success: "Transaction sent"
            }
        }

        func toastAppearance(hasIcon: Bool) -> ToastAppearance {
            switch self {
            case .neutral: .neutral(icon: hasIcon ? DesignSystem.Icons.Checkmark.regular20 : nil)
            case .error: .error
            case .info: .info
            case .success: .success
            }
        }
    }

    enum Option: CaseIterable, Hashable {
        case noIcon
        case action
        case notClosable
        case actionNotClosable
        case multiline

        var title: String {
            switch self {
            case .noIcon: "No icon"
            case .action: "Action"
            case .notClosable: "Not closable"
            case .actionNotClosable: "Action, not closable"
            case .multiline: "Multi-line"
            }
        }

        @MainActor
        @ViewBuilder
        var toast: some View {
            switch self {
            case .noIcon:
                ToastView("Promo code copied")
            case .action:
                ToastView("Balance is currently hidden", appearance: .info)
                    .action("Unhide") {}
            case .notClosable:
                ToastView("Wallet disconnected", appearance: .neutral(icon: DesignSystem.Icons.Checkmark.regular20))
                    .closable(false)
            case .actionNotClosable:
                ToastView("Balance is currently hidden", appearance: .info)
                    .action("Unhide") {}
                    .closable(false)
            case .multiline:
                ToastView(ToastShowcase.longLabel, appearance: .error)
                    .frame(width: 370)
            }
        }
    }
}
#endif
