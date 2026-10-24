//
//  TangemSearchFieldShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemUI

struct TangemSearchFieldShowcase: View {
    @FocusState private var isFocused: Bool
    @State private var text = ""
    @State private var placeholder = "Search tokens"
    @State private var cornerStyle: TangemSearchField.CornerStyle = .capsule
    @State private var hasSearchIcon = true
    @State private var hasClearButton = true

    var body: some View {
        DSShowcase("TangemSearchField", layout: .fill) { controls in
            controls.picker("Corner style", $cornerStyle, options: Self.cornerStyles)
            controls.toggle("Search icon", $hasSearchIcon)
            controls.toggle("Clear button", $hasClearButton)
            controls.text("Placeholder", $placeholder)
            controls.readout("Text", text.isEmpty ? "empty" : text)
            controls.action("Resign focus") { isFocused = false }
        } stage: {
            VStack {
                TangemSearchField(
                    text: $text,
                    focusAction: { isFocused = true },
                    clearAction: { text = "" },
                    cancelAction: {
                        text = ""
                        isFocused = false
                    }
                )
                .cornerStyle(cornerStyle)
                .placeholder(text: placeholder)
                .configure(hasSearchIcon: hasSearchIcon, hasClearButton: hasClearButton)
                .frame(height: 44)
                .focused($isFocused)

                Spacer()
            }
            .padding(16)
        } matrix: {
            DSShowcaseMatrix(rows: Self.cornerStyles, columns: FieldContent.allCases) { cornerStyle, content in
                TangemSearchField(text: .constant(content.text))
                    .cornerStyle(cornerStyle)
                    .placeholder(text: "Search tokens")
                    .frame(width: 240, height: 44)
            }
        }
    }
}

private extension TangemSearchFieldShowcase {
    static var cornerStyles: [TangemSearchField.CornerStyle] { [.capsule, .rounded] }

    enum FieldContent: CaseIterable {
        case empty
        case filled

        var text: String {
            switch self {
            case .empty: ""
            case .filled: "Ethereum"
            }
        }
    }
}
#endif
