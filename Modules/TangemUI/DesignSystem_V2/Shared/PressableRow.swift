//
//  PressableRow.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct PressableRow<Label: View, Accessory: View>: View {
    private let onTap: (() -> Void)?
    private let accessorySpacing: CGFloat
    private let label: Label
    private let accessory: Accessory

    init(
        onTap: (() -> Void)?,
        accessorySpacing: CGFloat = 0,
        label: Label,
        accessory: Accessory = EmptyView()
    ) {
        self.onTap = onTap
        self.accessorySpacing = accessorySpacing
        self.label = label
        self.accessory = accessory
    }

    var body: some View {
        button
            .overlay(alignment: .bottom) { accessory }
    }
}

// MARK: - Shell

private extension PressableRow {
    @ViewBuilder
    var button: some View {
        if let onTap {
            SwiftUI.Button(action: onTap) { cell }
                .buttonStyle(RowPressStyle())
        } else {
            cell
        }
    }

    /// The hidden copy reserves the accessory's space so the press fill spans it, while the real one is
    /// overlaid outside the button and keeps its own taps.
    var cell: some View {
        VStack(alignment: .leading, spacing: accessorySpacing) {
            label

            accessory
                .hidden()
        }
    }
}

// MARK: - Press style

private struct RowPressStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed && isEnabled ? DesignSystem.Color.interactionPressDefault : Color.clear)
            .contentShape(Rectangle())
    }
}
