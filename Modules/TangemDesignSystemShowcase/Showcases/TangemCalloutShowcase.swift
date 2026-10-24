//
//  TangemCalloutShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct TangemCalloutShowcase: View {
    @State private var text = "Swipe to see your other wallets"
    @State private var arrowAlignment: TangemCallout.ArrowAlignment = .top
    @State private var palette: PaletteOption = .green
    @State private var showIcon = true
    @State private var actionCount = 0

    var body: some View {
        DSShowcase("TangemCallout") { controls in
            controls.text("Text", $text)
            controls.picker("Arrow alignment", $arrowAlignment, options: Self.arrowAlignments)
            controls.picker("Palette", $palette)
            controls.toggle("Icon", $showIcon)
            controls.readout("Action taps", "\(actionCount)")
        } stage: {
            callout(text: text, arrowAlignment: arrowAlignment, palette: palette)
                .icon(showIcon ? Assets.star.image : nil)
        } matrix: {
            DSShowcaseMatrix(rows: PaletteOption.allCases, columns: Self.arrowAlignments) { palette, arrowAlignment in
                callout(text: "Tap to copy the address", arrowAlignment: arrowAlignment, palette: palette)
                    .icon(Assets.star.image)
            }
        }
    }

    private func callout(
        text: String,
        arrowAlignment: TangemCallout.ArrowAlignment,
        palette: PaletteOption
    ) -> TangemCallout {
        TangemCallout(
            text: text,
            arrowAlignment: arrowAlignment,
            action: TangemCallout.Action(icon: Assets.star.image, closure: { actionCount += 1 })
        )
        .colorPalette(palette.palette)
    }
}

private extension TangemCalloutShowcase {
    static var arrowAlignments: [TangemCallout.ArrowAlignment] { [.top, .bottom] }

    enum PaletteOption: CaseIterable {
        case green
        case gray
        case blue

        var palette: TangemCallout.ColorPalette {
            switch self {
            case .green: .green
            case .gray: .gray
            case .blue: .blue
            }
        }
    }
}
#endif
