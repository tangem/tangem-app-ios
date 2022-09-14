//___FILEHEADER___

import SwiftUI

struct ___VARIABLE_moduleName:identifier___View: View {
    @ObservedObject private var viewModel: ___VARIABLE_moduleName: identifier___ViewModel

    init(viewModel: ___VARIABLE_moduleName: identifier___ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

struct ___VARIABLE_moduleName:identifier___View_Preview: PreviewProvider {
    static let viewModel = ___VARIABLE_moduleName: identifier___ViewModel(coordinator: ___VARIABLE_moduleName:identifier___Coordinator())

    static var previews: some View {
        ___VARIABLE_moduleName: identifier___View(viewModel: viewModel)
    }
}
