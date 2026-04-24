//
//  ContentView.swift
//  POC Call Detection
//
//  Created by Gar on 24/04/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var callManager: CallDetectionManager
    
    // For pulse animation on iOS 15
    @State private var isPulsing: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                callStatusCard
                callStateDetail
                
                Spacer()
            }
            .padding()
            .navigationTitle("Call Detector")
        }
    }
    
    // MARK: - Status Card
    private var callStatusCard: some View {
        VStack(spacing: 16) {
            Image(systemName: callManager.callState.icon)
                .font(.system(size: 56))
                .foregroundColor(statusColor)
                .scaleEffect(isPulsing ? 1.15 : 1.0)
                .animation(
                    callManager.isCallActive
                    ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
                    : .default,
                    value: isPulsing
                )
                .onChange(of: callManager.isCallActive) { active in
                    isPulsing = active
                }
            
            Text(callManager.callState.description)
                .font(.title2.bold())
                .foregroundColor(statusColor)
            
            // Active indicator badge
            if callManager.isCallActive {
                Label("Active", systemImage: "circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color.green)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - State Detail
    private var callStateDetail: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
            
            DetailRow(
                label: "Is Call Active",
                value: callManager.isCallActive ? "Yes" : "No",
                valueColor: callManager.isCallActive ? .green : .secondary
            )
            
            DetailRow(
                label: "Current State",
                value: callManager.callState.description
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Helper
    private var statusColor: Color {
        switch callManager.callState {
        case .none:      return .secondary
        case .incoming:  return .blue
        case .outgoing:  return .orange
        case .connected: return .green
        case .onHold:    return .yellow
        case .ended:     return .red
        }
    }
}

// MARK: - Reusable Row
struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CallDetectionManager())
}
