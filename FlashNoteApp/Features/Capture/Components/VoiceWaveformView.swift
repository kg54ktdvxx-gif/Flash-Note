import SwiftUI

struct VoiceWaveformView: View {
    let audioLevel: Float
    let isRecording: Bool

    @State private var barHeights: [CGFloat] = Array(repeating: 0.08, count: 48)

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barHeights.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(isRecording ? AppColors.waveformActive : AppColors.waveformIdle)
                    .frame(width: 2, height: barHeights[index] * 36 + 2)
            }
        }
        .frame(height: 44)
        .onChange(of: audioLevel) { _, newLevel in
            guard isRecording else { return }
            withAnimation(.easeInOut(duration: 0.08)) {
                barHeights.removeFirst()
                barHeights.append(CGFloat(min(max(newLevel * 8, 0.03), 1.0)))
            }
        }
        .onChange(of: isRecording) { _, recording in
            if !recording {
                withAnimation(.easeOut(duration: 0.4)) {
                    barHeights = Array(repeating: 0.08, count: 48)
                }
            }
        }
    }
}
