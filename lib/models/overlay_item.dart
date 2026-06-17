enum OverlayPreviewKind { gifts }

class OverlayItem {
  const OverlayItem({
    required this.title,
    required this.url,
    required this.copyTooltip,
    this.browserUrl,
    this.preview,
  });

  final String title;
  final String url;
  final String copyTooltip;
  final String? browserUrl;
  final OverlayPreviewKind? preview;

  bool get hasPreview => preview != null;
}
