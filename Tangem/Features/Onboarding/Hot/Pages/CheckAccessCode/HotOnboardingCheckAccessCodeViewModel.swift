//
//  HotOnboardingCheckAccessCodeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets
import TangemLocalization

final class HotOnboardingCheckAccessCodeViewModel: ObservableObject {
    @Published var accessCode: String = ""
    @Published private var isSuccessful = false

    let title = Localization.accessCodeCheckTitle
    let codeLength: Int = 6

    var pinColor: Color {
        guard accessCode.count == codeLength else {
            return Colors.Text.primary1
        }
        return isSuccessful ? Colors.Text.accent : Colors.Text.warning
    }

    private weak var delegate: HotOnboardingCheckAccessCodeDelegate?

    private var bag = Set<AnyCancellable>()

    init(delegate: HotOnboardingCheckAccessCodeDelegate) {
        self.delegate = delegate
        bind()
    }
}

// MARK: - Private methods

private extension HotOnboardingCheckAccessCodeViewModel {
    func bind() {
        $accessCode
            .dropFirst()
            .sink { [weak self] code in
                self?.check(accessCode: code)
            }
            .store(in: &bag)
    }

    func check(accessCode: String) {
        guard
            accessCode.count == codeLength,
            let result = delegate?.validateAccessCode(accessCode)
        else {
            return
        }

        isSuccessful = result

        if isSuccessful {
            delegate?.validateSuccessful()
        }
    }
}
