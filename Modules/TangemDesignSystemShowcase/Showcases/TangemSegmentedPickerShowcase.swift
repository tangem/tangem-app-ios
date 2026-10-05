//
//  TangemSegmentedPickerShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemUI

struct TangemSegmentedPickerShowcase: View {
    @State private var style: TangemSegmentedPickerStyle = .fixed
    @State private var showSeparators = true
    @State private var isDisabled = false
    @State private var segmentCount = 4
    @State private var selectedItem = Item.all[0]

    var body: some View {
        DSShowcase("TangemSegmentedPicker") { controls in
            controls.picker("Style", $style, options: Self.styles)
            controls.toggle("Separators", $showSeparators)
            controls.toggle("Disabled", $isDisabled)
            controls.value("Segments", $segmentCount, in: 1 ... Item.all.count)
            controls.readout("Selected", selection.wrappedValue.text)
        } stage: {
            TangemSegmentedPicker(data: items, selection: selection)
                .showSeparators(showSeparators)
                .style(style)
                .disabled(isDisabled)
        } matrix: {
            DSShowcaseMatrix(rows: Self.styles, columns: PickerState.allCases) { style, state in
                TangemSegmentedPicker(data: Array(Item.all.prefix(4)), selection: .constant(Item.all[1]))
                    .showSeparators(state != .noSeparators)
                    .style(style)
                    .disabled(state == .disabled)
                    .frame(width: 280)
            }
        }
    }

    private var items: [Item] {
        Array(Item.all.prefix(segmentCount))
    }

    private var selection: Binding<Item> {
        Binding(
            get: { items.contains(selectedItem) ? selectedItem : items[0] },
            set: { selectedItem = $0 }
        )
    }
}

private extension TangemSegmentedPickerShowcase {
    static var styles: [TangemSegmentedPickerStyle] { [.fixed, .flexible] }

    struct Item: TangemSegmentedPickerTextProvider {
        let text: String

        static var all: [Item] {
            ["1H", "1D", "1W", "1M", "3M", "6M", "1Y", "All time"].map { Item(text: $0) }
        }
    }

    enum PickerState: CaseIterable {
        case separators
        case noSeparators
        case disabled
    }
}
#endif
