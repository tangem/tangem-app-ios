//
//  ResetToFactoryAttentionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ResetToFactoryAttentionView: View {
    @ObservedObject private var viewModel: ResetToFactoryAttentionViewModel

    init(viewModel: ResetToFactoryAttentionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center, spacing: 0) {
                ZStack {
                    Assets.attentionBg
                        .resizable()
                        .fixedSize(horizontal: false, vertical: true)

                    Assets.attentionRed
                        .offset(y: 30)
                }
                .frame(
                    minWidth: geometry.size.width,
                    maxHeight: geometry.size.height * 0.5,
                    alignment: .bottom
                )

                informationViews
            }
        }
        .edgesIgnoringSafeArea(.top)
        .padding(.bottom, 16)
        .navigationBarTitle(Text(viewModel.navigationTitle), displayMode: .inline)
        .actionSheet(item: $viewModel.actionSheet) { $0.sheet }
    }

    private var informationViews: some View {
        VStack {
            Spacer()

            mainInformationView
                .layoutPriority(1)

            Spacer()

            actionButton
                .layoutPriority(1)
        }
    }

    private var mainInformationView: some View {
        VStack(alignment: .center, spacing: 14) {
            Text(viewModel.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(viewModel.message)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }


    private var actionButton: some View {
        MainButton(
            title: viewModel.buttonTitle,
            icon: .trailing(Assets.tangemIcon),
            isDisabled: !viewModel.isWarningChecked,
            action: viewModel.mainButtonAction
        )
        .padding(.horizontal, 16)
    }
}

struct ResetToFactoryAttentionView_Previews: PreviewProvider {
    static let viewModel = ResetToFactoryAttentionViewModel(
        navigationTitle: "Reset to factory settings",
        title: "Attention",
        message: "This action will lead to the complete removal of the wallet from the selected card and it will not be possible to restore the current wallet on it or use the card to recover the password",
        warningText: "I understand that after performing this action, I will no longer have access to the current wallet",
        buttonTitle: "Reset the card",
        resetToFactoryAction: {}
    )

    static var previews: some View {
        NavigationView {
            ResetToFactoryAttentionView(viewModel: viewModel)
        }
        .previewGroup(withZoomed: false)
    }
}
