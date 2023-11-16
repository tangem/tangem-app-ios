//
//  SendFinishView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendFinishView: View {
    let height = 150.0
    let namespace: Namespace.ID

    @ObservedObject var viewModel: SendFinishViewModel

    var body: some View {
        VStack(spacing: 20) {
            amountSummary

            destinationSummary
            feeSummary

            Spacer()

            bottomButtons
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var amountSummary: some View {
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
            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale)))
    }

    @ViewBuilder
    private var destinationSummary: some View {
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
            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale).combined(with: .offset(y: -height - 20))))
    }

    @ViewBuilder
    private var feeSummary: some View {
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

    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                MainButton(
                    title: Localization.sendExplore,
                    style: .secondary,
                    action: viewModel.explore
                )
                MainButton(
                    title: Localization.commonShare,
                    style: .secondary,
                    action: viewModel.share
                )
            }

            MainButton(
                title: Localization.commonClose,
                action: viewModel.close
            )
        }
    }
}

struct SendFinishView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        SendFinishView(namespace: namespace, viewModel: SendFinishViewModel(input: SendFinishViewModelInputMock()))
    }
}
