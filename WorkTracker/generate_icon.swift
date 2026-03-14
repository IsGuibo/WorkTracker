#!/usr/bin/env swift
/// 生成 AppIcon.icns — 甘特条主题图标
import AppKit

let outputDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath

let iconsetPath = "\(outputDir)/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

func makeIconData(size: Int) -> Data {
    let s = CGFloat(size)
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    ctx.interpolationQuality = .high

    // ── 圆角矩形背景 ──
    let r = s * 0.22
    let bgPath = CGMutablePath()
    bgPath.addRoundedRect(in: CGRect(x: 0, y: 0, width: s, height: s),
                          cornerWidth: r, cornerHeight: r)
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    // 蓝 → 靛紫 渐变
    let c1 = NSColor(calibratedRed: 0.14, green: 0.27, blue: 0.86, alpha: 1).cgColor
    let c2 = NSColor(calibratedRed: 0.42, green: 0.14, blue: 0.72, alpha: 1).cgColor
    let grad = CGGradient(colorsSpace: cs, colors: [c1, c2] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad,
                           start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0),
                           options: [])
    ctx.restoreGState()

    // ── 甘特条（CG 坐标 y 朝上，i=0 在底部） ──
    let barH  = s * 0.10
    let barGap = s * 0.08
    let mx    = s * 0.16          // 水平边距
    let availW = s - 2 * mx
    let bottomY = s * 0.18        // 最底条的 y（居中对齐）
    let cr = barH * 0.48

    // (xFrac, widthFrac, alpha)  — 从底到顶排列
    let bars: [(CGFloat, CGFloat, CGFloat)] = [
        (0.05, 0.45, 0.55),  // i=0 底：短，暗
        (0.20, 0.55, 0.90),  // i=1：偏移开始
        (0.00, 0.38, 0.50),  // i=2：很短，暗（暂停状态）
        (0.00, 0.75, 0.92),  // i=3 顶：最长，亮
    ]

    for (i, bar) in bars.enumerated() {
        let x = mx + bar.0 * availW
        let w = bar.1 * availW
        let y = bottomY + CGFloat(i) * (barH + barGap)
        let path = CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: barH),
                          cornerWidth: cr, cornerHeight: cr, transform: nil)
        ctx.setFillColor(NSColor(calibratedWhite: 1, alpha: bar.2).cgColor)
        ctx.addPath(path)
        ctx.fillPath()
    }

    let img = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: img)
    return rep.representation(using: .png, properties: [:])!
}

let sizes: [(String, Int)] = [
    ("icon_16x16", 16),    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),    ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, size) in sizes {
    let data = makeIconData(size: size)
    try! data.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name).png"))
    print("  ✓ \(name).png")
}

let icnsPath = "\(outputDir)/AppIcon.icns"
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetPath, "-o", icnsPath]
try! task.run()
task.waitUntilExit()

guard task.terminationStatus == 0 else {
    print("  ✗ iconutil 失败")
    exit(1)
}
print("  ✓ AppIcon.icns")
try? FileManager.default.removeItem(atPath: iconsetPath)
