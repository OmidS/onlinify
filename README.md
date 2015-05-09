# onlinify
Onlinify is a simple tool that make online data streaming from BCI2000 to MATLAB/Octave easy using fieldtrip buffer.

The only files you may need to edit are onlinifyOptions.m and processSignal.m (and possibly startup.m)

- onlinifyOptions.m is supposed to return all the options you want to change in a struct. If you want some option to be set to its default value, simply do not add it to that struct (userSettings).
You can also add additional options to it for your own usage in processSignal. All settings are available to processSignal as ws.settings

- processSignal.m is where all your processing happens. It is called with the latest block of signal given to it as an array of C in X (C rows are representative of the C Channels of the signal and X cols are representative of the X samples of each channel). Onlinify expects an string as the output from processSignal.
It is also passed an struct called ws (short for workspace) which can act as the exclusive workspace of the function which will be preserved between fuction calls. Additional explanation is available in processSignal.m

When those two files are ready, only make sure that onlinify.m is in the path and simply run it. 
It will wait until it detects BCI2000 signal coming through Fieldtrip and then it will gather the signal in blocks of processingBlockSec and pass it to processSignal.
Then it will show what processSignal returns in the results box. There are two types of results boxes: 
1. showResultsBox 
2. showEachOutput
As the names suggest, showResultsBox will add each output to the end of total output string and show them all in a strip in top of your last monitor and showEachOutput will show only the latest result received from processSignal in a box in the middle of your lartest monitor. You can enable each or both or none of them. 

* Monitor resolution and multiple monitors are handled automatically.

* Obviously, fieldtripbuffer and bci2000 must be available and they must be added to your MATLAB path. "startup.m" does just that. Typical usage senario is that you run "startup.m" once every time you open MATLAB to use onlinify.

Goodluck

Omid
