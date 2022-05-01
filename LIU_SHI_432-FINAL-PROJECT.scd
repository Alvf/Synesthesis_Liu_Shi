/* BY ERIC LIU AND ALVIN SHI
 * ________       ___    ___ ________   _______   ________  _________  ___  ___  _______   ________  ___  ________
 *|\   ____\     |\  \  /  /|\   ___  \|\  ___ \ |\   ____\|\___   ___\\  \|\  \|\  ___ \ |\   ____\|\  \|\   ____\
 *\ \  \___|_    \ \  \/  / | \  \\ \  \ \   __/|\ \  \___|\|___ \  \_\ \  \\\  \ \   __/|\ \  \___|\ \  \ \  \___|_
 * \ \_____  \    \ \    / / \ \  \\ \  \ \  \_|/_\ \_____  \   \ \  \ \ \   __  \ \  \_|/_\ \_____  \ \  \ \_____  \
 *  \|____|\  \    \/  /  /   \ \  \\ \  \ \  \_|\ \|____|\  \   \ \  \ \ \  \ \  \ \  \_|\ \|____|\  \ \  \|____|\  \
 *    ____\_\  \ __/  / /      \ \__\\ \__\ \_______\____\_\  \   \ \__\ \ \__\ \__\ \_______\____\_\  \ \__\____\_\  \
 *   |\_________\\___/ /        \|__| \|__|\|_______|\_________\   \|__|  \|__|\|__|\|_______|\_________\|__|\_________\
 *   \|_________\|___|/                             \|_________|                             \|_________|   \|_________|
 *
 * Given python-processed image data, this scd uses some predefined synths to generate a corresponding soundscape.
*/


(
s.reboot;
s.waitForBoot {

/* --- variables and user-inputs here */


/* --- SynthDefs and other asynchronous stuff (loading files to buffers, evaluating code in related .scd files) ---*/

// toy piano taken from comb_piano in https://github.com/catfact/zebra/blob/master/lib/Engine_DreadMoon.sc#L20-L41
SynthDef(\toy_piano, {
	|out = 0, amp = 0.35, freq = 520, grain = 6000,
	tune_up = 1.0005, tune_down = 0.9996, len = 1,
	lpf_ratio = 2.0, lpf_rq = 4.0, hpf_hz = 20, damp=0.2, damp_time=0.1|

	var	damp_mul = LagUD.ar(K2A.ar(1.0 - damp), 0, damp_time);

	var noise_env = Decay2.ar(Impulse.ar(0));
	var noise = LFNoise2.ar(grain) * noise_env;

	var delaytime = 1.0 / (freq * [tune_up, tune_down]);
	var string = Mix.new(CombL.ar(noise, delaytime, delaytime, len * damp_mul));

	var snd = RLPF.ar(string, lpf_ratio * freq, lpf_rq) * amp;
	snd = HPF.ar(snd, hpf_hz);
	snd = Pan2.ar(snd);

	Out.ar(out, snd);
	DetectSilence.ar(snd, doneAction:2);
}
).add;

// Hue to synth: the synth-ification of RGB
SynthDef(\H_synth, {
		|out = 0, amp = 0.75, freq = 520, red = 0.5, green = 0.5, blue = 0.5, len = 0.3|
		var rgbTotal = red + green + blue;

		// Blue is sin
		var blueWeight = blue / rgbTotal;
		var blueSound = SinOsc.ar(freq/2) + SinOsc.ar(freq)*0.5;

		// Red is sawtooth
		var redWeight = red / rgbTotal;
		var redSound = Saw.ar(freq);

		// Green is squarewave
		var greenWeight = green / rgbTotal;
		var greenSound = Pulse.ar(freq);

		var intSound = (blueSound*blueWeight) + (redSound*redWeight) + (greenSound*greenWeight);

		var env = Env.new([0,1,1,0],[0.1,0.8,0.1]*len);
		var snd = intSound*env.kr()*amp;
		rgbTotal.postln();
		Out.ar(out, snd);
		DetectSilence.ar(snd, doneAction:2);
	}
	).add;

	// Process the xml into actual variables:
	  // Picking the 3 top hue clusters (HSV, position, radius)
      // H: Instrument type/waveform
      // S: Sound complexity/life (FM/Convolution/etc)
      // V: Filter (hi-pass/lo-pass)
      // Position: Pan2 and freeverb
      // Variance: Wideness/reverb/panning ratios

s.sync;

// CREATE THE SOUNDSCAPE

}

)

Synth(\toy_piano);
Synth(\H_synth,[\green,0,\red,0,\blue,100])