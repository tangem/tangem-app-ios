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

// MARK: - Previews

#if DEBUG

private enum PreviewBalanceState: String, CaseIterable, Identifiable {
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

private enum PreviewRateState: String, CaseIterable, Identifiable {
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

private final class PreviewPublishers {
    let fiat = CurrentValueSubject<TokenBalanceType, Never>(.loaded(1234.56))
    let crypto = CurrentValueSubject<TokenBalanceType, Never>(.loaded(0.0128))
    let rate = CurrentValueSubject<WalletModelRate, Never>(.loaded(quote: .init(
        currencyId: "bitcoin",
        price: 96_000,
        priceUsd: 96_000,
        priceChange24h: 2.3,
        priceChange7d: nil,
        priceChange30d: nil,
        currencyCode: "USD"
    )))
}

private struct MarketsPortfolioSingleTokenInteractivePreview: View {
    @State private var fiatState: PreviewBalanceState = .loaded
    @State private var cryptoState: PreviewBalanceState = .loaded
    @State private var rateState: PreviewRateState = .loaded
    @State private var isCustomToken: Bool = false

    /// Stored as @State so the reference survives SwiftUI re-renders of the struct
    @State private var publishers = PreviewPublishers()

    private static let tokenItem = TokenItem.blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))

    private var tokenInfo: MarketsPortfolioSingleTokenViewModel.TokenInfo {
        MarketsPortfolioSingleTokenViewModel.TokenInfo(
            name: "Bitcoin",
            currencyCode: "BTC",
            iconInfo: TokenIconInfoBuilder().build(from: Self.tokenItem, isCustom: isCustomToken)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                previewPicker(title: "Fiat", selection: $fiatState) { newState in
                    publishers.fiat.send(newState.toTokenBalanceType(fiatValue: 1234.56, cryptoValue: 0.0128, isFiat: true))
                }

                previewPicker(title: "Crypto", selection: $cryptoState) { newState in
                    publishers.crypto.send(newState.toTokenBalanceType(fiatValue: 1234.56, cryptoValue: 0.0128, isFiat: false))
                }

                previewPicker(title: "Rate", selection: $rateState) { newState in
                    publishers.rate.send(newState.toWalletModelRate())
                }

                previewToggle(title: "isCustom", isOn: $isCustomToken)

                previewToggle(title: "Balance hidden", isOn: .init(
                    get: { SensitiveTextVisibilityState.shared.isHidden },
                    set: { SensitiveTextVisibilityState.shared.isHidden = $0 }
                ))

                PreviewSingleTokenContent(publishers: publishers, tokenInfo: tokenInfo)
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
    }

    @ViewBuilder
    private func previewToggle(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text("\(title): \(isOn.wrappedValue ? "true" : "false")")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Toggle(title, isOn: isOn)
                .labelsHidden()
        }
    }

    @ViewBuilder
    private func previewPicker<State: RawRepresentable & CaseIterable & Hashable & Identifiable>(
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
                ForEach(State.allCases) { state in
                    Text(state.rawValue).tag(state)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selection.wrappedValue, perform: onChange)
        }
    }
}

private struct PreviewSingleTokenContent: View {
    @StateObject var viewModel: MarketsPortfolioSingleTokenViewModel

    init(publishers: PreviewPublishers, tokenInfo: MarketsPortfolioSingleTokenViewModel.TokenInfo) {
        _viewModel = StateObject(wrappedValue: MarketsPortfolioSingleTokenViewModel(
            tokenInfo: tokenInfo,
            ratePublisher: publishers.rate.eraseToAnyPublisher(),
            fiatTotalTokenBalancePublisher: publishers.fiat.eraseToAnyPublisher(),
            cryptoTotalTokenBalancePublisher: publishers.crypto.eraseToAnyPublisher(),
            onTapAction: {}
        ))
    }

    var body: some View {
        MarketsPortfolioSingleTokenView(viewModel: viewModel)
    }
}

struct MarketsPortfolioSingleTokenView_Previews: PreviewProvider {
    static var previews: some View {
        MarketsPortfolioSingleTokenInteractivePreview()
            .previewDisplayName("Interactive")
    }
}

#endif // DEBUG
