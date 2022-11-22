//___FILEHEADER___

import Foundation
import Combine

class ___VARIABLE_moduleName___Coordinator: CoordinatorObject {
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: ___VARIABLE_moduleName___ViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    required init(
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {

    }
}

// MARK: - Options

extension ___VARIABLE_moduleName___Coordinator {
    enum Options {

    }
}

// MARK: - ___VARIABLE_moduleName___Routable

extension ___VARIABLE_moduleName___Coordinator: ___VARIABLE_moduleName___Routable {}
