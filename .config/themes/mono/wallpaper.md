# Mono dune wallpaper

Status: provisional; native 4K generation remains pending.

`wallpaper.png` is the original, unmodified 1672×941 PNG from the built-in
image-generation tool. Two direct 3840×2160 requests returned this smaller
resolution. It has not been upscaled or presented as native 4K.

Generation mode: built-in `image_gen`, new image, no reference image.
Selected generation prompt:

> Required output size: 3840x2160 pixels, native 4K UHD landscape PNG. The previous generation returned only 1672x941, which does not satisfy this request. Generate directly at 3840x2160; do not resize or upscale a smaller image. Create an elegant desktop wallpaper for a theme named Mono: entirely neutral black-and-white photographic desert sand dunes with sculptural sweeping crests, soft silver light, deep charcoal shadows, subtle fine wind ripples, a restrained dark gray sky. Original composition inspired by the elegant minimal feeling of Apple's desert wallpapers. No colored tint, no people, no buildings, no vegetation, no text, no branding, no framing, no user interface. Final deliverable must be a full-resolution 3840x2160 PNG image.

The CLI/API fallback requires explicit user confirmation and a locally
configured OPENAI_API_KEY. Generate at 3840×2160 and replace the provisional
asset after verifying the resulting PNG dimensions; update this note then.
