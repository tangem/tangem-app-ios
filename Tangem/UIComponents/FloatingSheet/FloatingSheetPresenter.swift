//
//  FloatingSheetPresenter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import protocol TangemUI.FloatingSheetContentViewModel

@MainActor
protocol FloatingSheetPresenter: AnyObject {
    func enqueue(sheet: some FloatingSheetContentViewModel)

    func removeActiveSheet()
    func removeAllSheets()

    func pauseSheetsDisplaying()
    func resumeSheetsDisplaying()
}
