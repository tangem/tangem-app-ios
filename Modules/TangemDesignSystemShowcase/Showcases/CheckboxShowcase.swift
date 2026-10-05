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
    @State private var isEnabled = true
    @State private var expandsHitArea = false

    var body: some View {
        DSShowcase("Checkbox") { controls in
            controls.picker("Value", $value)
            controls.toggle("Enabled", $isEnabled)
            controls.toggle("Expands hit area", $expandsHitArea)
        } stage: {
            VStack(spacing: 32) {
                Checkbox(value: value) {
                    value = value == .checked ? .unchecked : .checked
                }
                .expandsHitArea(expandsHitArea)
                .accessibilityLabel("Tri-state checkbox")

                HStack(spacing: 12) {
                    Checkbox(isOn: $isOn)
                        .expandsHitArea(expandsHitArea)
                        .accessibilityLabel("Boolean checkbox")

                    Text("init(isOn:)")
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                }
            }
            .disabled(!isEnabled)
        } matrix: {
            DSShowcaseMatrix(rows: MatrixState.allCases, columns: Checkbox.Value.allCases) { state, value in
                Checkbox(value: value) {}
                    .accessibilityLabel(String(describing: value))
                    .disabled(state == .disabled)
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
