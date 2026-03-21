#!/usr/bin/swift
// Generates a 1024×1024 app icon PNG.
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
    CGColor(red: 0.18, green: 0.32, blue: 0.96, alpha: 1),
    CGColor(red: 0.52, green: 0.18, blue: 0.88, alpha: 1),
] as CFArray
let gradient = CGGradient(colorsSpace: cs, colors: gradColors, locations: [0, 1])!
ctx.drawLinearGradient(gradient,
    start: CGPoint(x: size * 0.25, y: size),
    end:   CGPoint(x: size * 0.75, y: 0),
    options: []
)
ctx.resetClip()

// ── White mic shape ──────────────────────────────────────────────────────────
let lw: CGFloat = size * 0.048
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
ctx.setLineWidth(lw)
ctx.setLineCap(.round)

// Capsule body
let mw = size * 0.20, mh = size * 0.32
let mx = (size - mw) / 2, my = size * 0.40
let bodyPath = CGPath(
    roundedRect: CGRect(x: mx, y: my, width: mw, height: mh),
    cornerWidth: mw / 2, cornerHeight: mw / 2, transform: nil
)
ctx.addPath(bodyPath)
ctx.fillPath()

// Arc
let cx = size / 2, cy = my, r = size * 0.195
ctx.addArc(center: CGPoint(x: cx, y: cy), radius: r,
           startAngle: 0, endAngle: .pi, clockwise: true)
ctx.strokePath()

// Stand
let stemBottom = cy - r - size * 0.06
ctx.move(to: CGPoint(x: cx, y: cy - r))
ctx.addLine(to: CGPoint(x: cx, y: stemBottom))
ctx.strokePath()

// Base
let bw = size * 0.22
ctx.move(to: CGPoint(x: cx - bw / 2, y: stemBottom))
ctx.addLine(to: CGPoint(x: cx + bw / 2, y: stemBottom))
ctx.strokePath()

// ── Export PNG ───────────────────────────────────────────────────────────────
let image = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(
    URL(fileURLWithPath: output) as CFURL, "public.png" as CFString, 1, nil
)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("✓ \(output)")
