//
//  SelectableSwappingFeeRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SelectableSwappingFeeRowView: View {
    private let viewModel: SelectableSwappingFeeRowViewModel

    init(viewModel: SelectableSwappingFeeRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(viewModel.title)
                .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

            Spacer()

            content
        }
        .lineLimit(1)
        .padding(.vertical, 14)
        .background(Colors.Background.primary)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.isSelected.toggle()
        }
    }

    @ViewBuilder
    private var content: some View {
        HStack(spacing: 4) {
            Text(viewModel.subtitle)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

            Assets.check.image
                .resizable()
                .renderingMode(.template)
                .frame(width: 9, height: 9)
                .foregroundColor(Colors.Icon.accent)
                .opacity(viewModel.isSelected.value ? 1 : 0)
        }
    }
}

struct SelectableSwappingFeeRowView_Previews: PreviewProvider {
    struct ContentView: View {
        @State private var isSelectedFirst: Bool = false

        var viewModels: [SelectableSwappingFeeRowViewModel] {
            [
                .init(
                    title: "Normal",
                    subtitle: "0.155 MATIC (0.145 $)",
                    isSelected: .init(get: { isSelectedFirst }, set: { isSelectedFirst = $0 })
                ),
                .init(
                    title: "Priority",
                    subtitle: "0.163 MATIC (0.156 $)",
                    isSelected: .init(get: { !isSelectedFirst }, set: { isSelectedFirst = !$0 })
                ),
            ]
        }

        var body: some View {
            ZStack {
                Colors.Background.secondary

                GroupedSection(viewModels) {
                    SelectableSwappingFeeRowView(viewModel: $0)
                }
                .padding()
            }
        }
    }

    static var previews: some View {
        ContentView()
    }
}
