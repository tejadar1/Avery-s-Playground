import CoreGraphics

// Written by Art/spot.js (edit that, not this): the rooms in Spot It and where each thing that can change is.
// Spots are fractions of the picture; size is the thing's width or height, whichever is bigger, as a share of the width.
extension SpotTheDifference {
    static let rooms = [
        Room(name: "living", things: [
            Thing(id: "curtains", spot: CGPoint(x: 0.688, y: 0.300), size: 0.313, canHide: true, canRecolor: true),
            Thing(id: "frame", spot: CGPoint(x: 0.259, y: 0.217), size: 0.156, canHide: true, canRecolor: true),
            Thing(id: "clock", spot: CGPoint(x: 0.438, y: 0.175), size: 0.075, canHide: true, canRecolor: true),
            Thing(id: "garland", spot: CGPoint(x: 0.287, y: 0.096), size: 0.450, canHide: true, canRecolor: true),
            Thing(id: "lamp", spot: CGPoint(x: 0.522, y: 0.479), size: 0.356, canHide: false, canRecolor: true),
            Thing(id: "couch", spot: CGPoint(x: 0.275, y: 0.571), size: 0.412, canHide: false, canRecolor: true),
            Thing(id: "cushion1", spot: CGPoint(x: 0.181, y: 0.512), size: 0.100, canHide: true, canRecolor: true),
            Thing(id: "cushion2", spot: CGPoint(x: 0.362, y: 0.512), size: 0.100, canHide: true, canRecolor: true),
            Thing(id: "blanket", spot: CGPoint(x: 0.428, y: 0.579), size: 0.119, canHide: true, canRecolor: true),
            Thing(id: "plant", spot: CGPoint(x: 0.781, y: 0.608), size: 0.163, canHide: true, canRecolor: true),
            Thing(id: "books", spot: CGPoint(x: 0.906, y: 0.375), size: 0.125, canHide: true, canRecolor: true),
            Thing(id: "shelfbear", spot: CGPoint(x: 0.894, y: 0.512), size: 0.069, canHide: true, canRecolor: false),
            Thing(id: "vase", spot: CGPoint(x: 0.919, y: 0.658), size: 0.075, canHide: true, canRecolor: true),
            Thing(id: "rug", spot: CGPoint(x: 0.412, y: 0.892), size: 0.450, canHide: false, canRecolor: true),
            Thing(id: "table", spot: CGPoint(x: 0.412, y: 0.804), size: 0.313, canHide: false, canRecolor: false),
            Thing(id: "cup", spot: CGPoint(x: 0.316, y: 0.727), size: 0.044, canHide: true, canRecolor: true),
            Thing(id: "fruit", spot: CGPoint(x: 0.419, y: 0.719), size: 0.087, canHide: true, canRecolor: true),
            Thing(id: "book", spot: CGPoint(x: 0.519, y: 0.744), size: 0.063, canHide: true, canRecolor: true),
            Thing(id: "ball", spot: CGPoint(x: 0.725, y: 0.892), size: 0.063, canHide: true, canRecolor: true),
            Thing(id: "blocks", spot: CGPoint(x: 0.134, y: 0.879), size: 0.106, canHide: true, canRecolor: true),
            Thing(id: "teddy", spot: CGPoint(x: 0.850, y: 0.846), size: 0.119, canHide: true, canRecolor: true),
            Thing(id: "sock", spot: CGPoint(x: 0.631, y: 0.958), size: 0.063, canHide: true, canRecolor: true),
        ]),
        Room(name: "bedroom", things: [
            Thing(id: "curtains", spot: CGPoint(x: 0.719, y: 0.283), size: 0.250, canHide: true, canRecolor: true),
            Thing(id: "stars", spot: CGPoint(x: 0.516, y: 0.146), size: 0.169, canHide: true, canRecolor: true),
            Thing(id: "drawing", spot: CGPoint(x: 0.156, y: 0.175), size: 0.100, canHide: true, canRecolor: true),
            Thing(id: "shelfdino", spot: CGPoint(x: 0.166, y: 0.263), size: 0.081, canHide: true, canRecolor: true),
            Thing(id: "shelfball", spot: CGPoint(x: 0.259, y: 0.276), size: 0.044, canHide: true, canRecolor: true),
            Thing(id: "shelfbooks", spot: CGPoint(x: 0.353, y: 0.263), size: 0.094, canHide: true, canRecolor: true),
            Thing(id: "kite", spot: CGPoint(x: 0.769, y: 0.567), size: 0.150, canHide: true, canRecolor: true),
            Thing(id: "bed", spot: CGPoint(x: 0.275, y: 0.571), size: 0.450, canHide: false, canRecolor: true),
            Thing(id: "pillow", spot: CGPoint(x: 0.150, y: 0.512), size: 0.100, canHide: true, canRecolor: true),
            Thing(id: "bunny", spot: CGPoint(x: 0.300, y: 0.483), size: 0.075, canHide: true, canRecolor: true),
            Thing(id: "lamp", spot: CGPoint(x: 0.556, y: 0.533), size: 0.075, canHide: true, canRecolor: true),
            Thing(id: "clock", spot: CGPoint(x: 0.578, y: 0.563), size: 0.031, canHide: true, canRecolor: true),
            Thing(id: "rug", spot: CGPoint(x: 0.500, y: 0.883), size: 0.400, canHide: false, canRecolor: true),
            Thing(id: "toybox", spot: CGPoint(x: 0.750, y: 0.767), size: 0.150, canHide: false, canRecolor: true),
            Thing(id: "robot", spot: CGPoint(x: 0.719, y: 0.713), size: 0.044, canHide: true, canRecolor: true),
            Thing(id: "toyduck", spot: CGPoint(x: 0.784, y: 0.717), size: 0.044, canHide: true, canRecolor: true),
            Thing(id: "slippers", spot: CGPoint(x: 0.425, y: 0.817), size: 0.100, canHide: true, canRecolor: true),
            Thing(id: "drum", spot: CGPoint(x: 0.169, y: 0.863), size: 0.113, canHide: true, canRecolor: true),
            Thing(id: "cat", spot: CGPoint(x: 0.575, y: 0.867), size: 0.100, canHide: true, canRecolor: true),
        ]),
    ]
}
