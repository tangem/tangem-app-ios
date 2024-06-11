//
//  SendDestinationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendDestinationView: View {
    @ObservedObject var viewModel: SendDestinationViewModel
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 20) {
            GroupedSection(viewModel.addressViewModel) {
                SendDestinationTextView(viewModel: $0)
                    .setNamespace(namespace)
                    .setContainerNamespaceId(SendViewNamespaceId.addressContainer.rawValue)
                    .setTitleNamespaceId(SendViewNamespaceId.addressTitle.rawValue)
                    .setIconNamespaceId(SendViewNamespaceId.addressIcon.rawValue)
                    .setTextNamespaceId(SendViewNamespaceId.addressText.rawValue)
                    .setClearButtonNamespaceId(SendViewNamespaceId.addressClearButton.rawValue)
            } footer: {
                if !viewModel.animatingAuxiliaryViewsOnAppear, let viewModel = viewModel.addressViewModel {
                    Text(viewModel.description)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                        .transition(SendView.Constants.auxiliaryViewTransition(for: .destination))
                }
            }
            .backgroundColor(Colors.Background.action)
            .geometryEffect(.init(
                id: SendViewNamespaceId.addressBackground.rawValue,
                namespace: namespace
            ))

            GroupedSection(viewModel.additionalFieldViewModel) {
                SendDestinationTextView(viewModel: $0)
                    .setNamespace(namespace)
                    .setContainerNamespaceId(SendViewNamespaceId.addressAdditionalFieldContainer.rawValue)
                    .setTitleNamespaceId(SendViewNamespaceId.addressAdditionalFieldTitle.rawValue)
                    .setIconNamespaceId(SendViewNamespaceId.addressAdditionalFieldIcon.rawValue)
                    .setTextNamespaceId(SendViewNamespaceId.addressAdditionalFieldText.rawValue)
                    .setClearButtonNamespaceId(SendViewNamespaceId.addressAdditionalFieldClearButton.rawValue)
                    .padding(.vertical, 2)
            } footer: {
                if let additionalFieldViewModel = viewModel.additionalFieldViewModel, !viewModel.animatingAuxiliaryViewsOnAppear {
                    Text(additionalFieldViewModel.description)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                        .transition(SendView.Constants.auxiliaryViewTransition(for: .destination))
                }
            }
            .backgroundColor(Colors.Background.action)
            .geometryEffect(.init(
                id: SendViewNamespaceId.addressAdditionalFieldBackground.rawValue,
                namespace: namespace
            ))

            if let suggestedDestinationViewModel = viewModel.suggestedDestinationViewModel {
                SendSuggestedDestinationView(viewModel: suggestedDestinationViewModel)
                    .transition(.opacity)
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onAppear(perform: viewModel.onAuxiliaryViewAppear)
        .onDisappear(perform: viewModel.onAuxiliaryViewDisappear)
    }
}

struct SendDestinationView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        SendDestinationView(
            viewModel: SendDestinationViewModel(
                input: SendDestinationViewModelInputMock(),
                addressTextViewHeightModel: .init()
            ),
            namespace: namespace
        )
    }
}
