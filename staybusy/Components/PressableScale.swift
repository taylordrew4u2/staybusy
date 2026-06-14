//
//  PressableScale.swift
//  staybusy
//
//  Press feedback applied to every tappable surface in the app.
//  Routes timing through Theme.Motion so it respects Reduce Motion.
//

import SwiftUI

struct PressableScale: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? Theme.Opacity.pressed : 1)
            .animation(Theme.Motion.snap(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableScale {
    static var pressable: PressableScale { PressableScale() }
}
