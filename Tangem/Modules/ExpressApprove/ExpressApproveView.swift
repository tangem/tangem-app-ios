//
//  ExpressApproveView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressApproveView: View {
    @ObservedObject private var viewModel: ExpressApproveViewModel

    init(viewModel: ExpressApproveViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 16) {
            headerView

            content

            buttons
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Colors.Background.tertiary)
//        .alert(item: $viewModel.errorAlert) { $0.alert }
    }

    private var headerView: some View {
        ZStack(alignment: .topTrailing) {
            BottomSheetHeaderView(title: Localization.swappingPermissionHeader, subtitle: viewModel.subheader)
                .border(Color.red)
                .padding(.horizontal, 16)
                .border(Color.orange)

            Button(action: viewModel.didTapInfoButton) {
                Assets.infoIconMini.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)
//                    .padding(.horizontal, 16)
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            GroupedSection(viewModel.menuRowViewModel) {
                DefaultMenuRowView(viewModel: $0, selection: $viewModel.selectedAction)
            } footer: {
                DefaultFooterView(Localization.swappingPermissionPolicyTypeFooter)
            }
            .backgroundColor(Colors.Background.action)
            .padding(.horizontal, 16)

            GroupedSection(viewModel.feeRowViewModel) {
                DefaultRowView(viewModel: $0)
            } footer: {
                DefaultFooterView(Localization.swappingPermissionFeeFooter)
            }
            .backgroundColor(Colors.Background.action)
            .padding(.horizontal, 16)
        }
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            MainButton(
                title: Localization.swappingPermissionButtonsApprove,
                icon: .trailing(Assets.tangemIcon),
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.mainButtonIsDisabled,
                action: viewModel.didTapApprove
            )

            MainButton(
                title: Localization.commonCancel,
                style: .secondary,
                action: viewModel.didTapCancel
            )
        }
        // This fix for text's font in the cancel button, it shrink with no reason
        .minimumScaleFactor(1)
        .padding(.horizontal, 16)
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
                item = ExpressMockModulesFactory().makeExpressApproveViewModel(coordinator: self)
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
        
    }

    static var previews: some View {
        StatableContainer()
            .preferredColorScheme(.light)

        StatableContainer()
            .preferredColorScheme(.dark)
    }
}
