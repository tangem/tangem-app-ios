//
//  FloatingSheetRegistry.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

@MainActor
public final class FloatingSheetRegistry {
    typealias FloatingSheetViewBuilder = (any FloatingSheetContentViewModel) -> AnyView

    private var sheets = [ObjectIdentifier: FloatingSheetViewBuilder]()

    public nonisolated init() {}

    public func register<SheetContentViewModel: FloatingSheetContentViewModel>(
        _ viewModelType: SheetContentViewModel.Type,
        viewBuilder: @escaping (SheetContentViewModel) -> some View
    ) {
        sheets[viewModelType] = { sheetViewModel in
            guard let viewModel = sheetViewModel as? SheetContentViewModel else {
                return AnyView(EmptyView())
            }

            let view = viewBuilder(viewModel)
            return AnyView(view)
        }
    }

    func view(for viewModel: some FloatingSheetContentViewModel) -> AnyView? {
        let viewModelType = type(of: viewModel)

        guard let sheetContent = sheets[viewModelType]?(viewModel) else {
            assertionFailure("FloatingSheetView does not have registered content view for \(viewModelType)")
            return nil
        }

        return sheetContent
    }
}

// MARK: - SwiftUI.EnvironmentValues entry

public extension EnvironmentValues {
    @Entry var floatingSheetRegistry = FloatingSheetRegistry()
}

private extension Dictionary where Key == ObjectIdentifier {
    subscript<T>(key: T.Type) -> Value? {
        get { return self[ObjectIdentifier(T.self)] }
        set { self[ObjectIdentifier(T.self)] = newValue }
    }
}
