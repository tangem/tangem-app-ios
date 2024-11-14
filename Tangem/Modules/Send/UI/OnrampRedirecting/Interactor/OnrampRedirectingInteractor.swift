//
//  OnrampRedirectingInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol OnrampRedirectingInteractor {
    var onrampProvider: OnrampProvider? { get }

    func loadRedirectData() async throws
}

class CommonOnrampRedirectingInteractor {
    private weak var input: OnrampRedirectingInput?
    private weak var output: OnrampRedirectingOutput?

    private let onrampManager: OnrampManager

    init(
        input: OnrampRedirectingInput,
        output: OnrampRedirectingOutput,
        onrampManager: OnrampManager
    ) {
        self.input = input
        self.output = output
        self.onrampManager = onrampManager
    }
}

// MARK: - OnrampRedirectingInteractor

extension CommonOnrampRedirectingInteractor: OnrampRedirectingInteractor {
    var onrampProvider: TangemExpress.OnrampProvider? {
        input?.selectedOnrampProvider
    }

    func loadRedirectData() async throws {
        guard let provider = input?.selectedOnrampProvider else {
            throw CommonError.noData
        }

        // [REDACTED_TODO_COMMENT]
        let redirectSettings = OnrampRedirectSettings(
            successURL: IncomingActionConstants.externalSuccessURL,
            theme: "light",
            language: "en"
        )

        let redirectData = try await onrampManager.loadRedirectData(provider: provider, redirectSettings: redirectSettings)
        output?.redirectDataDidLoad(data: redirectData)
    }
}
