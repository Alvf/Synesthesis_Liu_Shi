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

//gargly low noise from Alvin's midterm
SynthDef(\growl,
	{|out = 0, amp = 0.7, freq = 520, len = 1, mufmul = 6|
		var fmod11 = SinOsc.ar(freq:6*freq, mul:freq*2);
		var fmod1 = SinOsc.ar(freq:1.025*freq+fmod11, mul:freq/2);
		var carrier1 = SinOsc.ar(freq:freq+fmod1, mul:amp/4);
		var env1 = Env.new([0,1,0.25,0],[0.01,0.04,0.54]*len);

		var fmod2 = SinOsc.ar(freq:freq/2, mul:freq/2);
		var amod2 = SinOsc.ar(freq:freq);
		var carrier2 = SinOsc.ar(freq:freq+fmod2, mul:2*amp/4)*(1+amod2);
		var env2 = Env.new([0,1,0.25,0],[0.01,0.04,0.95]*len);

		var amod3 = SinOsc.ar(freq:1.5*freq,add:1/4,mul:1/4);
		var carrier3 = SinOsc.ar(freq:freq, mul: amp/8)*(1/2+amod3);

		var amod4 = SinOsc.ar(freq:freq/4);
		var carrier4 = Saw.ar(freq:freq, mul: amp/8)*amod4;

		var snd = HPF.ar(LPF.ar(
			(carrier1+carrier4*env1.kr())+((carrier3 + carrier2)*env2.kr()),
			mufmul*freq),freq/20);
		snd = snd - BPF.ar(snd,freq*1,0.1);
		snd = Compander.ar(snd,snd,0.75,0.75,1.5);
		snd = Pan2.ar(snd);

		Out.ar(out, snd);
		DetectSilence.ar(snd, doneAction:2);
	}
).add;

