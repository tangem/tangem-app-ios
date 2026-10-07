//
//  CheckmarkShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemUI

struct CheckmarkShowcase: View {
    @State private var isOn = false
    @State private var isEnabled = true
    @State private var expandsHitArea = false

    var body: some View {
        DSShowcase("Checkmark") { controls in
            controls.toggle("Checked", $isOn)
            controls.toggle("Enabled", $isEnabled)
            controls.toggle("Expands hit area", $expandsHitArea)
        } stage: {
            Checkmark(isOn: $isOn)
                .expandsHitArea(expandsHitArea)
                .accessibilityLabel("Showcase checkmark")
                .disabled(!isEnabled)
        } matrix: {
            DSShowcaseMatrix(
                rows: MatrixState.allCases,
                columns: [false, true],
                columnLabel: { $0 ? "checked" : "unchecked" }
            ) { state, checked in
                Checkmark(checked: checked) {}
                    .accessibilityLabel(checked ? "checked" : "unchecked")
                    .disabled(state == .disabled)
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
