//
//  SilentPushTesterView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct SilentPushTesterView: View {
    @ObservedObject var viewModel: SilentPushTesterViewModel

    var body: some View {
        Form {
            Section("Payload") {
                labeledField("user_wallet_id", text: $viewModel.userWalletId)
                labeledField("network_id", text: $viewModel.networkId)
                labeledField("token_id", text: $viewModel.tokenId)
                labeledField("derivation_path", text: $viewModel.derivationPath)

                Picker("type", selection: $viewModel.selectedType) {
                    ForEach(viewModel.types, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }

            Section("Preset") {
                Button("Fill from current wallet/token") {
                    viewModel.fillFromCurrentWallet()
                }
            }

            Section("Scenario") {
                Picker("Scenario", selection: $viewModel.scenario) {
                    ForEach(SilentPushTesterViewModel.Scenario.allCases) { scenario in
                        Text(scenario.rawValue).tag(scenario)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Button("Send (silent, foreground refresh)") {
                    viewModel.sendAsSilentPush()
                }

                Button("Send as tap (navigation)") {
                    viewModel.sendAsTap()
                }
            }

            if !viewModel.lastResultMessage.isEmpty {
                Section("Result") {
                    Text(viewModel.lastResultMessage)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Silent Push Tester")
    }

    private func labeledField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField(title, text: text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }
}
