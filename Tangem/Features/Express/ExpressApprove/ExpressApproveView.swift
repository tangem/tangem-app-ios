//
//  ExpressApproveView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct ExpressApproveView: View {
    @ObservedObject private var viewModel: ExpressApproveViewModel

    init(viewModel: ExpressApproveViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 22) {
            GroupedSection(viewModel.menuRowViewModel) {
                DefaultMenuRowView(viewModel: $0, selection: $viewModel.selectedAction)
            } footer: {
                approveInfoDescriptionView
            }
            .backgroundColor(Colors.Background.action)

            GroupedSection(viewModel.feeCompactViewModel) { feeViewModel in
                FeeCompactView(viewModel: feeViewModel) {
                    viewModel.didTapFeeSelectorButton()
                }
            } footer: {
                DefaultFooterView(viewModel.feeFooterText)
            }
            .backgroundColor(Colors.Background.action)
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .padding(.horizontal, 16)
        .background(Colors.Background.tertiary)
    }

    private var approveInfoDescriptionView: some View {
        Text(viewModel.approveInfoSubtitle())
            .environment(\.openURL, OpenURLAction { _ in
                viewModel.didTapLearnMore()
                return .handled
            })
            .multilineTextAlignment(.leading)
    }
}

struct ExpressApproveView_Preview: PreviewProvider {
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
                        ExpressApproveView(viewModel: $0)
                    }
            }
        }
    }

    class BottomSheetCoordinator: ObservableObject, ExpressApproveRoutable {
        @Published var item: ExpressApproveViewModel?

        func toggleItem() {
            if item == nil {
                item = ExpressModulesFactoryMock().makeExpressApproveViewModel(
                    source: ExpressInteractorWalletModelWrapper(
                        userWalletInfo: UserWalletModelMock().userWalletInfo,
                        walletModel: CommonWalletModel.mockETH,
                        expressOperationType: .swap,
                    ),
                    providerName: "1inch",
                    selectedPolicy: .unlimited,
                    coordinator: self
                )
            } else {
                item = nil
            }
        }

        func didSendApproveTransaction() {
            item = nil
        }

        func userDidCancel() {
            item = nil
        }

        func openLearnMore() {}
    }

    static var previews: some View {
        StatableContainer()
            .preferredColorScheme(.light)

        StatableContainer()
            .preferredColorScheme(.dark)
    }
}
