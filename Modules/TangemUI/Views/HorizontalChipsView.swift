//
//  HorizontalChipsView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct Chip: Identifiable, Hashable, Equatable {
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

    public init(
        chips: [Chip],
        selectedId: Binding<Chip.ID?>
    ) {
        self.chips = chips
        _selectedId = selectedId
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.horizontalContentSpacing) {
                ForEach(chips) { chip in
                    let title = chip.title
                    ChipView(
                        title: title,
                        isSelected: selectedId == chip.id
                    ) {
                        if selectedId == chip.id {
                            selectedId = nil
                        } else {
                            selectedId = chip.id
                        }
                    }
                }
            }
            .padding(.horizontal, Constants.horizontalContentPadding)
        }
        .frame(height: Constants.chipHeight)
        .onAppear(perform: ensureDefaultSelectionIfNeeded)
        .onChange(of: chips) { _ in
            ensureDefaultSelectionIfNeeded()
        }
    }
}

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
        static let horizontalContentPadding: CGFloat = 16
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
                    .font(Fonts.Bold.subheadline)
                    .lineLimit(1)
                    .padding(.horizontal, Constants.horizontalChipPadding)
                    .padding(.vertical, Constants.verticalChipPadding)
                    .frame(height: Constants.chipHeight)
                    .foregroundStyle(foregroundColor)
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
