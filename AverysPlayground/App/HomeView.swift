import SwiftUI

struct HomeView: View {
    private let columns = [GridItem(.adaptive(minimum: 150 * uiScale), spacing: 20 * uiScale)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24 * uiScale) {
                    HStack(spacing: 8 * uiScale) {
                        Image("Coco")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 130 * uiScale)
                            .accessibilityLabel("Coco the crocodile")
                        Text("Avery's Playground")
                            .font(.kid(36))
                            .foregroundStyle(Color.outline)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.top, 8 * uiScale)

                    LazyVGrid(columns: columns, spacing: 20 * uiScale) {
                        ForEach(Activity.allCases) { activity in
                            NavigationLink(value: activity) {
                                ActivityTile(activity: activity)
                            }
                            .buttonStyle(SquishyButtonStyle())
                            .simultaneousGesture(TapGesture().onEnded {
                                Speaker.shared.say(activity.title)
                            })
                        }
                    }
                }
                .padding(20 * uiScale)
            }
            .background(PlayfulBackground())
            .navigationDestination(for: Activity.self) { activity in
                activity.destination
                    .navigationTitle(activity.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .tint(Color.outline)
    }
}

private struct ActivityTile: View {
    let activity: Activity

    var body: some View {
        VStack(spacing: 4 * uiScale) {
            Image(activity.icon)
                .resizable()
                .scaledToFit()
                .frame(height: 120 * uiScale)
                .offset(y: -20 * uiScale)  // pops out over the top edge of the tile
                .padding(.bottom, -20 * uiScale)
                .accessibilityHidden(true)
            Text(activity.title)
                .font(.kid(24))
                .foregroundStyle(.white)
                .shadow(color: Color.outline, radius: 0, x: 2, y: 2)
        }
        .frame(maxWidth: .infinity, minHeight: 160 * uiScale)
        .cartoonCard(activity.color)
    }
}

#Preview {
    HomeView()
}
