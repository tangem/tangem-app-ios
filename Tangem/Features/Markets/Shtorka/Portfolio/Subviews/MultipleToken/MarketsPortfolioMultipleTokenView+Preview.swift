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

// MARK: - Previews

#if DEBUG

private enum PreviewMultipleBalanceState: String, CaseIterable, Identifiable {
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

private final class PreviewMultiplePublishers {
    // Two token slots simulating two accounts
    let fiat1 = CurrentValueSubject<TokenBalanceType, Never>(.loaded(987.65))
    let fiat2 = CurrentValueSubject<TokenBalanceType, Never>(.loaded(246.91))
    let crypto1 = CurrentValueSubject<TokenBalanceType, Never>(.loaded(0.0102))
    let crypto2 = CurrentValueSubject<TokenBalanceType, Never>(.loaded(0.0026))
}

private struct MarketsPortfolioMultipleTokenInteractivePreview: View {
    @State private var fiatState1: PreviewMultipleBalanceState = .loaded
    @State private var fiatState2: PreviewMultipleBalanceState = .loaded
    @State private var cryptoState1: PreviewMultipleBalanceState = .loaded
    @State private var cryptoState2: PreviewMultipleBalanceState = .loaded
    @State private var isCustomToken: Bool = false

    /// Stored as @State so the reference survives SwiftUI re-renders of the struct
    @State private var publishers = PreviewMultiplePublishers()

    private static let tokenItem = TokenItem.blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))

    private var tokenInfo: MarketsPortfolioMultipleTokenViewModel.TokenInfo {
        MarketsPortfolioMultipleTokenViewModel.TokenInfo(
            name: "Bitcoin",
            count: 2,
            currencyCode: "BTC",
            iconInfo: TokenIconInfoBuilder().build(from: Self.tokenItem, isCustom: isCustomToken)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                previewPicker(title: "Fiat #1", selection: $fiatState1) { newState in
                    publishers.fiat1.send(newState.toTokenBalanceType(value: 987.65))
                }

                previewPicker(title: "Fiat #2", selection: $fiatState2) { newState in
                    publishers.fiat2.send(newState.toTokenBalanceType(value: 246.91))
                }

                previewPicker(title: "Crypto #1", selection: $cryptoState1) { newState in
                    publishers.crypto1.send(newState.toTokenBalanceType(value: 0.0102))
                }

                previewPicker(title: "Crypto #2", selection: $cryptoState2) { newState in
                    publishers.crypto2.send(newState.toTokenBalanceType(value: 0.0026))
                }

                previewToggle(title: "isCustom", isOn: $isCustomToken)

                previewToggle(title: "Balance hidden", isOn: .init(
                    get: { SensitiveTextVisibilityState.shared.isHidden },
                    set: { SensitiveTextVisibilityState.shared.isHidden = $0 }
                ))

                PreviewMultipleTokenContent(publishers: publishers, tokenInfo: tokenInfo)
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

private struct PreviewMultipleTokenContent: View {
    @StateObject var viewModel: MarketsPortfolioMultipleTokenViewModel

    init(publishers: PreviewMultiplePublishers, tokenInfo: MarketsPortfolioMultipleTokenViewModel.TokenInfo) {
        _viewModel = StateObject(wrappedValue: MarketsPortfolioMultipleTokenViewModel(
            tokenInfo: tokenInfo,
            fiatTotalTokenBalancePublishers: [
                publishers.fiat1.eraseToAnyPublisher(),
                publishers.fiat2.eraseToAnyPublisher(),
            ],
            cryptoTotalTokenBalancePublishers: [
                publishers.crypto1.eraseToAnyPublisher(),
                publishers.crypto2.eraseToAnyPublisher(),
            ],
            onTapAction: {}
        ))
    }

    var body: some View {
        MarketsPortfolioMultipleTokenView(viewModel: viewModel)
    }
}

struct MarketsPortfolioMultipleTokenView_Previews: PreviewProvider {
    static var previews: some View {
        MarketsPortfolioMultipleTokenInteractivePreview()
            .previewDisplayName("Interactive")
    }
}

#endif // DEBUG
