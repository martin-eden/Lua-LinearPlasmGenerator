## What

(2024-11)

"Plasm" gradient filling for 1-d images.

![Image](Nice%20images/Plasm_1d.png)

Command-line tool to generate image of given width, height and random
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
  ImageHeight = 30,
  ImageWidth = 60,
  OutputFileName = 'Plasm_1d.ppm',
  RandomSeed = 1732580666,
  },
}
```

To specify image width (900) and height (150) use
```
$ lua Plasm_1d_ppm.lua 900 150
```

You can specify random seed (int64 range, 1234 here) as third parameter.
That's why we're printing config. With fixed random seed same image will
be generated every time

```
$ lua Plasm_1d_ppm.lua 900 150 1234
```

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


### wtf is .ppm format

Heh, Plain pixmap. It's opened fine by xViewer in Linux Mint. GIMP opens
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

More common usages I think is background for PowerPoint presentation, lol.
Just add logo and text.

I even found images generated by similar method as "digital art" which
some site wants to sell. That's even worse than PowerPoint presentation.


## Requirements

  * Lua 5.4

It does not use any OS-specific functions so may run even under Windows!


## See also

* [RGB stripe console][RgbStripeConsole] originally this code was born there
* [My other repositories][Repos] (Lua and Arduino C++)

[RgbStripeConsole]: https://github.com/martin-eden/Lua-RgbStripeConsole
[Repos]: https://github.com/martin-eden/contents
