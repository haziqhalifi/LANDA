{{flutter_js}}
{{flutter_build_config}}

// Force SKWasm renderer to avoid CanvasKit context-lost runtime crashes.
_flutter.loader.load({
  config: {
    renderer: "skwasm",
  },
});
