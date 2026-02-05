//
//  ExpressProvidersSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

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

            if let ukNotificationInput = viewModel.ukNotificationInput {
                NotificationView(input: ukNotificationInput)
                    .padding(.vertical, 4)
            }

            VStack(spacing: 6) {
                ForEach(viewModel.providerViewModels) {
                    ExpressProviderRowView(viewModel: $0)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 24)

            ExpressMoreProvidersSoonView()
        }
        .padding(.horizontal, 16)
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
