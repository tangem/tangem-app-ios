//
//  CheckboxShowcase.swift
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

struct CheckboxShowcase: View {
    @State private var value: Checkbox.Value = .unchecked
    @State private var isOn = false
    @State private var size: Checkbox.Size = .size24
    @State private var isEnabled = true
    @State private var expandsHitArea = false

    var body: some View {
        DSShowcase("Checkbox") { controls in
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
                Checkbox(value: value) {
                    value = value.toggled
                }
                .size(size)
                .expandsHitArea(expandsHitArea)
                .accessibilityLabel("Tri-state checkbox")

                HStack(spacing: 12) {
                    Checkbox(isOn: $isOn)
                        .size(size)
                        .expandsHitArea(expandsHitArea)
                        .accessibilityLabel("Boolean checkbox")

                    Text("init(isOn:)")
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                }
            }
            .disabled(!isEnabled)
        } matrix: {
            ForEach(Checkbox.Size.allCases, id: \.self) { size in
                DSShowcaseGroup("Size \(String(describing: size))") {
                    DSShowcaseMatrix(rows: MatrixState.allCases, columns: Checkbox.Value.allCases) { state, value in
                        if state == .enabled || value != .error {
                            Checkbox(value: value) {}
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

private extension CheckboxShowcase {
    enum MatrixState: CaseIterable {
        case enabled
        case disabled
    }
}
#endif
