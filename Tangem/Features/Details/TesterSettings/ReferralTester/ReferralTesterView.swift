//
//  ReferralTesterView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReferralTesterView: View {
    @ObservedObject var viewModel: ReferralTesterViewModel

    var body: some View {
        Form {
            Section("Current state") {
                stateRow("refcode", value: viewModel.currentRefcode)
                stateRow("promo active", value: viewModel.isPromoActive ? "yes" : "no")
            }

            Section("Referral deep link") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("refcode (deep_link_sub1)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("refcode", text: $viewModel.refcode)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Button("Simulate referral deep link") {
                    viewModel.simulateReferralDeepLink()
                }
            }

            Section {
                Button("Clear referral", role: .destructive) {
                    viewModel.clearReferral()
                }
            } footer: {
                Text(
                    """
                    Saves the referral attribute locally, exactly as the AppsFlyer handler would. \
                    Restart the app on a wallet-less state to reach the Welcome flow — stories are \
                    skipped while a referral is present.
                    """
                )
            }
        }
        .navigationTitle("Referral Tester")
    }

    private func stateRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
        }
        .font(.footnote)
    }
}

// MARK: - Previews

#if DEBUG
struct ReferralTesterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ReferralTesterView(viewModel: ReferralTesterViewModel())
        }
    }
}
#endif // DEBUG
