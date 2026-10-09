//
//  FloatingSheetPresenter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import protocol TangemUI.FloatingSheetContentViewModel

protocol FloatingSheetPresentingStateProvider: AnyObject {
    var hasPresentedSheet: Bool { get }
    var hasPresentedSheetPublisher: AnyPublisher<Bool, Never> { get }

    func containsSheet(withId id: String) -> Bool
}

@MainActor
protocol FloatingSheetPresenter: AnyObject {
    func enqueue(sheet: some FloatingSheetContentViewModel)

    func removeActiveSheet()
    func removeSheet(withId id: String)
    func removeAllSheets()

    func pauseSheetsDisplaying()
    func resumeSheetsDisplaying()
}
