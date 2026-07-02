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

@available(iOS 17.0, *)
#Preview("Interactive") {
    final class PreviewBalanceDataProvider: TokenDetailsBalanceDataProvider {
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

    enum PreviewBalanceState: String, CaseIterable, Identifiable {
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

    @Previewable @State var fiatState = PreviewBalanceState.loaded
    @Previewable @State var cryptoState = PreviewBalanceState.loaded
    @Previewable @State var isCustomToken = false

    // Stored as @State so the reference survives SwiftUI re-renders of the struct
    @Previewable @State var dataProvider = PreviewBalanceDataProvider()

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
                ForEach(State.allCases) { state in
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

            TokenDetailsBalanceView(
                viewModel: TokenDetailsBalanceViewModel(
                    tokenItem: TokenItem.blockchain(.init(.bitcoin(testnet: false), derivationPath: nil)),
                    dataProvider: dataProvider,
                    reloadBalance: {}
                )
            )
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}
