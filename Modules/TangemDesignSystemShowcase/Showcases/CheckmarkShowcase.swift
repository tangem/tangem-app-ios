//
//  CheckmarkShowcase.swift
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

struct CheckmarkShowcase: View {
    @State private var value: Checkmark.Value = .unchecked
    @State private var isOn = false
    @State private var size: Checkmark.Size = .size24
    @State private var isEnabled = true
    @State private var expandsHitArea = false

    var body: some View {
        DSShowcase("Checkmark") { controls in
            controls.picker("Value", $value)
            controls.picker("Size", $size)
            controls.toggle("Enabled", $isEnabled)
            controls.toggle("Expands hit area", $expandsHitArea)
            controls.action("Validate") {
                if value == .unchecked {
                    value = .error
                }
            }
            controls.note("Validate marks an unchecked control as error; tapping it then checks it.")
        } stage: {
            VStack(spacing: 32) {
                Checkmark(value: value) {
                    value = value.toggled
                }
                .size(size)
                .expandsHitArea(expandsHitArea)
                .accessibilityLabel("Showcase checkmark")

                HStack(spacing: 12) {
                    Checkmark(isOn: $isOn)
                        .size(size)
                        .expandsHitArea(expandsHitArea)
                        .accessibilityLabel("Boolean checkmark")

                    Text("init(isOn:)")
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                }
            }
            .disabled(!isEnabled)
        } matrix: {
            ForEach(Checkmark.Size.allCases, id: \.self) { size in
                DSShowcaseGroup("Size \(String(describing: size))") {
                    DSShowcaseMatrix(rows: MatrixState.allCases, columns: Checkmark.Value.allCases) { state, value in
                        if state == .enabled || value != .error {
                            Checkmark(value: value) {}
                                .size(size)
                                .accessibilityLabel(String(describing: value))
                                .disabled(state == .disabled)
                        }
                    }
                }
            }
        }
    }
}

private extension CheckmarkShowcase {
    enum MatrixState: CaseIterable {
        case enabled
        case disabled
    }
}
#endif
