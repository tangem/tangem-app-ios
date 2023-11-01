//
//  SendSummaryView.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct SendSummaryView: View {
    let height = 150.0
    let namespace: Namespace.ID

    let viewModel: SendSummaryViewModel

    var body: some View {
        VStack(spacing: 20) {
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

            Spacer()

            Button(action: viewModel.send) {
                Text("Send")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}

private enum PreviewData {
    @Namespace static var namespace
}

#Preview {
    SendSummaryView(namespace: PreviewData.namespace, viewModel: SendSummaryViewModel(input: SendSummaryViewModelInputMock(), router: SendSummaryRoutableMock()))
}
