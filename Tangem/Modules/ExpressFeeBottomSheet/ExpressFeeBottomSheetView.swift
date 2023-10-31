//
//  ExpressFeeBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressFeeBottomSheetView: View {
    @ObservedObject private var viewModel: ExpressFeeBottomSheetViewModel

    init(viewModel: ExpressFeeBottomSheetViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            BottomSheetHeaderView(title: "Speed and fee")

            GroupedSection(viewModel.feeRowViewModels) {
                FeeRowView(viewModel: $0)
            } footer: {
                DefaultFooterView("Network transaction fees are small charges paid to support network security, incentivize validators, allocate resources, and determine transaction priority.")
            }
            .verticalPadding(0)
            .padding(.horizontal, 14)
        }
    }
}

struct ExpressFeeBottomSheetView_Preview: PreviewProvider {
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
                    .bottomSheet(item: $coordinator.item) {
                        ExpressFeeBottomSheetView(viewModel: $0)
                    }
            }
        }
    }

    class BottomSheetCoordinator: ObservableObject, ExpressFeeBottomSheetRoutable {
        @Published var item: ExpressFeeBottomSheetViewModel?

        func toggleItem() {
            if item == nil {
                item = ExpressFeeBottomSheetViewModel(coordinator: self)
            } else {
                item = nil
            }
        }

        func closeExpressFeeBottomSheet() {
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
