import UIKit
import BinanceChain

class ViewController: UIViewController {

    var test: Test?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Run tests
        self.test = Test()
        self.test?.runTestsOnTestnet(.allMinimised)

    }

}

