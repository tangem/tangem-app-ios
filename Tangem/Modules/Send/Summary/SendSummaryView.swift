//
//  SendSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendSummaryView: View {
    let height = 150.0
    let namespace: Namespace.ID

    @ObservedObject var viewModel: SendSummaryViewModel

    var body: some View {
        VStack(spacing: 20) {
            amountSummary

            destinationSummary
            feeSummary

            Spacer()

            sendButton
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var amountSummary: some View {
        Button {
            viewModel.didTapSummary(for: .amount)
        } label: {
            Color.clear
                .frame(maxHeight: height)
                .border(Color.green, width: 5)
                .overlay(
                    VStack {
                        HStack {
                            Text(viewModel.amountText)
                                .foregroundColor(.black)
                            Spacer()
                        }
                    }
                    .padding()
                )
                .matchedGeometryEffect(id: "amount", in: namespace)
        }
        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale)))
        .disabled(!viewModel.canEditAmount)
    }

    @ViewBuilder
    private var destinationSummary: some View {
        Button {
            viewModel.didTapSummary(for: .destination)
        } label: {
            Color.clear
                .frame(maxHeight: height)
                .border(Color.purple, width: 5)
                .overlay(
                    VStack(alignment: .leading) {
                        HStack {
                            Text(viewModel.destinationText)
                                .lineLimit(1)
                                .foregroundColor(.black)
                            Spacer()
                        }
                    }
                    .padding()
                )
                .matchedGeometryEffect(id: "dest", in: namespace)
        }
        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale).combined(with: .offset(y: -height - 20))))
        .disabled(!viewModel.canEditDestination)
    }

    @ViewBuilder
    private var feeSummary: some View {
        Button {
            viewModel.didTapSummary(for: .fee)
        } label: {
            Color.clear
                .frame(maxHeight: height)
                .border(Color.blue, width: 5)
                .overlay(
                    VStack(alignment: .leading) {
                        HStack {
                            Text(viewModel.feeText)
                                .foregroundColor(.black)
                            Spacer()
                        }
                    }
                    .padding()
                )
                .transition(.identity)
                .matchedGeometryEffect(id: "fee", in: namespace)
        }
    }

    @ViewBuilder
    private var sendButton: some View {
        MainButton(
            title: Localization.commonSend,
            icon: .trailing(Assets.tangemIcon),
            isLoading: viewModel.isSending,
            action: viewModel.send
        )
    }
}

struct SendSummaryView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        SendSummaryView(namespace: namespace, viewModel: SendSummaryViewModel(input: SendSummaryViewModelInputMock()))
    }
}
