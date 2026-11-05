//
//  ButtonGroupShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemUI

struct ButtonGroupShowcase: View {
    @State private var orientation: ButtonGroup.Orientation = .vertical
    @State private var showsStart = true
    @State private var taps = 0

    var body: some View {
        DSShowcase("ButtonGroup") { controls in
            controls.picker("Orientation", $orientation)
            controls.toggle("Start button", $showsStart)
            controls.readout("Taps", "\(taps)")
        } stage: {
            group(orientation: orientation, showsStart: showsStart)
                .padding(.horizontal, 16)
        } matrix: {
            DSShowcaseMatrix(
                rows: ButtonGroup.Orientation.allCases,
                columns: [true, false],
                columnLabel: { $0 ? "start + end" : "end only" }
            ) { orientation, showsStart in
                group(orientation: orientation, showsStart: showsStart)
                    .frame(width: 360)
            }
        }
    }

    private func group(orientation: ButtonGroup.Orientation, showsStart: Bool) -> ButtonGroup {
        let start = TangemUI.Button(label: "Learn more", accessibilityLabel: nil, action: tap)
            .styleType(.secondary(.default))
        let end = TangemUI.Button(label: "Got it", accessibilityLabel: nil, action: tap)
            .styleType(.primary)

        return ButtonGroup(start: showsStart ? start : nil, end: end)
            .orientation(orientation)
    }

    private func tap() {
        taps += 1
    }
}
#endif
