import SwiftUI

/// Stars (the child) or Hearts (the grown-up) in a Team Up game, with their score. Whose turn it is lights up.
struct PlayerBadge: View {
    let piece: TicTacToe.Piece
    let score: Int
    let isTurn: Bool

    var body: some View {
        HStack(spacing: 8 * uiScale) {
            Image(systemName: piece == .star ? "star.fill" : "heart.fill")
                .font(.system(size: 30 * uiScale, weight: .bold))
                .foregroundStyle(piece == .star ? Color(red: 0.98, green: 0.78, blue: 0.25) : Color(red: 0.93, green: 0.36, blue: 0.48))
                .shadow(color: Color.outline.opacity(0.6), radius: 0, x: 2, y: 2)
            Text(piece.team)
                .font(.kid(22))
                .foregroundStyle(Color.outline)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("\(score)")
                .font(.kid(22))
                .foregroundStyle(.white)
                .frame(minWidth: 36 * uiScale, minHeight: 36 * uiScale)
                .background(Color.outline.opacity(0.75), in: Circle())
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14 * uiScale)
        .frame(maxWidth: .infinity, minHeight: 60 * uiScale)
        .cartoonCard(isTurn ? Color(red: 1.0, green: 0.92, blue: 0.55) : .white, cornerRadius: 30 * uiScale)
        .scaleEffect(isTurn ? 1.05 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTurn)
        .accessibilityElement(children: .combine)
    }
}

extension TicTacToe.Piece {
    var other: Self { self == .star ? .heart : .star }
    var team: String { self == .star ? "Stars" : "Hearts" }
}
