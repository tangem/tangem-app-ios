//
//  AttentionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct AttentionView: View {
    @ObservedObject private var viewModel: AttentionViewModel

    init(viewModel: AttentionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center, spacing: 0) {
                ZStack {
                    Assets.attentionBg

                    Assets.attentionRed
                        .offset(y: 30)
                }
                .padding(.bottom, 40)

                mainInformationView

                Spacer(minLength: 0)

                VStack(spacing: 22) {
                    agreeView

                    actionButton
                }
            }
            .edgesIgnoringSafeArea(.top)
            .padding(.bottom, 16)
        }
        .navigationBarTitle(Text(viewModel.navigationTitle), displayMode: .inline)
    }

    private var mainInformationView: some View {
        VStack(alignment: .center, spacing: 14) {
            Text(viewModel.title)
                .style(font: .title1(.bold), color: Colors.Text.primary1)

            Text(viewModel.message)
                .style(font: .callout(), color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 46)
        }
    }

    @ViewBuilder
    private var agreeView: some View {
        if let warningText = viewModel.warningText {
            Button {
                viewModel.isWarningChecked.toggle()
            } label: {
                HStack(spacing: 18) {
                    circleImage
                        .resizable()
                        .frame(width: 22, height: 22)

                    Text(warningText)
                        .style(font: .caption1(), color: Colors.Text.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var circleImage: Image {
        viewModel.isWarningChecked ? Assets.circleChecked : Assets.circleEmpty
    }

    private var actionButton: some View {
        TangemButton(title: viewModel.buttonTitle, image: "tangemIcon", iconPosition: .trailing) {
            viewModel.mainButtonAction()
        }
        .buttonStyle(TangemButtonStyle(
            colorStyle: .black,
            layout: .flexibleWidth,
            isDisabled: !viewModel.isWarningChecked
        ))
        .padding(.horizontal, 16)
    }
}

struct AttentionView_Previews: PreviewProvider {
    static let viewModel = AttentionViewModel(
        isWarningChecked: false,
        navigationTitle: "Reset to factory settings",
        title: "Attention",
        message: "This action will lead to the complete removal of the wallet from the selected card and it will not be possible to restore the current wallet on it or use the card to recover the password",
        warningText: "I understand that after performing this action, I will no longer have access to the current wallet",
        buttonTitle: "Reset the card",
        mainButtonAction: {}
    )

    static var previews: some View {
        NavigationView {
            AttentionView(viewModel: viewModel)
        }
        .deviceForPreview(.iPhone12Pro)
    }
}
