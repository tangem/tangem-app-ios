//
//  HotOnboardingAccessCodeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSdk
import TangemAssets
import TangemLocalization

final class HotOnboardingAccessCodeViewModel: ObservableObject {
    @Published private(set) var state: State = .accessCode

    @Published private var accessCode: String = ""
    @Published private var confirmAccessCode: String = ""

    let codeLength: Int = 6

    var code: Binding<String> {
        Binding(
            get: {
                switch self.state {
                case .accessCode:
                    self.accessCode
                case .confirmAccessCode:
                    self.confirmAccessCode
                }
            },
            set: { newValue in
                switch self.state {
                case .accessCode:
                    self.accessCode = newValue
                case .confirmAccessCode:
                    self.confirmAccessCode = newValue
                }
            }
        )
    }

    var infoItem: InfoItem {
        switch state {
        case .accessCode:
            InfoItem(
                title: Localization.accessCodeCreateTitle,
                description: Localization.accessCodeCreateDescription("\(codeLength)")
            )
        case .confirmAccessCode:
            InfoItem(
                title: Localization.accessCodeConfirmTitle,
                description: Localization.accessCodeConfirmDescription
            )
        }
    }

    var isPinSecured: Bool {
        switch state {
        case .accessCode:
            false
        case .confirmAccessCode:
            true
        }
    }

    var pinColor: Color {
        switch state {
        case .accessCode:
            return Colors.Text.primary1
        case .confirmAccessCode where confirmAccessCode.count == codeLength:
            return confirmAccessCode == accessCode ? Colors.Text.accent : Colors.Text.warning
        case .confirmAccessCode:
            return Colors.Text.primary1
        }
    }

    private weak var delegate: HotOnboardingAccessCodeDelegate?

    private var bag = Set<AnyCancellable>()

    init(delegate: HotOnboardingAccessCodeDelegate) {
        self.delegate = delegate
        bind()
    }
}

// MARK: - Internal methods

extension HotOnboardingAccessCodeViewModel {
    func resetState() {
        accessCode = ""
        confirmAccessCode = ""
        state = .accessCode
    }
}

// MARK: - Private methods

private extension HotOnboardingAccessCodeViewModel {
    func bind() {
        $accessCode
            .dropFirst()
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .sink { [weak self] code in
                self?.check(accessCode: code)
            }
            .store(in: &bag)

        $confirmAccessCode
            .dropFirst()
            .sink { [weak self] code in
                self?.check(confirmAccessCode: code)
            }
            .store(in: &bag)
    }

    func check(accessCode: String) {
        guard accessCode.count == codeLength else {
            return
        }
        state = .confirmAccessCode
    }

    func check(confirmAccessCode: String) {
        guard
            confirmAccessCode.count == codeLength,
            confirmAccessCode == accessCode
        else {
            return
        }

        if delegate?.isRequestBiometricsNeeded() == true {
            requestBiometricsAccess(accessCode: accessCode)
        }
    }

    func requestBiometricsAccess(accessCode: String) {
        BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason) { [weak delegate] _ in
            delegate?.accessCodeComplete(accessCode: accessCode)
        }
    }
}

// MARK: - Types

extension HotOnboardingAccessCodeViewModel {
    enum State {
        case accessCode
        case confirmAccessCode
    }

    struct InfoItem {
        let title: String
        let description: String
    }
}
