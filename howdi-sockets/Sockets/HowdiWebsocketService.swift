import Foundation

enum ServiceState {
    case offline
    case connected
    case paused
}

public class HowdiWebsocketService: NSObject, StompClientDelegate {
    
    public static let shared = HowdiWebsocketService()
    
    private var state: ServiceState = .offline
    private var client: StompClient = OfflineStompClient()
    
    public func initializeService(url: String) {
        state = .connected
        
        print("********************Service is Initialized********************")
        
        let client = WebsocketStompClient(url: URL(string: url)!)
        
        client.delegate = self
        client.connect()
        
        self.client.resignToClient(client: client)
        self.client = client
    }
    
    public func pauseEvents() {
        state = .paused
        
        print("********************Service is Paused********************")
        
        if client.isConnected {
            client.disconnect()
        }
    }
    
    public func resumeEvents() {
        state = .connected
        
        print("********************Service is Resumed********************")
        
        if !client.isConnected {
            client.connect()
        }
    }
    
    public func stompClientDidConnect(client: StompClient) {
        print("STOMP client did connect")
        
        if state == .paused {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                if self.state == .paused && client.isConnected {
                    client.disconnect()
                }
            })
        }
    }
    
    public func stompClientDidReceiveJSONMessage(client: StompClient, destination: String, data: AnyObject, headers: [String : String]) {
        print("STOMP client did receive message: destination \(destination), data \(data) headers \(headers)")
    }
    
    public func stompClientDidEnqueueFrame(client: StompClient, frame: StompClientFrame) {
        print("STOMP client did enqueue frame \(frame)")
        
        if state == .connected  {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                if self.state == .connected && !client.isConnected {
                    client.connect()
                }
            })
        }
    }
    
    public func stompClientDidEncounterError(client: StompClient, error: Error) {
        print("STOMP client did encounter error \(error)")
        
        if state == .connected {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                if self.state == .connected && !client.isConnected {
                    client.connect()
                }
            })
        }
    }
    
    public func stompClientDidDisconnect(client: StompClient, error: Error?) {
        print("STOMP client did disconnect: error \(String(describing: error))")
        
        if state == .connected {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                if self.state == .connected && !client.isConnected {
                    client.connect()
                }
            })
        }
    }
}
