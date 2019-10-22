# Welcome to Tangem

The Tangem card is a self-custodial hardware wallet for blockchain assets. The main functions of Tangem cards are to securely create and store a private key from a blockchain wallet and sign blockchain transactions. The Tangem card does not allow users to import/export, backup/restore private keys, thereby guaranteeing that the wallet is unique and unclonable. 

- [Getting Started](#getting-started)
    - [Requirements](#requirements)
    - [Installation](#installation)
        - [CocoaPods](#cocoapods)
        - [Swift Package Manager](#swift-package-manager)
        - [Carthage](#carthage)
- [Usage](#usage)
    - [Initialization](#initialization)
    - [Card interaction](#card-interaction)
        - [Scan card](#scan-card)
        - [Sign](#sign)
    - [Environment class](#environment-class)
- [Customization](#customization)
    - [UI](#ui)
    - [Tasks](#tasks)
    - [Localization](#localization)


## Getting Started

### Requirements
iOS 11+ (CoreNFC is required)

### Installation

1) Configure your app to detect NFC tags. Turn on Near Field Communication Tag Reading under the Capabilities tab for the project’s target (see [Add a capability to a target](https://help.apple.com/xcode/mac/current/#/dev88ff319e7)).

2) Add the [NFCReaderUsageDescription](https://developer.apple.com/documentation/bundleresources/information_property_list/nfcreaderusagedescription) key as a string item to the Info.plist file. For the value, enter a string that describes the reason the app needs access to the device’s NFC reader: 
```xml
<key>NFCReaderUsageDescription</key>
<string>Some reason</string>
```

3) In the Info.plist file, add the list of the application identifiers supported in your app to the [ISO7816 Select Identifiers](https://developer.apple.com/documentation/bundleresources/information_property_list/select-identifiers) (AIDs) information property list key. The AIDs of Tangem cards are: `A000000812010208` and `D2760000850101`.

```
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
    <array>
        <string>A000000812010208</string>
        <string>D2760000850101</string>
    </array>
```

4) To prevent customers from installing apps on a device that does not support the NFC capability, add the following to the Info.plist code:

 ```
<key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>nfc</string>
    </array>
```

#### CocoaPods

For the Tangem SDK, use the following entry in your Podfile:

```rb
pod 'TangemSdk'
```

Then run `pod install`.

For any file in which you'd like to use the Tangem SDK in, don't forget to
import the framework with `import TangemSdk`.

## Usage

Tangem SDK is a self-sufficient solution that implements a card abstraction model, methods of interaction with the card and interactions with the user via UI.

### Initialization
To get started, you need to create an instance of the `CardManager` class. It provides the simple way of interacting with the card.

```swift
let cardManager: CardManager = CardManager()
```

The universal initializer allows you to create an instance of the class that you can use immediately without any additional setup. 

You can also use a custom initializer, which allows you to pass your implementation of `CardReader` protocol to communicate with a card as well as the implementation of `CardManagerDelegate` protocol to create a custom user interface.
You can read more about this in [Customization](#сustomization).

### Tasks

#### Scan card 
To start using any card, you first need to read it using the ` scanCard()` method. This method launches an NFC session, and once it’s connected with the card, it obtains the card data. Optionally, if the card contains a wallet (private and public key pair), it proves that the wallet owns a private key that corresponds to a public one.

Example:

```swift
cardManager.scanCard {[unowned self] scanResult, cardEnvironment in
    switch scanResult {
        case .onRead(let card):
            // Card object contains information from scanned card
            print("Card was read with result: \(card)")
        case .onVerify(let isGenuine):
            // isGenuine shows is the card Genuine or not
            print("Card was verified with result: \(isGenuine)")
        case .userCancelled:
            print("Operation was cancelled by user")
        case .failure(let error):
            print("Error occurred: \(error.localizedDescription)")
    }

    print("Current card environment: \(cardEnvironment)")

}

```
Scanning the card is an asynchronous operation. In order to get a result for the method, you need to subscribe to the cases. 

`.onRead(let card)` – this event is triggered after the card has been successfully read. In addition, the obtained card object is contained inside the enum. At this stage, the authenticity of the card is ***NOT*** verified.

`.onVerify(let isGenuine)` – this event is triggered when the card’s authenticity has been verified. If the card is authentic, isGenuine will be set to true, otherwise, it will be set to false.

`.userCancelled` – this event is triggered when the user manually cancels the operation.

`.failure(let error)` – this event is triggered when something goes wrong during the operation.

***
The callback also returns an instance of `CardEnvironment`. This is needed to perform further operations with the card. ([More](#evironment-class) about `CardEnvironment` class).

#### Sign
This method allows you to sign one or multiple hashes. Simultaneous signing of array of hashes in a single SIGN command is required to support Bitcoin-type multi-input blockchains (UTXO). The SIGN command will return a corresponding array of signatures.

```swift
let hashes = [hash1, hash2]
cardManager.sign(hashes: hashes, environment: cardEnvironment) { result, cardEnvironment in
    switch result {
    case .success(let signResponse):
        print(signResponse)
    case .failure(let error):
        print(error.localizedDescription)
    case .userCancelled:
          print("user cancelled")
    }
    
    print("Current card environment: \(cardEnvironment)")
    
}
```

### Evironment class
Depending on the card settings, interacting with it may require encryption, a PIN code, CVC code, etc. SDK tries to handle these situations. An instanse of `CardEnvironment` class is an object that contains data needed to interact with the card. It may be modified in the process of executing the command.

Every command takes an instance of `CardEnvironment` and returns it in the callback. 

>For example, if the card requires a PIN code, the SDK will request the user to enter it, after which the result is saved to the instance of `CardEnvironment` and is returned in the callback.

In most cases, we recommend saving the `CardEnvironment` for each card and apply it to all methods.

Providing an instance of `CardEnvironment` is not required when scanning the card for the first time if you don’t want to give it a specific configuration at the beginning.


> For example, if you know that the cards made specifically for your app will require encryption when being scanned. If you don’t provide a specially configured instance of `CardEnvironment`, the SDK will first determine whether or not encryption is required, and then execute the command, which would take slightly longer than if you’d provided the initial settings.

## Customization
### UI
If the interaction with user is required, the SDK performs the entire cycle of this interaction. In order to change the appearance or behavior of the user UI, you can provide you own implementation of the `CardManagerDelegate` protocol. After this, initialize the `CardManager` class with your delegate class.

```swift
let myCardManagerDelegate = MyCardManagerDelegate()
let cardManager: CardManager = CardManager(cardManagerDelegate: myCardManagerDelegate)
```

> If you pass nil instead of `cardManagerDelegate`, the SDK won’t be able to process errors that require user intervention and return them to `.failure(let error)`.

### Tasks
`CardManager` only covers general tasks. If you want to trigger card commands in a certain order, you need to create your own task.

To do this, you need to create a subclass of the `Task` class, and override the `onRun(..)` method.

Then call the `runTask(..)` method of the `CardManager` class with you task.

```swift
let task = ScanTask()
cardManager.runTask(task, callback: callback)
```
> For example, you want to read the card and immediately sign a transaction on it within one NFC session. In such a case, you need to inherit from the `Task` class and override the `onRun(..)` method, in which you implement the required behavior.

It’s possible to run just one command without the need to create a separate task by using the `runCommand(..)` method.
> For example, if you need to read the card details, but don’t need to check the authenticity. 
```swift
do {
    let environment = CardEnvironment()
    let readCommand = ReadCommand(pin1: environment.pin1)
    let task = SingleCommandTask(readCommand)
    runTask(task, environment: environment, callback: callback)
} catch {
    print("Error")
    return
}
```

### Localization
You can replace one or more lines used in the SDK with your own. For this, you need to add keys with translations of the lines that you want to replace in your app, after which you need to install the localization bundle like this:
```swift
TangemSdk.Localization.localizationsBundle = Bundle(for: AppDelegate.self)
````
