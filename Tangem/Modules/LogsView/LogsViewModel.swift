//
//  LogsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import UIKit
import Foundation
import TangemFoundation
import TangemLogger
import SwiftUI

class LogsViewModel: ObservableObject {
    var selectedCategory: String { categories[selectedCategoryIndex] }

    @Published var selectedCategoryIndex: Int = .zero
    @Published var logs: LoadingResult<[LogRowViewData], Error> = .loading
    @Published var categories: [String] = ["All"]
    @Published var alert: AlertBinder?
    @Published var sheet: ActionSheetBinder?

    private let entries: CurrentValueSubject<LoadingResult<[LogRowViewData], Error>, Never> = .init(.loading)
    private var bag: Set<AnyCancellable> = []

    init() {
        bind()
        load()
    }

    func openSheet() {
        sheet = .init(sheet: .init(title: Text("Choose action"), message: nil, buttons: [
            .default(Text("Share"), action: { [weak self] in self?.share() }),
            .default(Text("Clear"), action: { [weak self] in self?.clear() }),
            .cancel(),
        ]))
    }

    private func share() {
        let url = OSLogFileParser.logFile
        AppPresenter.shared.show(
            UIActivityViewController(activityItems: [url], applicationActivities: nil)
        )
    }

    private func clear() {
        alert = AlertBuilder.makeAlert(
            title: "Clear logs?",
            message: "Do you want to delete `\(OSLogFileParser.logFile.absoluteString)` file?",
            with: .withPrimaryCancelButton(secondaryTitle: "Yes", secondaryAction: { [weak self] in
                try? OSLogFileParser.removeFile()
                self?.selectedCategoryIndex = .zero
                self?.load()
            })
        )
    }

    private func bind() {
        entries
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map { entries in
                let categories = entries.value.flatMap { $0.map(\.log.category) } ?? []
                return ["All"] + categories.toSet().sorted()
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .receiveValue { viewModel, categories in
                viewModel.categories = categories
            }
            .store(in: &bag)

        Publishers
            .CombineLatest(entries, $selectedCategoryIndex)
            .receive(on: DispatchQueue.global())
            .withWeakCaptureOf(self)
            .map { viewModel, args in
                let (entries, categoryIndex) = args

                return entries.mapValue { entries in
                    if categoryIndex > 0 {
                        return entries
                            .filter { $0.log.category == viewModel.categories[categoryIndex] }
                    }

                    return entries
                }
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .receiveValue { viewModel, entries in
                viewModel.logs = entries
            }
            .store(in: &bag)
    }

    private func load() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result {
                try OSLogFileParser.entries().reversed().map { LogRowViewData(log: $0) }
            }
            self.entries.send(.result(result))
        }
    }
}
