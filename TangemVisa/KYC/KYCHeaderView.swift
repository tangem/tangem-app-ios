//
//  KYCHeaderView.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

// [REDACTED_TODO_COMMENT]
// [REDACTED_INFO]
struct KYCHeaderView: View {
    let stepPublisher: AnyPublisher<KYCStep, Never>
    let back: () -> Void
    let close: () -> Void

    @State private var step: KYCStep = .status

    var body: some View {
        HStack {
            Button(
                shouldHideBackButton ? "Close" : "Back",
                action: shouldHideBackButton ? close : back
            )

            Spacer()

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)

            Spacer()

            Button("Close", action: close)
                .opacity(shouldHideBackButton ? 0 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onReceive(stepPublisher) { step in
            self.step = step
        }
    }

    private var title: String {
        switch step {
        case .status:
            "Account verification"
        case .agreementSelector:
            "Country of residence"
        case .questionnaire:
            "Personal information"
        case .docTypeSelector:
            "Upload document"
        case .liveness:
            "Liveness check"
        }
    }

    private var shouldHideBackButton: Bool {
        switch step {
        case .status, .agreementSelector:
            true
        default:
            false
        }
    }
}
