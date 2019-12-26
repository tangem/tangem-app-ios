import Foundation
import Darwin

func showInstructions() {

    print("""

Usage: swift run binancechain [test]

Available tests:

               all: Run everything
               api: HTTP API
         websocket: Websockets
            wallet: Wallet
         broadcast: Broadcast Transactions
           noderpc: NodeRPC (JSONRPC/HTTP)

""")
   exit(0)

}

let args = CommandLine.arguments.dropFirst()
guard let name = args.first, let which = Test.Tests(rawValue: name) else {
    showInstructions()
    exit(0)
}

let test = Test()
test.runTestsOnTestnet(which)

RunLoop.main.run()
