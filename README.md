# drc-wrapper
Drc wrapper is a simple bash script to ease DRC tool usage originally developed by Denis Sbragion

[http://drc-fir.sourceforge.net/](http://drc-fir.sourceforge.net/)

## Scope
Since original drc command is quite complicated to understand and it has a lot of parameters to tune a wrapper script can mitigate these problems.

## Properties
* Linux/OSX support
* impulse response microphone compensation support
* ability to choose a target curve
* few parameters to tune to achieve best result
* raw pcm and wav output filters
* corrected impulse response generation useful to analyze achieved result

for an easy analysis it is suggested to use REW software

[https://www.roomeqwizard.com/](https://www.roomeqwizard.com/)

## Dependencies
* [DRC](http://drc-fir.sourceforge.net/)
* sox

it is assumed that DRC is compiled and available in the standard PATH.

## Prerequisites
In order to get drcwrapper to work it is needed an impulse response of the room used for the listening. Drc is intended to be used with 441000 Hz files but other frequency configuration files are provided but they aren't tested. When exporting impulse response please be sure it is a signed integer 32 bit wav to achieve the best result.

## Optional prerequisites
* **microphone compensation curve:** used to correct distortion caused by the microphone
* **target curve:** a file specifying desired impulse response of the room in the listening point

### Target curve file example
```
0 0
16	10.225
20	9.375
25	11
31.5	9.5
40	10.5
50	9.425
63	7.5
80	5.325
100	4.575
125	3.325
160	2.6
200	2.5
250	2.025
315	1.75
400	1.675
500	1.675
630	1.325
800	1.67
1000	1.35
1250	1.25
1600	1.375
2000	1.525
2500	1.2
3150	1.2
4000	0.875
5000	0.125
6300	0
8000	-0.125
10000	-1.25
12500	-1.5
16000	-1.875
20000	-4.785
22050 0
```
every row of the file represents a mapping between frequency in Hz and its gain in dB relative to a flat curve. Notice that on the first row of the file frequency **must** be `0` and on the last row frequency **must** be sampling rate / 2, in this case `22050`.

## Usage
Most of the parameters here are derivated from the standard drc [doc](http://drc-fir.sourceforge.net/doc/drc.html), please read it for further explanation

### Example command
```bash
drcwrapper -b [...] -f [...] -c [...] -m [...] -t [...] -s [...] -e [...] -g [...] -p [...] -l [...] -u [...] IMPULSE
```

```bash
drcwrapper -b 32 -f 44100 -c normal -m ecm8000-44.1KHz.txt -t target_curve_file -s 40 -e 20000 -g 2 -p 0.85 -l 525 -u 1 Right32.wav
```

#### -b
This is the impulse response bit depth. Default is 32 bit but also 16 bit is good enough to achieve good result.

#### -f
Operating frequency or sampling rate, it determines:

* impulse response sampling rate
* filter sampling rate
* drc configuration file to use

default is 44100 Hz and it is the one tested in depth, other **not tested** options are:

* 44100
* 48000
* 88200
* 96000

#### -c
DRC configuration preset. Normal configuration is a good starting point to tune, insane is intended to be used just to show how sound artifacts are and not in a real scenario use case. Default is erb.

values are:

* minimal
* soft
* normal
* strong
* extreme
* insane
* erb

#### -m
Microphone compensation file used to correct impulse response before computing. This file follows the same rules explained in [Target curve file example](#target-curve-file-example)

#### -t
Target curve file used to manipulate filter in order to achieve the desiderated result. See [Target curve file example](#target-curve-file-example) for a better explaination.

#### -s
Lower end frequency that your speaker setup can reproduce. If you have a subwoofer consider the range extended. This parameter handles the minimum frequency where peak limiting stage starts to operate in order to prevent amplification and speaker overload. Default is 20 Hz.

For further explanation consult original documentation at [http://drc-fir.sourceforge.net/doc/drc.html#sec184](http://drc-fir.sourceforge.net/doc/drc.html#sec184)

#### -e
Higher end frequency that your speaker setup can reproduce. This parameter handles the maximum frequency where peak limiting stage ends to operate in order to prevent amplification and speaker overload. Default is 20000 Hz.

For further explanation consult original documentation at [http://drc-fir.sourceforge.net/doc/drc.html#sec185](http://drc-fir.sourceforge.net/doc/drc.html#sec185)

#### -g
Maximum gain allowed in the correction filter. Peaks in the correction filter amplitude response greater than this value will be compressed to PLMaxGain. Typical values are between 1.2 and 4. A typical value is 2.0, i.e. 6 dB. Default is 2.

For further explanation consult original documentation at [http://drc-fir.sourceforge.net/doc/drc.html#sec182](http://drc-fir.sourceforge.net/doc/drc.html#sec182)