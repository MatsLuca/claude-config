import Foundation
import Vision
import CoreImage

// Aufruf: docdetect BILD [--text]
// → JSON {confidence, corners:[tl,tr,br,bl]} (normiert, y nach unten); mit --text zusätzlich
//   lines:[{quad:[tl,tr,br,bl], text}] aus VNRecognizeTextRequest (Zeilen-/Wort-Boxen samt Neigung).
let args = CommandLine.arguments
guard args.count > 1, let ci = CIImage(contentsOf: URL(fileURLWithPath: args[1])) else {
    fputs("usage: docdetect BILD [--text]\n", stderr); exit(2)
}
let mitText = args.contains("--text")
// Für die Texterkennung reicht ~2200 px (schneller als 12 MP; Boxen sind normiert, also skalenfrei)
let maxSeite = max(ci.extent.width, ci.extent.height)
let skal = min(1.0, 2200.0 / maxSeite)
let bild = mitText && skal < 1 ? ci.transformed(by: CGAffineTransform(scaleX: skal, y: skal)) : ci
let handler = VNImageRequestHandler(ciImage: bild, options: [:])
let doc = VNDetectDocumentSegmentationRequest()
let txt = VNRecognizeTextRequest()
txt.recognitionLevel = .accurate
txt.usesLanguageCorrection = false
txt.recognitionLanguages = ["de-DE", "en-US"]
do { try handler.perform(mitText ? [doc, txt] : [doc]) } catch { fputs("Vision-Fehler: \(error)\n", stderr); exit(1) }
func p(_ q: CGPoint) -> String { String(format: "[%.5f,%.5f]", q.x, 1 - q.y) }
var out = "{"
if let obs = doc.results?.first {
    out += "\"confidence\":\(obs.confidence),\"corners\":[\(p(obs.topLeft)),\(p(obs.topRight)),\(p(obs.bottomRight)),\(p(obs.bottomLeft))]"
} else { out += "\"corners\":null" }
if mitText {
    var lines: [String] = []
    for o in txt.results ?? [] {
        let t = (o.topCandidates(1).first?.string ?? "").replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        lines.append("{\"quad\":[\(p(o.topLeft)),\(p(o.topRight)),\(p(o.bottomRight)),\(p(o.bottomLeft))],\"text\":\"\(t)\"}")
    }
    out += ",\"lines\":[\(lines.joined(separator: ","))]"
}
print(out + "}")
