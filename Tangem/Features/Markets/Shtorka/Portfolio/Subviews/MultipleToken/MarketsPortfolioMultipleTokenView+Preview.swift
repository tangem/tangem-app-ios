//
//  MarketsPortfolioMultipleTokenView+Preview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemUI

@available(iOS 17.0, *)
#Preview("Interactive") {
    enum PreviewMultipleBalanceState: String, CaseIterable, Identifiable {
        case loaded = "Loaded"
        case loadingNoCache = "Loading"
        case loadingCached = "Loading (cached)"
        case failureNoCache = "Failure"
        case failureCached = "Failure (cached)"

        var id: String { rawValue }

        func toTokenBalanceType(value: Decimal) -> TokenBalanceType {
            switch self {
            case .loaded: return .loaded(value)
            case .loadingNoCache: return .loading(nil)
            case .loadingCached: return .loading(.init(balance: value, date: .now))
            case .failureNoCache: return .failure(nil)
            case .failureCached: return .failure(.init(balance: value, date: .now))
            }
        }
    }

    enum PreviewMultiplePublishers {
        // Two token slots simulating two accounts
        static let fiat1 = CurrentValueSubject<TokenBalanceType, Never>(.loaded(987.65))
        static let fiat2 = CurrentValueSubject<TokenBalanceType, Never>(.loaded(246.91))
        static let crypto1 = CurrentValueSubject<TokenBalanceType, Never>(.loaded(0.0102))
        static let crypto2 = CurrentValueSubject<TokenBalanceType, Never>(.loaded(0.0026))
    }

    @Previewable @State var fiatState1 = PreviewMultipleBalanceState.loaded
    @Previewable @State var fiatState2 = PreviewMultipleBalanceState.loaded
    @Previewable @State var cryptoState1 = PreviewMultipleBalanceState.loaded
    @Previewable @State var cryptoState2 = PreviewMultipleBalanceState.loaded
    @Previewable @State var isCustomToken = false

    func previewToggle(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text("\(title): \(isOn.wrappedValue ? "true" : "false")")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Toggle(title, isOn: isOn)
                .labelsHidden()
        }
    }

    func previewPicker(
        title: String,
        selection: Binding<PreviewMultipleBalanceState>,
        onChange: @escaping (PreviewMultipleBalanceState) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("· \(selection.wrappedValue.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Picker(title, selection: selection) {
                ForEach(PreviewMultipleBalanceState.allCases) { state in
                    Text(state.rawValue).tag(state)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selection.wrappedValue, perform: onChange)
        }
    }

    return ScrollView {
        VStack(spacing: 16) {
            previewPicker(title: "Fiat #1", selection: $fiatState1) { newState in
                PreviewMultiplePublishers.fiat1.send(newState.toTokenBalanceType(value: 987.65))
            }

            previewPicker(title: "Fiat #2", selection: $fiatState2) { newState in
                PreviewMultiplePublishers.fiat2.send(newState.toTokenBalanceType(value: 246.91))
            }

            previewPicker(title: "Crypto #1", selection: $cryptoState1) { newState in
                PreviewMultiplePublishers.crypto1.send(newState.toTokenBalanceType(value: 0.0102))
            }

            previewPicker(title: "Crypto #2", selection: $cryptoState2) { newState in
                PreviewMultiplePublishers.crypto2.send(newState.toTokenBalanceType(value: 0.0026))
            }

            previewToggle(title: "isCustom", isOn: $isCustomToken)

            previewToggle(
                title: "Balance hidden",
                isOn: .init(
                    get: { SensitiveTextVisibilityState.shared.isHidden },
                    set: { SensitiveTextVisibilityState.shared.isHidden = $0 }
                )
            )

            MarketsPortfolioMultipleTokenView(
                viewModel: MarketsPortfolioMultipleTokenViewModel(
                    tokenInfo: MarketsPortfolioMultipleTokenViewModel.TokenInfo(
                        name: "Bitcoin",
                        count: 2,
                        currencyCode: "BTC",
                        iconInfo: TokenIconInfoBuilder().build(
                            from: TokenItem.blockchain(.init(.bitcoin(testnet: false), derivationPath: nil)),
                            isCustom: isCustomToken
                        )
                    ),
                    fiatTotalTokenBalancePublishers: [
                        PreviewMultiplePublishers.fiat1.eraseToAnyPublisher(),
                        PreviewMultiplePublishers.fiat2.eraseToAnyPublisher(),
                    ],
                    cryptoTotalTokenBalancePublishers: [
                        PreviewMultiplePublishers.crypto1.eraseToAnyPublisher(),
                        PreviewMultiplePublishers.crypto2.eraseToAnyPublisher(),
                    ],
                    onTapAction: {}
                )
            )
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}
