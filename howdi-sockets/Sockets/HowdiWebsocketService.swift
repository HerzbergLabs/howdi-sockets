import Foundation

public class HowdiWebsocketService: NSObject, StompClientDelegate {
    
    public static let shared = HowdiWebsocketService()
    
    private var stompClient: StompClient?
    
    public func initializeService(url: String) {
        let client = StompClient(url: URL(string: url)!)
        
        client.delegate = self
        client.connect()
        
        self.stompClient = client
    }
    
    public func pauseEvents() {
        if stompClient?.isConnected ?? false {
            stompClient?.disconnect()
        }
    }
    
    public func resumeEvents() {
        if !(stompClient?.isConnected ?? false) {
            stompClient?.connect()
        }
    }
    
    public func stompClientDidConnect(client: StompClient) {
        print("STOMP client did connect")
    }
    
    public func stompClientDidReceiveJSONMessage(client: StompClient, destination: String, data: AnyObject, headers: [String : String]) {
        print("STOMP client did receive message: destination \(destination), data \(data) headers \(headers)")
    }
    
    public func stompClientDidEnqueueFrame(client: StompClient) {
        print("STOMP client did enqueue frame")
    }
    
    public func stompClientDidEncounterError(client: StompClient, error: Error) {
        print("STOMP client did encounter error \(error)")
    }
    
    public func stompClientDidDisconnect(client: StompClient, error: Error?) {
        print("STOMP client did disconnect: error \(String(describing: error))")
    }
}
