import ArgumentParser

struct Keystore:ParsableCommand {
    
    @Flag(help: "Should print debug info")
    var debug = false
    
    @Option(name: .shortAndLong, help: "which port to bind on")
    var port = 9009
    
    @Option(name: .shortAndLong, help: "max_size storage limit")
    var max_size = 1000
    
    static let configuration: CommandConfiguration = CommandConfiguration(
        commandName: "Keystore", abstract: "Simple keystore for fun",
        discussion: "just type keystore"
    )
    
    mutating func run() throws {
        try run_server(port:self.port, max_size: self.max_size)
    }
}

Keystore.main()
