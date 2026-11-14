// Renders the app icon: a soft golden breath-orb on a night-indigo squircle.
import AppKit

let size = 1024.0
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext
let inset = 100.0
let rect = CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
let squircle = CGPath(roundedRect: rect, cornerWidth: 185, cornerHeight: 185, transform: nil)
ctx.addPath(squircle); ctx.clip()
let cs = CGColorSpaceCreateDeviceRGB()
let bg = CGGradient(colorsSpace: cs, colors: [
    CGColor(red: 0.16, green: 0.13, blue: 0.21, alpha: 1), CGColor(red: 0.06, green: 0.065, blue: 0.11, alpha: 1)] as CFArray,
    locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size), options: [])
let c = CGPoint(x: size / 2, y: size / 2 + 10)
let glow = CGGradient(colorsSpace: cs, colors: [
    CGColor(red: 0.98, green: 0.86, blue: 0.58, alpha: 1), CGColor(red: 0.92, green: 0.72, blue: 0.42, alpha: 0.55),
    CGColor(red: 0.92, green: 0.64, blue: 0.46, alpha: 0)] as CFArray, locations: [0, 0.35, 1])!
ctx.drawRadialGradient(glow, startCenter: c, startRadius: 0, endCenter: c, endRadius: 330, options: [])
ctx.setStrokeColor(CGColor(red: 0.95, green: 0.9, blue: 0.82, alpha: 0.35))
for (r, w) in [(250.0, 3.0), (310.0, 2.0)] {
    ctx.setLineWidth(w)
    ctx.strokeEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
}
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
