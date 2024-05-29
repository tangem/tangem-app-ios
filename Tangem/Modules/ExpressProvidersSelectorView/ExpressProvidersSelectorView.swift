//
//  ExpressProvidersSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressProvidersSelectorView: View {
    @ObservedObject private var viewModel: ExpressProvidersSelectorViewModel

    init(viewModel: ExpressProvidersSelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(
                title: Localization.expressChooseProvidersTitle,
                subtitle: Localization.expressChooseProvidersSubtitle
            )
            .fixedSize(horizontal: false, vertical: true)

            GroupedSection(viewModel.providerViewModels) {
                ProviderRowView(viewModel: $0)
            }
            .interItemSpacing(14)
            .innerContentPadding(12)
            .backgroundColor(Colors.Background.action)
            .padding(.vertical, 10)

            moreProvidersInformationView
        }
        .padding(.horizontal, 16)
    }

    private var moreProvidersInformationView: some View {
        VStack(alignment: .center, spacing: 4) {
            Assets.expressMoreProvidersIcon.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.inactive)

            Text(Localization.expressMoreProvidersSoon)
                .style(Fonts.Regular.footnote, color: Colors.Icon.informative)
                .multilineTextAlignment(.center)
        }
    }
}

struct ExpressProvidersSelectorView_Preview: PreviewProvider {
    struct StatableContainer: View {
        @ObservedObject private var coordinator = BottomSheetCoordinator()

        var body: some View {
            ZStack {
                Colors.Background.primary
                    .edgesIgnoringSafeArea(.all)

                Button("Bottom sheet isShowing \((coordinator.item != nil).description)") {
                    coordinator.toggleItem()
                }
                .font(Fonts.Bold.body)
                .offset(y: -200)

                NavHolder()
                    .bottomSheet(item: $coordinator.item, backgroundColor: Colors.Background.tertiary) {
                        ExpressProvidersSelectorView(viewModel: $0)
                    }
            }
        }
    }

    class BottomSheetCoordinator: ObservableObject, ExpressProvidersSelectorRoutable {
        @Published var item: ExpressProvidersSelectorViewModel?

        func toggleItem() {
            if item == nil {
                item = ExpressModulesFactoryMock().makeExpressProvidersSelectorViewModel(coordinator: self)
            } else {
                item = nil
            }
        }

        func closeExpressProvidersSelector() {
            item = nil
        }
    }

    static var previews: some View {
        StatableContainer()
            .preferredColorScheme(.light)

        StatableContainer()
            .preferredColorScheme(.dark)
    }
}
