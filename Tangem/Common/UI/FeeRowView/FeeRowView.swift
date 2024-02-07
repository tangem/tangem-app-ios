//
//  ExpressFeeRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct FeeRowView: View {
    let viewModel: FeeRowViewModel

    private var namespace: Namespace.ID?
    private var titleNamespaceId: String?
    private var subtitleNamespaceId: String?

    init(viewModel: FeeRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: viewModel.isSelected.toggle) {
            HStack(spacing: 8) {
                viewModel.option.icon.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .foregroundColor(iconColor)

                Text(viewModel.option.title)
                    .style(font, color: Colors.Text.primary1)
                    .matchedGeometryEffectOptional(id: SendViewNamespaceId.feeTitle.rawValue, in: namespace)

                Spacer()

                if let subtitleText = viewModel.subtitleText {
                    Text(subtitleText)
                        .style(font, color: Colors.Text.primary1)
                        .matchedGeometryEffectOptional(id: SendViewNamespaceId.feeSubtitle.rawValue, in: namespace)
                        .frame(minWidth: viewModel.isLoading ? 70 : 0)
                        .skeletonable(isShown: viewModel.isLoading)
                }
            }
            .padding(.vertical, 12)
        }
    }

    private var iconColor: Color {
        viewModel.isSelected.value ? Colors.Icon.accent : Colors.Icon.informative
    }

    private var font: Font {
        viewModel.isSelected.value ? Fonts.Bold.footnote : Fonts.Regular.footnote
    }
}

extension FeeRowView: Setupable {
    func setNamespace(_ namespace: Namespace.ID) -> Self {
        map { $0.namespace = namespace }
    }

    func setTitleNamespaceId(_ titleNamespaceId: String?) -> Self {
        map { $0.titleNamespaceId = titleNamespaceId }
    }

    func setSubtitleNamespaceId(_ subtitleNamespaceId: String?) -> Self {
        map { $0.subtitleNamespaceId = subtitleNamespaceId }
    }
}

struct ExpressFeeRowView_Preview: PreviewProvider {
    struct ContentView: View {
        @State private var option: FeeOption = .market

        private var viewModels: [FeeRowViewModel] {
            [FeeRowViewModel(
                option: .market,
                subtitle: .loaded("0.159817 MATIC (0.22 $)"),
                isSelected: .init(get: { option == .market }, set: { _ in option = .market })
            ), FeeRowViewModel(
                option: .fast,
                subtitle: .loaded("0.159817 MATIC (0.22 $)"),
                isSelected: .init(get: { option == .fast }, set: { _ in option = .fast })
            )]
        }

        var body: some View {
            GroupedSection(viewModels) {
//                FeeRowView(viewModel: $0, namespace: ))
                Text($0.subtitleText ?? "A")
            }
            .padding(.vertical, 14)
            .background(Colors.Background.secondary)
        }
    }

    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)

        ContentView()
            .preferredColorScheme(.dark)
    }
}
