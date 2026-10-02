//
//  CallDetectionManager.swift
//  POC Call Detection
//
//  Created by Gar on 24/04/26.
//

import CallKit
import Combine
import OSLog
import UIKit

class CallDetectionManager: NSObject, ObservableObject, CXCallObserverDelegate {
    
    // MARK: - Published State
    /// Whenever a connected or on-hold call is detected, `isCallActive` will be set to `true`.
    @Published var isCallActive: Bool = false
    @Published var callState: CallState = .none
    
    static let shared = CallDetectionManager()
    private var callObserver: CXCallObserver?
    private var cancellables: Set<AnyCancellable> = []
    
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
        observeCallStateChanges()
        observeAppLifecycle()
    }
    
    /// Initializes the call observer and evaluates any active calls at launch.
    /// Sets up a `CXCallObserver` delegate to monitor ongoing call state changes.
    /// If a call is already in progress when the app starts, updates
    /// `isCallActive` accordingly, and presents a blocking page informing the user
    /// that the app can't be used if a connected or on-hold call is detected.
    func start() {
        Logger.callDetectionManager.info("Call Detection Manager started")
        if callObserver == nil {
            let observer = CXCallObserver()
            observer.setDelegate(self, queue: .main)
            callObserver = observer
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            Logger.callDetectionManager.info("Detecting any existing call at launch")
            self?.reconcileCallState()
        }
    }
    
    private func reconcileCallState() {
        let calls = callObserver?.calls ?? []
        let hasActiveCall = calls.contains { ($0.hasConnected || $0.isOnHold) && !$0.hasEnded }
        Logger.callDetectionManager.info("Reconciling call state. isCallActive : \(hasActiveCall)")
        isCallActive = hasActiveCall
    }
    
    private func observeCallStateChanges() {
        $isCallActive
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isActive in
                guard let self else { return }
                if isActive {
                    // showCallDetectionView()
                } else {
                    // removeCallDetectionView()
                }
            })
            .store(in: &cancellables)
    }
    
    private func observeAppLifecycle() {
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                reconcileCallState()
                if !isCallActive {
                    // removeCallDetectionView()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - CXCallObserverDelegate
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        updateCallState(from: call)
        reconcileCallState()
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
