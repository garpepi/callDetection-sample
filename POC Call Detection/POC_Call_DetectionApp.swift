//
//  POC_Call_DetectionApp.swift
//  POC Call Detection
//
//  Created by Gar on 24/04/26.
//

import SwiftUI

@main
struct POC_Call_DetectionApp: App {
    @StateObject private var callManager = CallDetectionManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(callManager)
        }
    }
}
