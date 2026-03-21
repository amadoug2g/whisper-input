#!/usr/bin/swift
// Generates a 1024x1024 app icon PNG for Memo.
// A microphone with sound waves on a blue-purple gradient.
// Usage: swift generate-icon.swift <output-path>
import AppKit
import CoreGraphics

let output = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon.png"

let size: CGFloat = 1024
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(
    data: nil, width: Int(size), height: Int(size),
    bitsPerComponent: 8, bytesPerRow: 0, space: cs,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

// Flip to match AppKit coordinate system
ctx.translateBy(x: 0, y: size)
ctx.scaleBy(x: 1, y: -1)

// ── Background: rounded rect with blue-purple gradient ──────────────────────
let corner = size * 0.225
let bgPath = CGPath(
    roundedRect: CGRect(origin: .zero, size: CGSize(width: size, height: size)),
    cornerWidth: corner, cornerHeight: corner, transform: nil
)
ctx.addPath(bgPath)
ctx.clip()

let gradColors = [
    CGColor(red: 0.16, green: 0.28, blue: 0.94, alpha: 1),   // rich blue
    CGColor(red: 0.48, green: 0.16, blue: 0.86, alpha: 1),   // deep purple
] as CFArray
let gradient = CGGradient(colorsSpace: cs, colors: gradColors, locations: [0, 1])!
ctx.drawLinearGradient(gradient,
    start: CGPoint(x: 0, y: size),
    end:   CGPoint(x: size, y: 0),
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
)
ctx.resetClip()

// Re-clip to rounded rect for all drawing
ctx.addPath(bgPath)
ctx.clip()

let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
let whiteTranslucent = CGColor(red: 1, green: 1, blue: 1, alpha: 0.92)

// ── Mic capsule (centered, slightly left to make room for waves) ────────────
let lw: CGFloat = size * 0.042
ctx.setLineWidth(lw)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)

let micCenterX = size * 0.42
let micCenterY = size * 0.46

// Capsule body (filled)
let capsuleW = size * 0.16
let capsuleH = size * 0.28
let capsuleX = micCenterX - capsuleW / 2
let capsuleY = micCenterY - capsuleH * 0.35
let capsulePath = CGPath(
    roundedRect: CGRect(x: capsuleX, y: capsuleY, width: capsuleW, height: capsuleH),
    cornerWidth: capsuleW / 2, cornerHeight: capsuleW / 2, transform: nil
)
ctx.setFillColor(white)
ctx.addPath(capsulePath)
ctx.fillPath()

// Arc around capsule
ctx.setStrokeColor(whiteTranslucent)
let arcR = size * 0.155
let arcCenterY = capsuleY + capsuleH * 0.15
ctx.addArc(center: CGPoint(x: micCenterX, y: arcCenterY),
           radius: arcR, startAngle: .pi * 0.15, endAngle: .pi * 0.85, clockwise: true)
ctx.strokePath()

// Stem
let stemTop = arcCenterY - arcR
let stemBottom = stemTop - size * 0.06
ctx.move(to: CGPoint(x: micCenterX, y: stemTop))
ctx.addLine(to: CGPoint(x: micCenterX, y: stemBottom))
ctx.strokePath()

// Base
let baseW = size * 0.16
ctx.move(to: CGPoint(x: micCenterX - baseW / 2, y: stemBottom))
ctx.addLine(to: CGPoint(x: micCenterX + baseW / 2, y: stemBottom))
ctx.strokePath()

// ── Sound waves (3 arcs radiating from the right side of the mic) ───────────
let waveOriginX = micCenterX + capsuleW / 2 + size * 0.02
let waveOriginY = micCenterY + capsuleH * 0.1

for i in 0..<3 {
    let waveR = size * 0.09 + CGFloat(i) * size * 0.075
    let alpha = 0.9 - CGFloat(i) * 0.2
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: alpha))
    ctx.setLineWidth(lw * (1.0 - CGFloat(i) * 0.15))
    ctx.addArc(center: CGPoint(x: waveOriginX, y: waveOriginY),
               radius: waveR, startAngle: -.pi * 0.35, endAngle: .pi * 0.35, clockwise: false)
    ctx.strokePath()
}

// ── Export PNG ───────────────────────────────────────────────────────────────
ctx.resetClip()
let image = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(
    URL(fileURLWithPath: output) as CFURL, "public.png" as CFString, 1, nil
)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("Icon generated: \(output)")
