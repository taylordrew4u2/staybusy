//
//  StayBusyWidgetBundle.swift
//  StayBusyWidgets
//
//  Belongs to the StayBusyWidgets target ONLY.
//

import WidgetKit
import SwiftUI

@main
struct StayBusyWidgetBundle: WidgetBundle {
    var body: some Widget {
        RemainingBlocksWidget()
        StayBusyLiveActivity()
    }
}
