//
//  FloatingSheetVisibility.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

@MainActor
public final class FloatingSheetVisibility: ObservableObject {
    @Published public private(set) var visibleSheets: Set<ObjectIdentifier> = []

    public static let shared: FloatingSheetVisibility = .init()

    private init() {}

    public func appeared<SheetContentViewModel: FloatingSheetContentViewModel>(_ viewModelType: SheetContentViewModel.Type) {
        visibleSheets.insert(ObjectIdentifier(viewModelType))
    }

    public func disappeared<SheetContentViewModel: FloatingSheetContentViewModel>(_ viewModelType: SheetContentViewModel.Type) {
        visibleSheets.remove(ObjectIdentifier(viewModelType))
    }
}
