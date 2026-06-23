//
//  TypographyV2Demo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

final class TypographyV2DemoViewModel: ObservableObject, Identifiable {
    let items: [Item] = [
        Item(name: "display / medium", token: DesignSystem.Font.displayMediumToken),
        Item(name: "heading / medium", token: DesignSystem.Font.headingMediumToken),
        Item(name: "heading / small", token: DesignSystem.Font.headingSmallToken),
        Item(name: "subheading / medium", token: DesignSystem.Font.subheadingMediumToken),
        Item(name: "body / medium", token: DesignSystem.Font.bodyMediumToken),
        Item(name: "caption / medium", token: DesignSystem.Font.captionMediumToken),
    ]

    struct Item: Identifiable {
        let name: String
        let token: TangemTypographyToken

        var id: String { name }
    }
}

struct TypographyV2DemoView: View {
    private static let typeSizes = Array(DynamicTypeSize.allCases)

    @ObservedObject var viewModel: TypographyV2DemoViewModel

    @State private var selectedID: String
    @State private var typeSizeIndex: Int

    init(viewModel: TypographyV2DemoViewModel) {
        self.viewModel = viewModel
        _selectedID = State(initialValue: viewModel.items.first?.id ?? "")
        _typeSizeIndex = State(initialValue: Self.typeSizes.firstIndex(of: .large) ?? 0)
    }

    private var token: TangemTypographyToken {
        viewModel.items.first { $0.id == selectedID }?.token ?? DesignSystem.Font.bodyMediumToken
    }

    private var typeSize: DynamicTypeSize {
        Self.typeSizes[typeSizeIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Picker("Font", selection: $selectedID) {
                ForEach(viewModel.items) { item in
                    Text(item.name).tag(item.id)
                }
            }
            .pickerStyle(.menu)

            Stepper(value: $typeSizeIndex, in: 0 ... Self.typeSizes.count - 1) {
                Text("Dynamic Type: \(String(describing: typeSize))")
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("The quick brown fox jumps over the lazy dog while the sleepy cat keeps watch from the warm windowsill.")

                VStack(alignment: .leading, spacing: 0) {
                    Text("First stacked line")
                    Text("Second stacked line")
                    Text("Third stacked line")
                }
            }
            .font(token)
            .foregroundStyle(DesignSystem.Color.textPrimary)
            .dynamicTypeSize(typeSize)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignSystem.Color.borderPrimary, lineWidth: 1)
            )

            Spacer()
        }
        .padding(16)
        .navigationBarTitle(Text("Typography V2"))
    }
}
