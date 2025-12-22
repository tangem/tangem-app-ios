//
//  ExpressFeeRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI

struct FeeRowView: View {
    let viewModel: FeeRowViewModel

    private var optionGeometryEffect: GeometryEffectPropertiesModel?
    private var amountGeometryEffect: GeometryEffectPropertiesModel?

    init(viewModel: FeeRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        switch viewModel.style {
        case .plain:
            content
        case .selectable(let isSelected):
            Button(action: isSelected.toggle) {
                content
            }
        }
    }

    private var content: some View {
        HStack(spacing: 8) {
            leadingView
                .matchedGeometryEffect(optionGeometryEffect)

            Spacer()

            trailingView
                .lineLimit(1)
                .matchedGeometryEffect(amountGeometryEffect)
        }
        .padding(.vertical, 12)
    }

    private var leadingView: some View {
        HStack(spacing: 8) {
            viewModel.option.icon.image
                .resizable()
                .renderingMode(.template)
                .frame(width: 24, height: 24)
                .foregroundColor(iconColor)

            Text(viewModel.option.title)
                .style(leadingFont, color: Colors.Text.primary1)
        }
    }

    @ViewBuilder
    private var trailingView: some View {
        switch viewModel.components {
        case .loading:
            SkeletonView()
                .frame(width: 70, height: 15)
        case .success(let components):
            trailingView(for: components)
        case .failure:
            Text(AppConstants.emDashSign)
                .style(leadingFont, color: Colors.Text.primary1)
                .layoutPriority(1)
        }
    }

    func trailingView(for components: FormattedFeeComponents) -> some View {
        HStack(spacing: 4) {
            Text(components.cryptoFee)
                .style(leadingFont, color: Colors.Text.primary1)
                .layoutPriority(1)

            if let fiatFee = components.fiatFee {
                Text(AppConstants.dotSign)
                    .style(Fonts.RegularStatic.footnote, color: Colors.Text.primary1)
                    .layoutPriority(3)

                Text(fiatFee)
                    .style(Fonts.RegularStatic.subheadline, color: Colors.Text.tertiary)
                    .layoutPriority(2)
            }
        }
    }

    private var leadingFont: Font {
        switch viewModel.style {
        case .plain:
            Fonts.RegularStatic.subheadline
        case .selectable(let isSelected):
            isSelected.value ? Fonts.BoldStatic.subheadline : Fonts.RegularStatic.subheadline
        }
    }

    private var iconColor: Color {
        switch viewModel.style {
        case .plain:
            Colors.Icon.accent
        case .selectable(let isSelected):
            isSelected.value ? Colors.Icon.accent : Colors.Icon.informative
        }
    }
}

// MARK: - Setupable

extension FeeRowView: Setupable {
    func optionGeometryEffect(_ effect: GeometryEffectPropertiesModel?) -> Self {
        map { $0.optionGeometryEffect = effect }
    }

    func amountGeometryEffect(_ effect: GeometryEffectPropertiesModel?) -> Self {
        map { $0.amountGeometryEffect = effect }
    }
}

struct ExpressFeeRowView_Preview: PreviewProvider {
    struct ContentView: View {
        @State private var option: FeeOption = .market

        private var viewModels: [FeeRowViewModel] {
            [
                FeeRowViewModel(
                    option: .slow,
                    components: .success(.init(cryptoFee: "0.359817123123123123123 MATIC", fiatFee: "123123123123120.22 $")),
                    style: .selectable(isSelected: .init(get: { option == .slow }, set: { _ in option = .slow }))
                ),
                FeeRowViewModel(
                    option: .market,
                    components: .success(.init(cryptoFee: "0.159817 MATIC", fiatFee: "0.22 $")),
                    style: .selectable(isSelected: .init(get: { option == .market }, set: { _ in option = .market }))
                ),
                FeeRowViewModel(
                    option: .fast,
                    components: .success(.init(cryptoFee: "0.159817 MATIC", fiatFee: "0.22 $")),
                    style: .selectable(isSelected: .init(get: { option == .fast }, set: { _ in option = .fast }))
                ),
            ]
        }

        var body: some View {
            GroupedScrollView(contentType: .lazy(alignment: .leading, spacing: 14)) {
                GroupedSection(viewModels) {
                    FeeRowView(viewModel: $0)
                }
            }
            .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        }
    }

    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)

        ContentView()
            .preferredColorScheme(.dark)
    }
}
