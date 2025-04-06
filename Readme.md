## What

(2024-11, 2024-12, 2025-04)

"Plasm" gradient filling for 1-d images.

![Image][SampleImage]

Command-line tool to generate image by given width, height and random
seed.

## How to use

### Basic usage

```
$ lua Plasm_1d_ppm.lua
```
will use random seed and create/overwrite `Plasm_1d.ppm` image file.
Also it will print something like

```
Config = {
  ColorFormat = 'Rgb',
  ImageHeight = 10,
  ImageWidth = 60,
  OutputFileName = 'Plasm_1d.ppm',
  RandomSeed = 1743896375,
}
```

### Arguments

All values from `Config` except `OutputFileName` can be passed
as positional parameters. Sequence is

`ImageWidth ImageHeight ColorFormat RandomSeed`

For example to specify `ImageWidth` (900) and `ImageHeight` (150) call
```
$ lua Plasm_1d_ppm.lua 900 150
```

Third optional argument is `ColorFormat`. `Rgb` for RGB and `Gs`
for grayscale. (Grayscale is more sexy to my taste as you can directly
treat values as relief height.)

Fourth optional argument is `RandomSeed` (int64). With same random
seed, image width and color format you will get same result. That's
why we are printing config. You can store just several bytes to
recreate image.


### Advanced usage

Tweak [Plasm_1d_ppm.lua](Plasm_1d_ppm.lua)!

Important things there are parameters for plasm generator:
`Scale` and `TransformDistance` function.


### How it works

Recursive divisions. Each time we'll set middle pixel as average of
border pixels plus noise. Noise is the essence. Noise amplitude depends
of current segment length. Typically, shorter segment means less noise
potential.

Instead of spending words, I left code in [LinearPlasmGenerator](LinearPlasmGenerator/).


### Wtf is .ppm format?!

Huh, Plain pixmap. It's opening fine by xViewer in Linux Mint. GIMP opens
it fine too.

If you bother to install `netpbm` package you can convert `.ppm` to `.png`
from command-line:

```
$ pnmtopng Plasm_1d.ppm > Plasm_1d.png
```


### How it can be used

I'm using it to generate pattern for RGB LED stripe above by monitor.
And then scroll it smoothly. See my [RGB stripe console][RgbStripeConsole]
project.

I think more common usages is background for PowerPoint presentation, lol.
Just add logo and text.

I even found images generated by similar method as "digital art" which
one site tries to sell. That's even worse than PowerPoint presentations.


## Requirements

  * Lua 5.3

It does not use any OS-specific functions so may run even under Windows!


## Bonus stuff

[DisplayPpm][DisplayPpm] - quick script to display `.ppm` in console
while you're rolling plasm generation.

Example:
```
lua Plasm_1d_ppm.lua 160 15; lua DisplayPpm.lua
```
![ConsoleSample][ConsoleSample]

That's text terminal guys! (There are fancy ANSI codes extension
to set colors in RGB.)

Sorry Windows users, I don't think it will work on your system.


## See also

* [RGB stripe console][RgbStripeConsole] originally this code was born there
* [My other repositories][Repos] (Lua and Arduino C++)

[DisplayPpm]: DisplayPpm.lua
[ConsoleSample]: BlaBlaImages/ConsoleSample.png
[SampleImage]: BlaBlaImages/Plasm_1d.png
[RgbStripeConsole]: https://github.com/martin-eden/Lua-RgbStripeConsole
[Repos]: https://github.com/martin-eden/contents
