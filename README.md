# drc-wrapper

**drc-wrapper** is a simple Bash script designed to simplify the usage of the DRC (Digital Room Correction) tool originally developed by Denis Sbragion.

[http://drc-fir.sourceforge.net/](http://drc-fir.sourceforge.net/)

## Scope

The original `drc` command involves complex configuration files and dozens of parameters. `drc-wrapper` abstracts this complexity into a straightforward CLI tool, calculating necessary window sizes, handling file conversions automatically, and producing ready-to-use filter outputs.

## Features

* Linux & macOS support (automatically detects OS configuration paths).
* Automated file conversions via SoX (supports signed 32-bit WAV input, outputs 32-bit float PCM and 16-bit WAV).
* Microphone compensation curve support.
* Target curve customization (defaults to a flat response if omitted).
* Dynamic output directory generation based on timestamps to prevent accidental overwrites.
* Generates test convolutions and minimum phase response filters for easy analysis in tools like REW (Room EQ Wizard).

## Dependencies

Before running the wrapper, ensure you have the following CLI tools installed and available in your standard system PATH:

* DRC FIR ([http://drc-fir.sourceforge.net/](http://drc-fir.sourceforge.net/))
* SoX (Sound eXchange - [http://sox.sourceforge.net/](http://sox.sourceforge.net/))
* bc (An arbitrary precision calculator language)

## Prerequisites

To use drc-wrapper, you need an impulse response WAV file of your listening room.

* Sampling Rate: DRC works best with 44100 Hz files (other sample rates are supported via configuration files, but are untested).
* Format: For best results, export your room impulse response as a 32-bit signed integer WAV file.

## Optional Files

### Microphone Compensation File (-m)
Used to correct amplitude non-linearities introduced by your measurement microphone.

### Target Curve File (-t)
Specifies the desired room frequency response at the listening position. If omitted, drc-wrapper automatically generates a flat curve target file (0 -30 dB to Nyquist -30 dB).

Target Curve Example Format:
```
0 0
16  10.225
20  9.375
25  11
31.5    9.5
40  10.5
50  9.425
63  7.5
80  5.325
100 4.575
125 3.325
160 2.6
200 2.5
250 2.025
315 1.75
400 1.675
500 1.675
630 1.325
800 1.67
1000    1.35
1250    1.25
1600    1.375
2000    1.525
2500    1.2
3150    1.2
4000    0.875
5000    0.125
6300    0
8000    -0.125
10000   -1.25
12500   -1.5
16000   -1.875
20000   -4.785
22050 0
```

* Each row maps a frequency in Hz to its gain in dB.
* The first row MUST start at 0 Hz.
* The last row MUST end at your Nyquist frequency (sample_rate / 2), e.g., 22050 Hz for 44.1 kHz.

---

## Usage

Most parameters are derived directly from the official DRC documentation ([http://drc-fir.sourceforge.net/doc/drc.html](http://drc-fir.sourceforge.net/doc/drc.html)).

### Syntax

```bash
drcwrapper -l <ms> -u <ms> [OPTIONS] IMPULSE_FILE.wav
```

### Example Command

```bash
drcwrapper -b 32 -f 44100 -c normal -m ecm8000-44.1KHz.txt -t target_curve.txt -s 40 -e 20000 -g 2 -p 0.85 -l 525 -u 1 -o ./output Right32.wav
```

---

## Command-Line Arguments

### Required Arguments
* -l `<ms>`: Lower correction window in milliseconds. Automatically computes dependent window taps.
* -u `<ms>`: Upper correction window in milliseconds.

### Optional Arguments
* -b `<bit_depth>`: Impulse response bit depth. Default is 32 bit, but also 16 bit is good enough to achieve good result.
* -f `<frequency>`: Operating frequency or sampling rate, it determines impulse response sampling rate, filter sampling rate, and drc configuration file to use. Default is 44100 Hz and it is the one tested in depth. Other untested options are: ```44100, 48000, 88200, 96000```.
* -c `<preset>`: DRC configuration preset. Normal configuration is a good starting point to tune, insane is intended to be used just to show how sound artifacts are and not in a real scenario use case. Default is erb. Values are: ```minimal, soft, normal, strong, extreme, insane, erb```.
* -m `<path>`: Microphone compensation file used to correct impulse response before computing. This file follows the same rules explained in [Target curve file example](#target-curve-file-example).
* -t `<path>`: Target curve file used to manipulate filter in order to achieve the desired result. See [Target curve file example](#target-curve-file-example) for a better explanation.
* -s `<freq>`: Lower end frequency that your speaker setup can reproduce. If you have a subwoofer consider the range extended. This parameter handles the minimum frequency where peak limiting stage starts to operate in order to prevent amplification and speaker overload. Default is 20 Hz. For further explanation consult original documentation at [http://drc-fir.sourceforge.net/doc/drc.html#sec184](http://drc-fir.sourceforge.net/doc/drc.html#sec184)
* -e `<freq>`: Higher end frequency that your speaker setup can reproduce. This parameter handles the maximum frequency where peak limiting stage ends to operate in order to prevent amplification and speaker overload. Default is 20000 Hz. For further explanation consult original documentation at [http://drc-fir.sourceforge.net/doc/drc.html#sec185](http://drc-fir.sourceforge.net/doc/drc.html#sec185)
* -g `<gain>`: Maximum gain allowed in the correction filter. Peaks in the correction filter amplitude response greater than this value will be compressed to PLMaxGain. Typical values are between 1.2 and 4. A typical value is 2.0, i.e. 6 dB. Default is 2. For further explanation consult original documentation at [http://drc-fir.sourceforge.net/doc/drc.html#sec182](http://drc-fir.sourceforge.net/doc/drc.html#sec182)
* -p `<exp>`: Window exponent. Increasing it gives higher correction in the midrange. Typical values are between 0.7 and 1.2. Default is 1.
* -o `<path>`: Add drcwrapper working directory.

---

## Output Structure

The script automatically generates a timestamped directory (e.g., drc_out_1700000000/) containing:

1. 32-bit Float PCM Files: Raw intermediate files generated directly by DRC.
2. wav/ Subdirectory: Automatically converted 16-bit WAV files ideal for direct import into REW (Room EQ Wizard) or convolution engines:
   * `<filename>`_mic_compensated_impulse_response.wav: Pre-filtered impulse response.
   * `<filename>`.wav: Final generated correction filter.
   * `<filename>`_minimum_phase.wav: Minimum phase response output.
   * `<filename>`_test_convolution.wav: Simulated result of applying the correction filter to the original room impulse response.
