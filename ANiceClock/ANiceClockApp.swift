    //
//  ANiceClockApp.swift
//  ANiceClock
//
//  Created by Steve Li on 6/17/25.
//

import SwiftUI

@main
struct ANiceClockApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // Default to dark mode for nightstand use
                .statusBarHidden() // Hide status bar for cleaner look
        }
    }
}
