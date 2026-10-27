// Pane's icon, drawn as editable vector geometry rather than a bitmap.
// The two pages read as Search's side-by-side view; the lens keeps the
// browser/search cue, and the blue-green plate separates it from Search.

import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Pane.iconset")
let document = CommandLine.arguments.dropFirst(2).first.map(URL.init(fileURLWithPath:))
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

let plate = NSColor(srgbRed: 0.075, green: 0.16, blue: 0.27, alpha: 1)
let paper = NSColor(srgbRed: 0.98, green: 0.96, blue: 0.89, alpha: 1)
let mint = NSColor(srgbRed: 0.39, green: 0.88, blue: 0.74, alpha: 1)
let ink = NSColor(srgbRed: 0.13, green: 0.22, blue: 0.33, alpha: 1)
let amber = NSColor(srgbRed: 1.0, green: 0.67, blue: 0.30, alpha: 1)

func rounded(_ context: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat,
             radius: CGFloat, color: NSColor) {
    context.setFillColor(color.cgColor)
    context.addPath(CGPath(roundedRect: CGRect(x: x, y: y, width: width, height: height),
                           cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.fillPath()
}

func draw(_ pixels: Int) -> NSImage {
    let scale = CGFloat(pixels) / 1024
    let image = NSImage(size: NSSize(width: pixels, height: pixels))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let context = NSGraphicsContext.current?.cgContext else { return image }
    context.saveGState()
    context.scaleBy(x: scale, y: scale)
    context.translateBy(x: 0, y: 1024)
    context.scaleBy(x: 1, y: -1)

    context.setShadow(offset: CGSize(width: 0, height: 10), blur: 24,
                      color: NSColor.black.withAlphaComponent(0.20).cgColor)
    rounded(context, x: 100, y: 100, width: 824, height: 824, radius: 184, color: plate)
    context.setShadow(offset: .zero, blur: 0, color: nil)

    // Two crisp, unequal pages and their quiet headers still read at Dock size.
    rounded(context, x: 216, y: 268, width: 286, height: 488, radius: 42, color: paper)
    rounded(context, x: 516, y: 268, width: 292, height: 488, radius: 42, color: mint)
    rounded(context, x: 252, y: 316, width: 50, height: 18, radius: 9, color: mint)
    rounded(context, x: 314, y: 316, width: 142, height: 18, radius: 9, color: ink.withAlphaComponent(0.25))
    rounded(context, x: 552, y: 316, width: 54, height: 18, radius: 9, color: paper)
    rounded(context, x: 618, y: 316, width: 144, height: 18, radius: 9, color: ink.withAlphaComponent(0.26))
    rounded(context, x: 252, y: 370, width: 178, height: 14, radius: 7, color: ink.withAlphaComponent(0.16))
    rounded(context, x: 552, y: 370, width: 154, height: 14, radius: 7, color: ink.withAlphaComponent(0.18))

    // A large, warm lens straddles the pages so the split remains visible
    // beneath it instead of becoming a generic two-card icon.
    context.setStrokeColor(amber.cgColor)
    context.setLineWidth(48)
    context.setLineCap(.round)
    context.addEllipse(in: CGRect(x: 540, y: 408, width: 220, height: 220))
    context.strokePath()
    context.move(to: CGPoint(x: 728, y: 596))
    context.addLine(to: CGPoint(x: 842, y: 708))
    context.strokePath()

    context.restoreGState()
    return image
}

func write(_ image: NSImage, to url: URL, pixels: Int) throws {
    guard let tiff = image.tiffRepresentation,
          let source = NSBitmapImageRep(data: tiff),
          let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                        isPlanar: false, colorSpaceName: .deviceRGB,
                                        bytesPerRow: 0, bitsPerPixel: 0)
    else { throw CocoaError(.fileWriteUnknown) }
    bitmap.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high
    source.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    try png.write(to: url)
}

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        let suffix = scale == 1 ? ".png" : "@2x.png"
        try write(draw(pixels), to: out.appendingPathComponent("icon_\(points)x\(points)\(suffix)"), pixels: pixels)
    }
}

if let document {
    let assets = document.appendingPathComponent("Assets")
    try? FileManager.default.removeItem(at: document)
    try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)

    let images: [(String, String)] = [
        ("left-pane.svg", #"<rect x="216" y="268" width="286" height="488" rx="42"/>"#),
        ("right-pane.svg", #"<rect x="516" y="268" width="292" height="488" rx="42"/>"#),
        ("details.svg", #"<rect x="252" y="316" width="50" height="18" rx="9"/><rect x="314" y="316" width="142" height="18" rx="9"/><rect x="552" y="316" width="54" height="18" rx="9"/><rect x="618" y="316" width="144" height="18" rx="9"/><rect x="252" y="370" width="178" height="14" rx="7"/><rect x="552" y="370" width="154" height="14" rx="7"/>"#),
        ("lens.svg", #"<circle cx="650" cy="518" r="86" fill="none" stroke="white" stroke-width="48"/><path d="M728 596L842 708" fill="none" stroke="white" stroke-width="48" stroke-linecap="round"/>"#),
    ]
    for (name, shape) in images {
        let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1024\" height=\"1024\" viewBox=\"0 0 1024 1024\"><g fill=\"white\">\(shape)</g></svg>"
        try svg.write(to: assets.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }

    let background = #"{ "solid" : "srgb:0.07500,0.16000,0.27000,1.00000" }"#
    let darkBackground = #"{ "solid" : "srgb:0.94000,0.93000,0.89000,1.00000" }"#
    func layer(_ name: String, image: String, light: String, dark: String, tinted: String) -> String {
        """
        { "name" : "\(name)", "image-name" : "\(image)", "glass" : false,
          "fill-specializations" : [
            { "value" : \(light) },
            { "appearance" : "dark", "value" : \(dark) },
            { "appearance" : "tinted", "value" : \(tinted) }
          ] }
        """
    }
    let ivory = #"{ "solid" : "srgb:0.98000,0.96000,0.89000,1.00000" }"#
    let deep = #"{ "solid" : "srgb:0.13000,0.22000,0.33000,1.00000" }"#
    let sea = #"{ "solid" : "srgb:0.39000,0.88000,0.74000,1.00000" }"#
    let teal = #"{ "solid" : "srgb:0.15000,0.62000,0.54000,1.00000" }"#
    let gold = #"{ "solid" : "srgb:1.00000,0.67000,0.30000,1.00000" }"#
    let white = #"{ "solid" : "srgb:1.00000,1.00000,1.00000,1.00000" }"#
    let json = """
    {
      "fill" : \(background),
      "fill-specializations" : [
        { "value" : \(background) },
        { "appearance" : "dark", "value" : \(darkBackground) }
      ],
      "groups" : [{
        "layers" : [
          \(layer("left pane", image: "left-pane.svg", light: ivory, dark: deep, tinted: white)),
          \(layer("right pane", image: "right-pane.svg", light: sea, dark: teal, tinted: white)),
          \(layer("page details", image: "details.svg", light: deep, dark: ivory, tinted: white)),
          \(layer("search lens", image: "lens.svg", light: gold, dark: gold, tinted: white))
        ],
        "shadow" : { "kind" : "none", "opacity" : 0.5 },
        "specular" : false,
        "translucency" : { "enabled" : false, "value" : 0.5 }
      }],
      "supported-platforms" : { "squares" : [ "macOS" ] }
    }
    """
    try json.write(to: document.appendingPathComponent("icon.json"), atomically: true, encoding: .utf8)
}

print("drew: \(out.path)")
