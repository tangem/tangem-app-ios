import Cocoa
import BinanceChain

class ViewController: NSViewController, TestDelegate {

    @IBOutlet weak var textField: NSTextField!
    
    private var test: Test?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Run tests
        self.test = Test()
        self.test?.delegate = self
        self.test?.runTestsOnTestnet(.allMinimised)

    }

    // MARK: - TestDelegate

    func testComplete(label: String, property: Any, error: Error?) {

        var text = label + ":\n"
        if let error = error {
            text += error.localizedDescription
        } else {
            text += String(describing: property)
        }
        self.textField.stringValue = text + "\n\n"

    }

}
