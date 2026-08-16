import AppKit

let size = NSSize(width: 1024, height: 1024)
let outputPath = CommandLine.arguments.dropFirst().first ?? "ios/WorldGuideApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
    NSPoint(x: x, y: y)
}

let image = NSImage(size: size)
image.lockFocus()

let canvas = NSRect(origin: .zero, size: size)
NSGraphicsContext.current?.shouldAntialias = true

let background = NSGradient(colors: [
    color(12, 34, 41),
    color(22, 83, 82)
])!
background.draw(in: canvas, angle: -35)

let route = NSBezierPath()
route.move(to: point(176, 300))
route.curve(to: point(380, 390), controlPoint1: point(245, 384), controlPoint2: point(313, 292))
route.curve(to: point(608, 528), controlPoint1: point(456, 500), controlPoint2: point(536, 426))
route.curve(to: point(826, 726), controlPoint1: point(682, 632), controlPoint2: point(742, 720))
route.lineWidth = 42
route.lineCapStyle = .round
route.lineJoinStyle = .round
color(239, 232, 209, 0.22).setStroke()
route.stroke()

let routeCore = route.copy() as! NSBezierPath
routeCore.lineWidth = 18
color(239, 232, 209, 0.72).setStroke()
routeCore.stroke()

for marker in [
    NSRect(x: 150, y: 274, width: 52, height: 52),
    NSRect(x: 800, y: 700, width: 52, height: 52)
] {
    color(239, 232, 209).setFill()
    NSBezierPath(ovalIn: marker).fill()
}

let ringRect = NSRect(x: 238, y: 170, width: 548, height: 548)
let ring = NSBezierPath(ovalIn: ringRect)
ring.lineWidth = 36
color(239, 232, 209, 0.94).setStroke()
ring.stroke()

let innerRing = NSBezierPath(ovalIn: ringRect.insetBy(dx: 68, dy: 68))
innerRing.lineWidth = 8
color(239, 232, 209, 0.28).setStroke()
innerRing.stroke()

let north = NSBezierPath()
north.move(to: point(512, 772))
north.line(to: point(610, 474))
north.line(to: point(512, 416))
north.line(to: point(414, 474))
north.close()
color(239, 232, 209).setFill()
north.fill()

let south = NSBezierPath()
south.move(to: point(512, 256))
south.line(to: point(610, 474))
south.line(to: point(512, 416))
south.line(to: point(414, 474))
south.close()
color(228, 91, 74).setFill()
south.fill()

let center = NSBezierPath(ovalIn: NSRect(x: 462, y: 424, width: 100, height: 100))
color(12, 34, 41).setFill()
center.fill()
center.lineWidth = 12
color(239, 232, 209).setStroke()
center.stroke()

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("Unable to render app icon")
}

try png.write(to: URL(fileURLWithPath: outputPath))
