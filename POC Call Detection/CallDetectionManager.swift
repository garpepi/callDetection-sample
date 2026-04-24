//
//  CallDetectionManager.swift
//  POC Call Detection
//
//  Created by Gar on 24/04/26.
//

import CallKit
import Combine

class CallDetectionManager: NSObject, ObservableObject, CXCallObserverDelegate {
    
    // MARK: - Published State
    @Published var isCallActive: Bool = false
    @Published var callState: CallState = .none
    private let callObserver = CXCallObserver()
    
    // MARK: - Call State Enum
    enum CallState {
        case none
        case incoming
        case outgoing
        case connected
        case onHold
        case ended
        
        var description: String {
            switch self {
            case .none:      return "No Call"
            case .incoming:  return "Incoming Call..."
            case .outgoing:  return "Outgoing Call..."
            case .connected: return "Call Active"
            case .onHold:    return "Call On Hold"
            case .ended:     return "Call Ended"
            }
        }
        
        var icon: String {
            switch self {
            case .none:      return "phone.slash"
            case .incoming:  return "phone.arrow.down.left"
            case .outgoing:  return "phone.arrow.up.right"
            case .connected: return "phone.fill"
            case .onHold:    return "pause.circle.fill"
            case .ended:     return "phone.down.fill"
            }
        }
    }
    
    // MARK: - Init
    override init() {
        super.init()
        callObserver.setDelegate(self, queue: .main)
    }
    
    // MARK: - CXCallObserverDelegate
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        updateCallState(from: call)
    }
    
    private func updateCallState(from call: CXCall) {
        if call.hasEnded {
            callState = .ended
            isCallActive = false
            // Reset to .none after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.callState == .ended {
                    self?.callState = .none
                }
            }
            return
        }
        
        if call.isOnHold {
            callState = .onHold
            isCallActive = true
            return
        }
        
        if call.hasConnected {
            callState = .connected
            isCallActive = true
            return
        }
        
        if call.isOutgoing {
            callState = .outgoing
            isCallActive = false
            return
        }
        
        // Incoming and not yet connected
        callState = .incoming
        isCallActive = false
    }
}
