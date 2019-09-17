//
//  Created by Aaron Nwabuoku on 2019-09-15.
//

import Foundation
import Starscream

public protocol StompClientDelegate {
    func stompClientDidConnect(client: StompClient)
    func stompClientDidDisconnect(client: StompClient)
    func stompClientDidDisconnectWithError(client: StompClient, error: Error)
    func stompClientDidReceiveData(client: StompClient, data: Data, destination: String)
    func stompClientDidEncounterError(client: StompClient, error: Error)
}

public final class StompClient : WebSocketDelegate {
    public var delegate: StompClientDelegate?
    
    public var isConnected: Bool {
        return socket.isConnected
    }
    
    private let url: URL
    private let socket: WebSocket
    
    private var frameQueue: FrameQueue = FrameQueue()
    
    public init(url: URL) {
        self.url = url
        self.socket = WebSocket(url: url)
        
        socket.delegate = self
    }
    
    public func connect() {
        socket.connect()
    }
    
    public func sendJSONMessage(destination: String, data: AnyObject, headers: [String : String]? = nil){
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions())
            let message = String(data: jsonData, encoding: String.Encoding.utf8)!
            
            var stompHeaders: Set<StompHeader> = [.destination(path: destination), .contentType(type: "application/json;charset=UTF-8"), .contentLength(length: message.utf8.count)]
            
            if let params = headers , !params.isEmpty {
                for (key, value) in params {
                    stompHeaders.insert(.custom(key: key, value: value))
                }
            }
            
            sendFrame(StompClientFrame(command: .send, headers: stompHeaders, body: message))
        } catch {
            delegate?.stompClientDidEncounterError(client: self, error: error)
        }
    }
    
    public func subscribe(destination: String, headers: [String : String]? = nil) -> String {
        let id = "sub-" + Int(arc4random_uniform(1000)).description
        
        var stompHeaders: Set<StompHeader> = [.destinationId(id: id), .destination(path: destination)]
        
        if let params = headers , !params.isEmpty {
            for (key, value) in params {
                stompHeaders.insert(.custom(key: key, value: value))
            }
        }
        
        sendFrame(StompClientFrame(command: .subscribe, headers: stompHeaders))
        
        return id
    }
    
    public func unsubscribe(_ destination: String, destinationId: String) {
        let headers: Set<StompHeader> = [.destinationId(id: destinationId), .destination(path: destination)]
        
        sendFrame(StompClientFrame(command: .unsubscribe, headers: headers))
    }
    
    public func disconnect() {
        sendFrame(StompClientFrame(command: .disconnect))
        
        socket.disconnect()
    }
    
    public func websocketDidConnect(socket: WebSocketClient) {
        let headers: Set<StompHeader> = [.acceptVersion(version: "1.1,1.2"), .host(hostname: url.host!), .heartBeat(value: "10000,10000")]
        
        sendFrame(StompClientFrame(command: .connect, headers: headers))
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        if let error = error {
            delegate?.stompClientDidDisconnectWithError(client: self, error: error)
        } else {
            delegate?.stompClientDidDisconnect(client: self)
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        do {
            let components = text.components(separatedBy: "\n")
            
            if components.first == "" {
                sendHeartBeat()
            } else {
                let frame = try StompServerFrame(text: text)
                
                print("Recieved frame:\n\(frame.description)")
                
                switch frame.command {
                case .connected:
                    while !frameQueue.isEmpty {
                        sendFrame(frameQueue.dequeue()!)
                    }
                    
                    delegate?.stompClientDidConnect(client: self)
                case .message:
                    print("Message recieved")
                case .error:
                    print("Error recieved")
                default:
                    break
                }
            }
        } catch {
            delegate?.stompClientDidEncounterError(client: self, error: error)
        }
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        // Not called in STOMP
    }
    
    private func sendFrame(_ frame: StompClientFrame) {
        if socket.isConnected {
            socket.write(string: frame.description)
        } else {
            frameQueue.enqueue(frame)
        }
    }
    
    private func sendHeartBeat() {
        socket.write(string: "\n\n")
    }
}

fileprivate struct FrameQueue {
    private var array = [StompClientFrame?]()
    private var head = 0
    
    public var isEmpty: Bool {
        return count == 0
    }
    
    public var count: Int {
        return array.count - head
    }
    
    public mutating func enqueue(_ element: StompClientFrame) {
        array.append(element)
    }
    
    public mutating func dequeue() -> StompClientFrame? {
        guard head < array.count, let element = array[head] else { return nil }
        
        array[head] = nil
        head += 1
        
        let percentage = Double(head)/Double(array.count)
        if array.count > 50 && percentage > 0.25 {
            array.removeFirst(head)
            head = 0
        }
        
        return element
    }
    
    public var front: StompClientFrame? {
        if isEmpty {
            return nil
        } else {
            return array[head]
        }
    }
}
