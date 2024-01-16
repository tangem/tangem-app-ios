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
        .alert(item: $viewModel.errorAlert) { $0.alert }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .trailing) {
                Text(Localization.swappingPermissionHeader)
                    .style(Fonts.Bold.callout, color: Colors.Text.primary1)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                Button(action: viewModel.didTapInfoButton) {
                    Assets.infoIconMini.image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.informative)
                        .padding(.horizontal, 16)
                }
            }

            Text(viewModel.subheader)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .padding(.horizontal, 50)
                .multilineTextAlignment(.center)
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
    static let viewModel = ExpressModulesFactoryMock().makeExpressApproveViewModel(coordinator: ExpressApproveRoutableMock())

    static var previews: some View {
        ExpressApproveView(viewModel: viewModel)
    }
}