// Steel drum from Alvin's finite amethyst midterm
SynthDef(\steeldrum,
	{|out = 0, amp = 0.45, freq = 520, len = 1, mufmul = 1, clunkmul = 0.1|

		// clink sound
		var fmod11 = SinOsc.ar(freq:10*freq, mul:freq*10);
		var fmod1 = SinOsc.ar(freq:2*freq+fmod11, mul:freq*0.75);
		var fmod2 = SinOsc.ar(freq:3*freq, mul:freq/2);
		var carrier1 = SinOsc.ar(freq:freq+fmod1, mul:amp/2);
		var carrier2 = SinOsc.ar(freq:4*freq+fmod2, mul:amp/2);

		var env1 = Env.new([0,1,0.75,0],[0.01,0.2,0.39,0.4]*len);
		var env2 = Env.new([0,1,0.75,0],[0.01,0.3,0.39,0.3]*len);
		var cling = LPF.ar((carrier1*env1.kr())+(carrier2*env2.kr()),freq*mufmul);

		// clunk attack
		var cfmod1 = SinOsc.ar(freq:3.17*freq, mul:freq/1);
		var cfmod2 = SinOsc.ar(freq:4.02*freq, mul:freq/2);
		var cfmod3 = SinOsc.ar(freq:7.15*freq, mul:freq/3);
		var ccarrier1 = SinOsc.ar(freq:freq+cfmod1, mul:amp*0.2*clunkmul);
		var ccarrier2 = SinOsc.ar(freq:freq+cfmod2, mul:amp*0.5*clunkmul);
		var ccarrier3 = SinOsc.ar(freq:freq+cfmod2, mul:amp*0.3*clunkmul);

		var cenv = Env.perc();
		var clunk = Decay2.ar((ccarrier1+ccarrier2+ccarrier3)*cenv.kr());

		//combinnig the two
		var snd = Mix.ar([cling,clunk]);
		snd = HPF.ar(snd,freq*2);

		Out.ar(out, snd);
		DetectSilence.ar(snd, doneAction:2);
}
).add;

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
		|out = 0, amp = 0.75, freq = 520, red = 0.5, green = 0.5, blue = 0.5, len = 1|
		var rgbTotal = red + green + blue;

		// Blue is steeldrum

		// clink sound
		var fmod11 = SinOsc.ar(freq:10*freq, mul:freq*10);
		var fmod1 = SinOsc.ar(freq:2*freq+fmod11, mul:freq*0.75);
		var fmod2 = SinOsc.ar(freq:3*freq, mul:freq/2);
		var carrier1 = SinOsc.ar(freq:freq+fmod1, mul:amp/2);
		var carrier2 = SinOsc.ar(freq:4*freq+fmod2, mul:amp/2);

		var env1 = Env.new([0,1,0.75,0],[0.01,0.2,0.39,0.4]*len);
		var env2 = Env.new([0,1,0.75,0],[0.01,0.3,0.39,0.3]*len);
		var cling = LPF.ar((carrier1*env1.kr())+(carrier2*env2.kr()),freq);

		// clunk attack
		var cfmod1 = SinOsc.ar(freq:3.17*freq, mul:freq/1);
		var cfmod2 = SinOsc.ar(freq:4.02*freq, mul:freq/2);
		var cfmod3 = SinOsc.ar(freq:7.15*freq, mul:freq/3);
		var ccarrier1 = SinOsc.ar(freq:freq+cfmod1, mul:amp*0.2*0.1);
		var ccarrier2 = SinOsc.ar(freq:freq+cfmod2, mul:amp*0.5*0.1);
		var ccarrier3 = SinOsc.ar(freq:freq+cfmod2, mul:amp*0.3*0.1);

		var cenv = Env.perc();
		var clunk = Decay2.ar((ccarrier1+ccarrier2+ccarrier3)*cenv.kr());

		//combinnig the two
		var blueSound = Mix.ar([cling,clunk]);

		var blueWeight = blue / rgbTotal;

		// Red is sawtooth
		var redWeight = red / rgbTotal;
		var redSound = Saw.ar(freq);

		// Green is growl

		var gfmod11 = SinOsc.ar(freq:6*freq, mul:freq*2);
		var gfmod1 = SinOsc.ar(freq:1.025*freq+gfmod11, mul:freq/2);
		var gcarrier1 = SinOsc.ar(freq:freq+gfmod1, mul:amp/4);
		var genv1 = Env.new([0,1,0.25,0],[0.01,0.04,0.54]*len);

		var gfmod2 = SinOsc.ar(freq:freq/2, mul:freq/2);
		var gamod2 = SinOsc.ar(freq:freq);
		var gcarrier2 = SinOsc.ar(freq:freq+gfmod2, mul:2*amp/4)*(1+gamod2);
		var genv2 = Env.new([0,1,0.25,0],[0.01,0.04,0.95]*len);

		var gamod3 = SinOsc.ar(freq:1.5*freq,add:1/4,mul:1/4);
		var gcarrier3 = SinOsc.ar(freq:freq, mul: amp/8)*(1/2+gamod3);

		var gamod4 = SinOsc.ar(freq:freq/4);
		var gcarrier4 = Saw.ar(freq:freq, mul: amp/8)*gamod4;

		var greenSound = HPF.ar(LPF.ar(
			(gcarrier1+gcarrier4*genv1.kr())+((gcarrier3 + gcarrier2)*genv2.kr()),
			6*freq),freq/20);
		var greenWeight = green / rgbTotal;

		var intSound = (blueSound*blueWeight) + (redSound*redWeight) + (greenSound*greenWeight);

		var env = Env.new([0,1,1,0],[0.1,0.8,0.1]*len);
		var fsnd = intSound*env.kr()*amp;
		Out.ar(out, fsnd);
		DetectSilence.ar(fsnd, doneAction:2);
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

(
~rbuf1 = Buffer.read(s, "./IMreverbs/Right Glass Triangle.wav".resolveRelative);
~size1 = 2048;
s.de
~bufsize1 = PartConv.calcBufSize(~size1, ~rbuf1);
~irspec1 = Buffer.alloc(s, ~bufsize1, 2);
~irspec1.preparePartConv(~rbuf1, ~size1);
SynthDef(\convFX1,
	{|out = 0, in = 21, mix = 0.5|
		var inSig = In.ar(in,2);
		var sig = PartConv.ar(inSig, ~size1, ~irspec1, mix)*0.025;
		var delay = 1 / (s.sampleRate / ~size1);
		var delayed = DelayN.ar(inSig, delay, delay)*(1-mix);
		Out.ar(out, [sig, delayed]);
	}
).add;
)

Synth(\convFX1);
(
// Synth(\steeldrum,[\out,21,\amp,4]);
// Synth(\toy_piano,[\out,21,\amp,0.35]);
Synth(\H_synth,[\green,100,\red,0,\blue,200,\out,21])
)