[![Version](https://img.shields.io/cocoapods/v/TangemSdk.svg?style=flat)](https://cocoapods.org/pods/TangemSdk)
[![License](https://img.shields.io/cocoapods/l/TangemSdk.svg?style=flat)](https://cocoapods.org/pods/TangemSdk)
[![Platform](https://img.shields.io/cocoapods/p/TangemSdk.svg?style=flat)](https://cocoapods.org/pods/TangemSdk)

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
- [Customization](#customization)
	- [UI](#ui)
	- [Tasks](#tasks)
	- [Localization](#localization)


## Getting Started

### Requirements
iOS 11+ (CoreNFC is required), Xcode 11+

### Installation

1) Configure your app to detect NFC tags. Turn on Near Field Communication Tag Reading under the Capabilities tab for the project’s target (see [Add a capability to a target](https://help.apple.com/xcode/mac/current/#/dev88ff319e7)).

2) Add the [NFCReaderUsageDescription](https://developer.apple.com/documentation/bundleresources/information_property_list/nfcreaderusagedescription) key as a string item to the Info.plist file. For the value, enter a string that describes the reason the app needs access to the device’s NFC reader: 
```xml
<key>NFCReaderUsageDescription</key>
<string>Some reason</string>
```

3) In the Info.plist file, add the list of the application identifiers supported in your app to the [ISO7816 Select Identifiers](https://developer.apple.com/documentation/bundleresources/information_property_list/select-identifiers) (AIDs) information property list key. The AIDs of Tangem cards are: `A000000812010208` and `D2760000850101`.

```xml
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
    <array>
        <string>A000000812010208</string>
        <string>D2760000850101</string>
    </array>
```

4) To prevent customers from installing apps on a device that does not support the NFC capability, add the following to the Info.plist code:

 ```xml
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
let cardManager = CardManager()
```

The universal initializer allows you to create an instance of the class that you can use immediately without any additional setup. 

You can also use a custom initializer, which allows you to pass your implementation of `CardReader` protocol to communicate with a card as well as the implementation of `CardManagerDelegate` protocol to create a custom user interface.
You can read more about this in [Customization](#сustomization).

### Tasks

#### Scan card 
To start using any card, you first need to read it using the ` scanCard()` method. This method launches an NFC session, and once it’s connected with the card, it obtains the card data. Optionally, if the card contains a wallet (private and public key pair), it proves that the wallet owns a private key that corresponds to a public one.

Example:

```swift
cardManager.scanCard { taskEvent in
    switch taskEvent {  
    case .event(let scanEvent):
        switch scanEvent {
        case .onRead(let card):
            print("Read result: \(card)")
        case .onVerify(let isGenuine):
            print("Verication result: \(isGenuine)")
        }
    case .completion(let error):
        if let error = error {
            if case .userCancelled = error {
                // If user canceled operation manually, then do nothing
            } else {
                print("Completed with error: \(error.localizedDescription)")
            }
        }
        //Handle completion. Unlock UI, etc.
    }
}

```

Communication with the card is an asynchronous operation. In order to get a result for the method, you need to subscribe to the task callback. 

Every task can invoke callback several times with different events:

`.completion(Error)` – this event is triggered only once when task is completely finished. It means that it's the final callback. If error is not nil, then something went wrong during the operation.

`.event(<T>)` –  this event is triggered when one of operations inside the task is completed. 

**Possible events of the Scan card task:**

`.onRead(let card)` – this event is triggered after the card has been successfully read. In addition, the obtained card object is contained inside the enum. At this stage, the authenticity of the card is ***NOT*** verified.

`.onVerify(let isGenuine)` – this event is triggered when the card’s authenticity has been verified. If the card is authentic, isGenuine will be set to true, otherwise, it will be set to false.

#### Sign
This method allows you to sign one or multiple hashes. Simultaneous signing of array of hashes in a single SIGN command is required to support Bitcoin-type multi-input blockchains (UTXO). The SIGN command will return a corresponding array of signatures.

```swift
let hashes = [hash1, hash2]
guard let cardId = card?.cardId else {
    print("Please, scan card before")
    return
}
cardManager.sign(hashes: hashes, cardId: cardId) { taskEvent in
    switch taskEvent {
    case .event(let signResponse):
        print(signResponse)
    case .completion(let error):
        if let error = error {
            if case .userCancelled = error {
                // User cancelled the operation, do nothing
            } else {
                print("Completed with error: \(error.localizedDescription)")
            }
        }
        // Handle completion. Unlock UI, etc.
    }
}
```

## Customization
### UI
If the interaction with user is required, the SDK performs the entire cycle of this interaction. In order to change the appearance or behavior of the user UI, you can provide you own implementation of the `CardManagerDelegate` protocol. After this, initialize the `CardManager` class with your delegate class.

```swift
let myCardManagerDelegate = MyCardManagerDelegate()
let cardManager = CardManager(cardManagerDelegate: myCardManagerDelegate)
```

> If you pass nil instead of `cardManagerDelegate`, the SDK won’t be able to process errors that require user intervention and return them to `.failure(let error)`.

### Tasks
`CardManager` only covers general tasks. If you want to trigger card commands in a certain order, you need to create your own task.

To do this, you need to create a subclass of the `Task` class, and override the `onRun(..)` method.

Then call the `runTask(..)` method of the `CardManager` class with you task.

```swift
let task = YourTask()
cardManager.runTask(task) { taskEvent in
    // Handle your events
}
```
> For example, you want to read the card and immediately sign a transaction on it within one NFC session. In such a case, you need to inherit from the `Task` class and override the `onRun(..)` method, in which you implement the required behavior.

It’s possible to run just one command without the need to create a separate task by using the `runCommand(..)` method.
> For example, if you need to read the card details, but don’t need to check the authenticity. 
```swift
// Create command
let readCommand = ReadCommand()
// Run command with the callback
cardManager.runCommand(readCommand) { taskEvent in
    switch taskEvent {
    case .event(let response):
        if let publicKey = response.cardPublicKey {
            // Get public key from card
            print("Card public key: \(publicKey)")
        }
    case .completion(let error):
        if let error = error {
            if case .userCancelled = error {
                // User cancelled the operation, do nothing
            } else {
                print("completed with error: \(error.localizedDescription)")
            }
        }
    }
}
```

### Localization
You can replace one or more lines used in the SDK with your own. For this, you need to add keys with translations of the lines that you want to replace in your app, after which you need to install the localization bundle like this:
```swift
TangemSdk.Localization.localizationsBundle = Bundle(for: AppDelegate.self)
````
