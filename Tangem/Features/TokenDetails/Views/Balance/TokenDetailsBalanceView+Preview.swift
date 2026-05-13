//
//  TokenDetailsBalanceView+Preview.swift
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

private struct TokenDetailsBalanceInteractivePreview: View {
    @State private var fiatState: PreviewBalanceState = .loaded
    @State private var cryptoState: PreviewBalanceState = .loaded
    @State private var isCustomToken: Bool = false

    /// Stored as @State so the reference survives SwiftUI re-renders of the struct
    @State private var dataProvider = PreviewBalanceDataProvider()

    private static let tokenItem = TokenItem.blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                previewPicker(title: "Fiat", selection: $fiatState) { newState in
                    dataProvider.totalFiat.send(newState.toFormattedTokenBalanceType(value: "$1,234.56"))
                    dataProvider.availableFiat.send(newState.toFormattedTokenBalanceType(value: "$1,100.00"))
                }

                previewPicker(title: "Crypto", selection: $cryptoState) { newState in
                    dataProvider.totalCrypto.send(newState.toFormattedTokenBalanceType(value: "0.0128 BTC"))
                    dataProvider.availableCrypto.send(newState.toFormattedTokenBalanceType(value: "0.0114 BTC"))
                }

                previewToggle(title: "isCustom", isOn: $isCustomToken)

                previewToggle(title: "Balance hidden", isOn: .init(
                    get: { SensitiveTextVisibilityState.shared.isHidden },
                    set: { SensitiveTextVisibilityState.shared.isHidden = $0 }
                ))

                PreviewTokenDetailsBalanceContent(
                    tokenItem: Self.tokenItem,
                    isCustomToken: isCustomToken,
                    dataProvider: dataProvider
                )
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

private struct PreviewTokenDetailsBalanceContent: View {
    let tokenItem: TokenItem
    let isCustomToken: Bool
    let dataProvider: PreviewBalanceDataProvider

    @StateObject var viewModel: TokenDetailsBalanceViewModel

    init(tokenItem: TokenItem, isCustomToken: Bool, dataProvider: PreviewBalanceDataProvider) {
        self.tokenItem = tokenItem
        self.isCustomToken = isCustomToken
        self.dataProvider = dataProvider
        _viewModel = StateObject(wrappedValue: TokenDetailsBalanceViewModel(
            tokenItem: tokenItem,
            dataProvider: dataProvider,
            reloadBalance: {}
        ))
    }

    var body: some View {
        TokenDetailsBalanceView(viewModel: viewModel)
    }
}

private enum PreviewBalanceState: String, CaseIterable, Identifiable {
    case loaded = "Loaded"
    case loadingNoCache = "Loading"
    case loadingCached = "Loading (cached)"
    case failureNoCache = "Failure"
    case failureCached = "Failure (cached)"

    var id: String { rawValue }

    func toFormattedTokenBalanceType(value: String) -> FormattedTokenBalanceType {
        switch self {
        case .loaded:
            return .loaded(value)
        case .loadingNoCache:
            return .loading(.empty("-"))
        case .loadingCached:
            return .loading(.cache(.init(balance: value, date: .now)))
        case .failureNoCache:
            return .failure(.empty("-"))
        case .failureCached:
            return .failure(.cache(.init(balance: value, date: .now)))
        }
    }
}

private final class PreviewBalanceDataProvider: TokenDetailsBalanceDataProvider {
    let totalFiat = CurrentValueSubject<FormattedTokenBalanceType, Never>(.loaded("$1,234.56"))
    let totalCrypto = CurrentValueSubject<FormattedTokenBalanceType, Never>(.loaded("0.0128 BTC"))
    let availableFiat = CurrentValueSubject<FormattedTokenBalanceType, Never>(.loaded("$1,100.00"))
    let availableCrypto = CurrentValueSubject<FormattedTokenBalanceType, Never>(.loaded("0.0114 BTC"))

    var totalCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        totalCrypto.eraseToAnyPublisher()
    }

    var totalFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        totalFiat.eraseToAnyPublisher()
    }

    var availableCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        availableCrypto.eraseToAnyPublisher()
    }

    var availableFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        availableFiat.eraseToAnyPublisher()
    }

    var stakingBalanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        Just(.loaded(1234.56)).eraseToAnyPublisher()
    }

    var yieldModuleState: AnyPublisher<YieldModuleManagerStateInfo, Never> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    var isTokenCustom: Bool { false }
}

struct TokenDetailsBalanceView_Previews: PreviewProvider {
    static var previews: some View {
        TokenDetailsBalanceInteractivePreview()
            .previewDisplayName("Interactive")
    }
}

#endif // DEBUG
