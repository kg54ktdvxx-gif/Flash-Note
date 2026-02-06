import SwiftUI

struct VoiceWaveformView: View {
    let audioLevel: Float
    let isRecording: Bool

    @State private var barHeights: [CGFloat] = Array(repeating: 0.1, count: 30)

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barHeights.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(isRecording ? AppColors.waveformActive : AppColors.waveformIdle)
                    .frame(width: 4, height: barHeights[index] * 40 + 4)
            }
        }
        .frame(height: 48)
        .onChange(of: audioLevel) { _, newLevel in
            guard isRecording else { return }
            withAnimation(.easeInOut(duration: 0.1)) {
                barHeights.removeFirst()
                barHeights.append(CGFloat(min(max(newLevel * 8, 0.05), 1.0)))
            }
        }
        .onChange(of: isRecording) { _, recording in
            if !recording {
                withAnimation(.easeOut(duration: 0.5)) {
                    barHeights = Array(repeating: 0.1, count: 30)
                }
            }
        }
    }
}
