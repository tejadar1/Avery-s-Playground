import SwiftUI

struct HomeView: View {
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 20)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        Image("Coco")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 130)
                            .accessibilityLabel("Coco the crocodile")
                        Text("Avery's Playground")
                            .font(.kid(36))
                            .foregroundStyle(Color.outline)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 20) {
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
                .padding(20)
            }
            .background(PlayfulBackground())
            .navigationDestination(for: Activity.self) { activity in
                activity.destination
                    .navigationTitle(activity.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(activity.color, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
            }
        }
        .tint(.white)
    }
}

private struct ActivityTile: View {
    let activity: Activity

    var body: some View {
        VStack(spacing: 8) {
            Text(activity.emoji)
                .font(.system(size: 64))
            Text(activity.title)
                .font(.kid(24))
                .foregroundStyle(.white)
                .shadow(color: Color.outline, radius: 0, x: 2, y: 2)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .cartoonCard(activity.color)
    }
}

#Preview {
    HomeView()
}
