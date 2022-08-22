// ___FILEHEADER___

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
