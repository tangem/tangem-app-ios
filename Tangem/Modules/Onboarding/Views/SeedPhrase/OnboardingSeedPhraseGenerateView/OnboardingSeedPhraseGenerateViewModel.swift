//
//  OnboardingSeedPhraseGenerateViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemSdk

protocol OnboardingSeedPhraseGenerationDelegate: AnyObject {
    func continuePhraseGeneration(with entropyLength: EntropyLength)
}

class OnboardingSeedPhraseGenerateViewModel: ObservableObject {
    var availableLengths: [MnemonicLenght] = [.twelveWords, .twentyFourWords]

    @Published var selectedLenght: MnemonicLenght = .twelveWords
    @Published var words: [String] = []

    private weak var seedPhraseManager: SeedPhraseManager?
    private weak var delegate: OnboardingSeedPhraseGenerationDelegate?

    private var selectedLengthSubscription: AnyCancellable?

    init(seedPhraseManager: SeedPhraseManager, delegate: OnboardingSeedPhraseGenerationDelegate?) {
        self.seedPhraseManager = seedPhraseManager
        self.delegate = delegate
        words = seedPhraseManager.mnemonics[selectedLenght.entropyLength]?.mnemonicComponents ?? []

        bind()
    }

    func continueAction() {
        delegate?.continuePhraseGeneration(with: selectedLenght.entropyLength)
    }

    private func bind() {
        selectedLengthSubscription = $selectedLenght
            .dropFirst()
            .map { $0.entropyLength }
            .withWeakCaptureOf(self)
            .map { $0.0.seedPhraseManager?.mnemonics[$0.1]?.mnemonicComponents ?? [] }
            .assign(to: \.words, on: self, ownership: .weak)
    }
}

extension OnboardingSeedPhraseGenerateViewModel {
    enum MnemonicLenght: Identifiable {
        case twelveWords
        case twentyFourWords

        var id: Self { self }

        var pickerTitle: String {
            Localization.onboardingSeedGenerateWordsCount(entropyLength.wordCount)
        }

        var descriptionMessage: String {
            Localization.onboardingSeedGenerateMessageWordsCount(entropyLength.wordCount)
        }
    }
}

private extension OnboardingSeedPhraseGenerateViewModel.MnemonicLenght {
    var entropyLength: EntropyLength {
        switch self {
        case .twelveWords: return .bits128
        case .twentyFourWords: return .bits256
        }
    }
}
