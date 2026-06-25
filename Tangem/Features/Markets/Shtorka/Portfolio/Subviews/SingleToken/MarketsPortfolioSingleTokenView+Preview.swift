//
//  MarketsPortfolioSingleTokenView+Preview.swift
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
    enum PreviewPublishers {
        static let fiat = CurrentValueSubject<TokenBalanceType, Never>(.loaded(1234.56))
        static let crypto = CurrentValueSubject<TokenBalanceType, Never>(.loaded(0.0128))
        static let rate = CurrentValueSubject<WalletModelRate, Never>(
            .loaded(
                quote: .init(
                    currencyId: "bitcoin",
                    price: 96_000,
                    priceUsd: 96_000,
                    priceChange24h: 2.3,
                    priceChange7d: nil,
                    priceChange30d: nil,
                    currencyCode: "USD"
                )
            )
        )
    }

    enum PreviewRateState: String, CaseIterable, Identifiable {
        case loaded = "Loaded"
        case loading = "Loading"
        case loadingCached = "Loading (cached)"
        case failure = "Failure"
        case failureCached = "Failure (cached)"
        case custom = "Custom"

        var id: String { rawValue }

        private static let quote = TokenQuote(
            currencyId: "bitcoin",
            price: 96_000,
            priceUsd: 96_000,
            priceChange24h: 2.3,
            priceChange7d: nil,
            priceChange30d: nil,
            currencyCode: "USD"
        )

        func toWalletModelRate() -> WalletModelRate {
            switch self {
            case .loaded: return .loaded(quote: Self.quote)
            case .loading: return .loading(cached: nil)
            case .loadingCached: return .loading(cached: Self.quote)
            case .failure: return .failure(cached: nil)
            case .failureCached: return .failure(cached: Self.quote)
            case .custom: return .custom
            }
        }
    }

    enum PreviewBalanceState: String, CaseIterable, Identifiable {
        case loaded = "Loaded"
        case loadingNoCache = "Loading"
        case loadingCached = "Loading (cached)"
        case failureNoCache = "Failure"
        case failureCached = "Failure (cached)"

        var id: String { rawValue }

        func toTokenBalanceType(fiatValue: Decimal, cryptoValue: Decimal, isFiat: Bool) -> TokenBalanceType {
            let value = isFiat ? fiatValue : cryptoValue
            switch self {
            case .loaded: return .loaded(value)
            case .loadingNoCache: return .loading(nil)
            case .loadingCached: return .loading(.init(balance: value, date: .now))
            case .failureNoCache: return .failure(nil)
            case .failureCached: return .failure(.init(balance: value, date: .now))
            }
        }
    }

    @Previewable @State var fiatState = PreviewBalanceState.loaded
    @Previewable @State var cryptoState = PreviewBalanceState.loaded
    @Previewable @State var rateState = PreviewRateState.loaded
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

    func previewPicker<State: RawRepresentable & CaseIterable & Hashable & Identifiable>(
        title: String,
        selection: Binding<State>,
        onChange: @escaping (State) -> Void
    ) -> some View where State.RawValue == String, State.AllCases: RandomAccessCollection {
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
                ForEach(PreviewBalanceState.allCases) { state in
                    Text(state.rawValue).tag(state)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selection.wrappedValue, perform: onChange)
        }
    }

    return ScrollView {
        VStack(spacing: 16) {
            previewPicker(title: "Fiat", selection: $fiatState) { newState in
                PreviewPublishers.fiat.send(newState.toTokenBalanceType(fiatValue: 1234.56, cryptoValue: 0.0128, isFiat: true))
            }

            previewPicker(title: "Crypto", selection: $cryptoState) { newState in
                PreviewPublishers.crypto.send(newState.toTokenBalanceType(fiatValue: 1234.56, cryptoValue: 0.0128, isFiat: false))
            }

            previewPicker(title: "Rate", selection: $rateState) { newState in
                PreviewPublishers.rate.send(newState.toWalletModelRate())
            }

            previewToggle(title: "isCustom", isOn: $isCustomToken)

            previewToggle(
                title: "Balance hidden",
                isOn: .init(
                    get: { SensitiveTextVisibilityState.shared.isHidden },
                    set: { SensitiveTextVisibilityState.shared.isHidden = $0 }
                )
            )

            MarketsPortfolioSingleTokenView(
                viewModel: MarketsPortfolioSingleTokenViewModel(
                    tokenInfo: MarketsPortfolioSingleTokenViewModel.TokenInfo(
                        name: "Bitcoin",
                        currencyCode: "BTC",
                        iconInfo: TokenIconInfoBuilder().build(
                            from: TokenItem.blockchain(.init(.bitcoin(testnet: false), derivationPath: nil)),
                            isCustom: isCustomToken
                        )
                    ),
                    ratePublisher: PreviewPublishers.rate.eraseToAnyPublisher(),
                    fiatTotalTokenBalancePublisher: PreviewPublishers.fiat.eraseToAnyPublisher(),
                    cryptoTotalTokenBalancePublisher: PreviewPublishers.crypto.eraseToAnyPublisher(),
                    onTapAction: {}
                )
            )
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}
