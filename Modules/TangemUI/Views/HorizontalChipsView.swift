//
//  HorizontalChipsView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct Chip: Identifiable, Hashable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct HorizontalChipsView: View {
    private let chips: [Chip]
    @Binding private var selectedId: Chip.ID?
    private let horizontalInset: CGFloat

    public init(
        chips: [Chip],
        selectedId: Binding<Chip.ID?>,
        horizontalInset: CGFloat = 0
    ) {
        self.chips = chips
        _selectedId = selectedId
        self.horizontalInset = horizontalInset
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.horizontalContentSpacing) {
                ForEach(chips) { chip in
                    ChipView(
                        title: chip.title,
                        isSelected: selectedId == chip.id
                    ) {
                        guard selectedId != chip.id else { return }
                        selectedId = chip.id
                    }
                }
            }
            .padding(.horizontal, horizontalInset)
        }
        .frame(height: Constants.chipHeight)
        .onAppear(perform: ensureDefaultSelectionIfNeeded)
        .onChange(of: chips) { _ in
            ensureDefaultSelectionIfNeeded()
        }
    }
}

extension HorizontalChipsView {
    private func ensureDefaultSelectionIfNeeded() {
        if selectedId == nil {
            selectedId = chips.first?.id
        }
    }

    private enum Constants {
        static let chipHeight: CGFloat = 36
        static let chipCornerRadius: CGFloat = 24
        static let horizontalContentSpacing: CGFloat = 8
        static let horizontalChipPadding: CGFloat = 16
        static let verticalChipPadding: CGFloat = 8
    }

    struct ChipView: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Text(title)
                    .style(Fonts.Bold.subheadline, color: foregroundColor)
                    .lineLimit(1)
                    .padding(.horizontal, Constants.horizontalChipPadding)
                    .padding(.vertical, Constants.verticalChipPadding)
                    .frame(height: Constants.chipHeight)
                    .background(
                        RoundedRectangle(
                            cornerRadius: Constants.chipCornerRadius,
                            style: .continuous
                        )
                        .fill(backgroundColor)
                    )
            }
            .buttonStyle(.plain)
        }

        private var backgroundColor: Color {
            isSelected ? Colors.Button.primary : Colors.Button.secondary
        }

        private var foregroundColor: Color {
            isSelected ? Colors.Text.primary2 : Colors.Text.primary1
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("HorizontalChipsView") {
    @Previewable @State var selectedId: Chip.ID? = nil

    HorizontalChipsView(
        chips: [
            .init(id: "all", title: "All"),
            .init(id: "top", title: "Top"),
            .init(id: "gainers", title: "Gainers"),
            .init(id: "losers", title: "Losers"),
            .init(id: "nft", title: "NFT"),
            .init(id: "defi", title: "DeFi"),
            .init(id: "ai", title: "AI"),
            .init(id: "metaverse", title: "Metaverse"),
        ],
        selectedId: $selectedId
    )
    .padding()
}
#endif
