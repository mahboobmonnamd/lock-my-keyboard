# App icon set

macOS Retina icons use a **1x / 2x scale** pair for each point size. That scale is what Apple documents as `@2x` (see [High Resolution OS X](https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Optimizing/Optimizing.html)).

In this repo, on-disk filenames use `_1x` / `_2x` suffixes instead of `@2x`, and `Contents.json` maps each file to the correct `size` + `scale`. Xcode only cares about those JSON fields; the filename can be anything.

| Points | Scale | Pixels | File |
| --- | --- | --- | --- |
| 16 | 1x | 16 | `icon_16x16_1x.png` |
| 16 | 2x | 32 | `icon_16x16_2x.png` |
| 32 | 1x | 32 | `icon_32x32_1x.png` |
| 32 | 2x | 64 | `icon_32x32_2x.png` |
| 128 | 1x | 128 | `icon_128x128_1x.png` |
| 128 | 2x | 256 | `icon_128x128_2x.png` |
| 256 | 1x | 256 | `icon_256x256_1x.png` |
| 256 | 2x | 512 | `icon_256x256_2x.png` |
| 512 | 1x | 512 | `icon_512x512_1x.png` |
| 512 | 2x | 1024 | `icon_512x512_2x.png` |

Source master: `docs/assets/app-icon-1024.png`.
