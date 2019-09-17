//
//  Created by Aaron Nwabuoku on 2019-09-15.
//

import Foundation

public struct StompClientFrame: CustomStringConvertible {
    private(set) var command: StompClientCommand
    private(set) var headers: Set<StompHeader>
    private(set) var body: String
    
    init(command: StompClientCommand, headers: Set<StompHeader> = [], body: String = "") {
        self.command = command
        self.headers = headers
        self.body = body
    }
    
    public var description: String {
        var string = command.rawValue + "\n"
        
        for header in headers {
            string += header.key + ":" + header.value + "\n"
        }
        
        string += "\n" + body + "\0"
        
        return string
    }
}

struct StompServerFrame: CustomStringConvertible {
    private(set) var command: StompServerCommand
    private(set) var headers: Set<StompHeader>
    private(set) var body: String
    
    init(command: StompServerCommand, headers: Set<StompHeader> = [], body: String) {
        self.command = command
        self.headers = headers
        self.body = body
    }
    
    init(text: String) throws {
        var components = text.components(separatedBy: "\n")
        
        if components.first == "" {
            components.removeFirst()
        }
        
        let command = try StompServerCommand(text: components.first!)
        
        var headers: Set<StompHeader> = []
        var body = ""
        var isBody = false
        for index in 1 ..< components.count {
            let component = components[index]
            if isBody {
                body += component
                if body.hasSuffix("\0") {
                    body = body.replacingOccurrences(of: "\0", with: "")
                }
            } else {
                if component == "" {
                    isBody = true
                } else {
                    let parts = component.components(separatedBy: ":")
                    guard let key = parts.first, let value = parts.last else {
                        continue
                    }
                    let header = StompHeader(key: key, value: value)
                    headers.insert(header)
                }
            }
        }
        
        self.init(command: command, headers: headers, body: body)
    }
    
    var description: String {
        var string = command.rawValue + "\n"
        
        for header in headers {
            string += header.key + ":" + header.value + "\n"
        }
        
        string += "\n" + body + "\0"
        
        return string
    }
}

enum StompClientCommand: String {
    case send = "SEND"
    case subscribe = "SUBSCRIBE"
    case unsubscribe = "UNSUBSCRIBE"
    case begin = "BEGIN"
    case commit = "COMMIT"
    case abort = "ABORT"
    case ack = "ACK"
    case nack = "NACK"
    case disconnect = "DISCONNECT"
    case connect = "CONNECT"
    case stomp = "STOMP"
    
    
    init(text: String) throws {
        guard let command = StompClientCommand(rawValue: text) else {
            throw NSError(domain: "io.howdi.ios.sockets", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Sent command is undefined."])
        }
        
        self = command
    }
}

enum StompServerCommand: String {
    case connected = "CONNECTED"
    case message = "MESSAGE"
    case receipt = "RECEIPT"
    case error = "ERROR"
    
    init(text: String) throws {
        guard let command = StompServerCommand(rawValue: text) else {
            throw NSError(domain: "io.howdi.ios.sockets", code: 1002, userInfo: [NSLocalizedDescriptionKey : "Received command is undefined."])
        }
        
        self = command
    }
}


enum StompHeader: Hashable {
    case contentLength(length: Int)
    case contentType(type: String)
    case receipt(receipt: String)
    
    case acceptVersion(version: String)
    case host(host: String)
    case login(login: String)
    case passcode(passcode: String)
    case heartBeat(value: String)
    
    case version(version: String)
    case session(session: String)
    case server(server: String)
    
    case destination(destination: String)
    case transaction(transaction: String)
    
    case subscriptionId(id: String)
    case ack(ack: String)
    
    case messageId(id: String)
    case subscription(id: String)
    
    case receiptId(id: String)
    
    case custom(key: String, value: String)
    
    init(key: String, value: String) {
        switch key {
        case "content-length":
            self = .contentLength(length: Int(value)!)
        case "content-type":
            self = .contentType(type: value)
        case "receipt":
            self = .receipt(receipt: value)
        case "accept-version":
            self = .acceptVersion(version: value)
        case "host":
            self = .host(host: value)
        case "login":
            self = .login(login: value)
        case "passcode":
            self = .passcode(passcode: value)
        case "heart-beat":
            self = .heartBeat(value: value)
        case "version":
            self = .version(version: value)
        case "session":
            self = .session(session: value)
        case "server":
            self = .server(server: value)
        case "destination":
            self = .destination(destination: value)
        case "transaction":
            self = .transaction(transaction: value)
        case "id":
            self = .subscriptionId(id: value)
        case "ack":
            self = .ack(ack: value)
        case "message-id":
            self = .messageId(id: value)
        case "subscription":
            self = .subscription(id: value)
        case "receipt-id":
            self = .receiptId(id: value)
        default:
            self = .custom(key: key, value: value)
        }
    }
    
    var key: String {
        switch self {
        case .contentLength:
            return "content-length"
        case .contentType:
            return "content-type"
        case .receipt:
            return "receipt"
        case .acceptVersion:
            return "accept-version"
        case .host:
            return "host"
        case .login:
            return "login"
        case .passcode:
            return "passcode"
        case .heartBeat:
            return "heart-beat"
        case .version:
            return "version"
        case .session:
            return "session"
        case .server:
            return "server"
        case .destination:
            return "destination"
        case .transaction:
            return "transaction"
        case .subscriptionId:
            return "id"
        case .ack:
            return "ack"
        case .messageId:
            return "message-id"
        case .subscription:
            return "subscription"
        case .receiptId:
            return "receipt-id"
        case .custom(let key, _):
            return key
        }
    }
    
    var value: String {
        switch self {
        case .custom(_, let value):
            return value
        case .contentLength(let length):
            return "\(length)"
        case .contentType(let type):
            return type
        case .receipt(let receipt):
            return receipt
        case .acceptVersion(let version):
            return version
        case .host(let host):
            return host
        case .login(let login):
            return login
        case .passcode(let passcode):
            return passcode
        case .heartBeat(let value):
            return value
        case .version(let version):
            return version
        case .session(let session):
            return session
        case .server(let server):
            return server
        case .destination(let destination):
            return destination
        case .transaction(let transaction):
            return transaction
        case .subscriptionId(let id):
            return id
        case .ack(let ack):
            return ack
        case .messageId(let id):
            return id
        case .subscription(let id):
            return id
        case .receiptId(let id):
            return id
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key.hashValue)
    }
    
    static func ==(lhs: StompHeader, rhs: StompHeader) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
