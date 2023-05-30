//
//  LearnViewModel.swift
//
//
//  Created by [REDACTED_AUTHOR]
//

import Combine
import SwiftUI

final class LearnViewModel: ObservableObject {
    @Injected(\.keysManager) var keysManager: KeysManager

    // MARK: - ViewState

    var headers: [String: String] {
        var result: [String: String] = [:]
        if let tangemComAuthorization = keysManager.tangemComAuthorization {
            result["Authorization"] = "Basic \(tangemComAuthorization)"
        }
        return result
    }

    var urlActions: [String: (String) -> Void] {
        var result: [String: (String) -> Void] = [:]
        result["https://devweb.tangem.com/promotion-program/ready-for-existed-card-award"] = handleAward
        return result
    }

    let url = URL(string: "https://devweb.tangem.com/promotion-program/")!

    // MARK: - Dependencies

    private unowned let coordinator: LearnRoutable

    init(coordinator: LearnRoutable) {
        self.coordinator = coordinator
    }

    func handleAward(url: String) {
        print(url)
    }
}
