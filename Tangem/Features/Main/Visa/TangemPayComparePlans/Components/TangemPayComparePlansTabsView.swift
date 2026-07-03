//
//  TangemPayComparePlansTabsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TangemPayComparePlansTabsView: View {
    let attributes: [TangemPayComparePlansSheetViewModel.Attribute]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(attributes.enumerated()), id: \.element.id) { index, attribute in
                        tab(attribute.tabTitle, isSelected: index == selectedIndex) {
                            onSelect(index)
                        }
                        .id(attribute.id)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 44)
            .onChange(of: selectedIndex) { newIndex in
                guard attributes.indices.contains(newIndex) else { return }

                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(attributes[newIndex].id, anchor: .center)
                    }
                }
            }
        }
        .padding(.vertical, 16)
    }

    private func tab(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        var label = AttributedString(title)
        label.foregroundColor = isSelected ? DesignSystem.Color.textPrimary : DesignSystem.Color.textSecondary

        return TangemButtonV2(label: label, accessibilityLabel: title, action: action)
            .size(.x11)
            .styleType(isSelected ? .material(.glass) : .ghost)
    }
}
