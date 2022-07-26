// ___FILEHEADER___

import Foundation
import SwiftUI

struct ___VARIABLE_moduleName___CoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ___VARIABLE_moduleName___Coordinator

    init(coordinator: ___VARIABLE_moduleName___Coordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        if let rootViewModel = coordinator.rootViewModel {
            ___VARIABLE_moduleName___View(viewModel: rootViewModel)
        }
    }
}
