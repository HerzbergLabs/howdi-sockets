//
//  Created by Aaron Nwabuoku on 2019-09-15.
//

import Foundation

struct StompClientFrame: CustomStringConvertible {
    private(set) var command: StompClientCommand
    private(set) var headers: Set<StompHeader>
    private(set) var body: String
    
    init(command: StompClientCommand, headers: Set<StompHeader> = [], body: String = "") {
        self.command = command
        self.headers = headers
        self.body = body
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
            throw NSError(domain: "io.howdi.ios", code: 1002, userInfo: [NSLocalizedDescriptionKey : "Received command is undefined."])
        }
        
        self = command
    }
}


enum StompHeader: Hashable {
    case acceptVersion(version: String)
    case heartBeat(value: String)
    case host(hostname: String)
    case destination(path: String)
    case destinationId(id: String)
    case version(version: String)
    case subscription(id: String)
    case messageId(id: String)
    case contentLength(length: Int)
    case message(message: String)
    case userName(name: String)
    case contentType(type: String)
    case custom(key: String, value: String)
    
    init(key: String, value: String) {
        switch key {
        case "version":
            self = .version(version: value)
        case "subscription":
            self = .subscription(id: value)
        case "message-id":
            self = .messageId(id: value)
        case "content-length":
            self = .contentLength(length: Int(value)!)
        case "message":
            self = .message(message: value)
        case "destination":
            self = .destination(path: value)
        case "heart-beat":
            self = .heartBeat(value: value)
        case "host":
            self = .host(hostname: value)
        case "user-name":
            self = .userName(name: value)
        case "content-type":
            self = .contentType(type: value)
        default:
            self = .custom(key: key, value: value)
        }
    }
    
    var key: String {
        switch self {
        case .acceptVersion:
            return "accept-version"
        case .heartBeat:
            return "heart-beat"
        case .host:
            return "host"
        case .destination:
            return "destination"
        case .destinationId:
            return "id"
        case .custom(let key, _):
            return key
        case .version:
            return "version"
        case .subscription:
            return "subscription"
        case .messageId:
            return "message-id"
        case .contentLength:
            return "content-length"
        case .message:
            return "message"
        case .userName:
            return "user-name"
        case .contentType:
            return "content-type"
        }
    }
    
    var value: String {
        switch self {
        case .acceptVersion(let version):
            return version
        case .heartBeat(let value):
            return value
        case .host(let hostname):
            return hostname
        case .destination(let path):
            return path
        case .destinationId(let id):
            return id
        case .custom(_, let value):
            return value
        case .version(let version):
            return version
        case .subscription(let id):
            return id
        case .messageId(let id):
            return id
        case .contentLength(let length):
            return "\(length)"
        case .message(let body):
            return body
        case .userName(let name):
            return name
        case .contentType(let type):
            return type
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key.hashValue)
    }
    
    static func ==(lhs: StompHeader, rhs: StompHeader) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
