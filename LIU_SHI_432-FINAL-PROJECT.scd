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
s.options.memSize = 2.pow(20);
s.waitForBoot {
/* --- variables and user-inputs here */
	~bufF = Buffer.read(s, "./IMreverbs/In The Silo.wav".resolveRelative); // Forest
	~bufS = Buffer.read(s, "./IMreverbs/Right Glass Triangle.wav".resolveRelative); // Sea
	~bufG = Buffer.read(s, "./IMreverbs/On a Star.wav".resolveRelative); // Glacier
	~bufM = Buffer.read(s, "./IMreverbs/Parking Garage.wav".resolveRelative); // Mountain
	~bufO = Buffer.read(s, "./IMreverbs/Masonic Lodge.wav".resolveRelative); // Other
	~rbuf = [~bufF, ~bufS, ~bufG, ~bufM, ~bufO];

/* --- SynthDefs and other asynchronous stuff (loading files to buffers, evaluating code in related .scd files) ---*/

// Hue to synth: the synth-ification of RGB
SynthDef(\H_synth, {
		|out = 0, amp = 0.75, freq = 520, red = 0.5, green = 0.5, blue = 0.5, len = 1, pan = 0.5, lmuf = 6, hmuf = 6|
		var rgbTotal = red + green + blue;

		// Blue is steeldrum

		// clink sound
		var fmod11 = SinOsc.ar(freq:10*freq, mul:freq*10);
		var fmod1 = SinOsc.ar(freq:2*freq+fmod11, mul:freq*0.75);
		var fmod2 = SinOsc.ar(freq:3*freq, mul:freq/2);
		var carrier1 = SinOsc.ar(freq:freq+fmod1, mul:amp);
		var carrier2 = SinOsc.ar(freq:4*freq+fmod2, mul:amp);

		var env1 = Env.new([0,1,0.75,0],[0.01,0.2,0.39,0.4]*len);
		var env2 = Env.new([0,1,0.75,0],[0.01,0.3,0.39,0.3]*len);
		var cling = LPF.ar((carrier1*env1.kr())+(carrier2*env2.kr()),freq);

		var blueSound = cling;

		var blueWeight = blue / rgbTotal;

		// Red is guitar-y (using pluck)
		var redWeight = red / rgbTotal;

		var renv = Env.new([0,1,0.75,0.75,0],[0.1,0.1,0.7,0.1]*len);

		var rsnd1 = Pluck.ar( in: BrownNoise.ar(amp*2),
        trig: Impulse.kr(0),
        maxdelaytime: 0.1,
		delaytime: (freq/2).reciprocal,
        decaytime: len,
        coef: 0.1);

		var rsnd2 = Pluck.ar( in: PinkNoise.ar(amp*2),
        trig: Impulse.kr(0),
        maxdelaytime: 0.1,
        delaytime: freq.reciprocal,
        decaytime: len,
        coef: 0.1);

		var rcarrier = 0.5*(rsnd1 + rsnd2)*renv.kr();

		var redSound = rcarrier;

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
		var valMuf = Env.new([lmuf,hmuf,lmuf],[0.5,0.5]*len);
		var fsnd = LPF.ar(intSound*env.kr()*amp,freq*valMuf.kr());
		Out.ar(out, Pan2.ar(fsnd,pan));
		DetectSilence.ar(fsnd, doneAction:2);
	}
	).add;

// Testing pluck.ar for use in red
SynthDef(\pluck, {
		|out = 0, amp = 0.1, freq = 212, len = 1, coef = 0.1|
var env = EnvGen.kr(Env.linen(0, len, 0));
var snd1 = Pluck.ar( in: BrownNoise.ar(amp/4),
        trig: Impulse.kr(0),
        maxdelaytime: 0.1,
        delaytime: freq.reciprocal,
        decaytime: len,
        coef: coef);
var snd2 = Pluck.ar( in: PinkNoise.ar(amp/4),
        trig: Impulse.kr(0),
        maxdelaytime: 0.1,
        delaytime: freq.reciprocal,
        decaytime: len,
        coef: coef);
    Out.ar(out, [snd1, snd2]);
}).add;

	// Process the xml into actual variables:
	  // Python gets the clusters clusterFile[x]
	  // Picking the 3 top hue clusters (HSV, position, radius)
	  // H: Instrument type/waveform (RGB)
	  // S: Fitering (LPF threshold)
	  // V: the bass/hi-ness of the cluster (Octave)
	  // Position: (x)Pan2 and (y)wet/dry of reverb
	  // Cluster occupation: how much of the image each cluster occupies (determines firing rate for the cluster with some math)
	  // Entropy (greyscale) for tempo; Entropy R, G, B for firing frequency

~clusterFile = CSVFileReader.readInterpret("./data/test_2_output_1.csv".resolveRelative, startRow: 1, skipBlanks: true, skipEmptyLines: true);

	~r1 = ~clusterFile[0][0];
	~g1 = ~clusterFile[0][1];
	~b1 = ~clusterFile[0][2];
	~ls1 = ~clusterFile[0][3];
	~hs1 = ~clusterFile[0][4];
	~lv1 = ~clusterFile[0][5];
	~hv1 = ~clusterFile[0][6];
	~pan1 = ~clusterFile[0][7];
	~reverb1 = ~clusterFile[0][8];
	~t1 = 5/~clusterFile[0][9] + 10;

	~r2 = ~clusterFile[1][0];
	~g2 = ~clusterFile[1][1];
	~b2 = ~clusterFile[1][2];
	~ls2 = ~clusterFile[1][3];
	~hs2 = ~clusterFile[1][4];
	~lv2 = ~clusterFile[1][5];
	~hv2 = ~clusterFile[1][6];
	~pan2 = ~clusterFile[1][7];
	~reverb2 = ~clusterFile[1][8];
	~t2 = 5/~clusterFile[1][9] + 10;

	~r3 = ~clusterFile[2][0];
	~g3 = ~clusterFile[2][1];
	~b3 = ~clusterFile[2][2];
	~ls3 = ~clusterFile[2][3];
	~hs3 = ~clusterFile[2][4];
	~lv3 = ~clusterFile[2][5];
	~hv3 = ~clusterFile[2][6];
	~pan3 = ~clusterFile[2][7];
	~reverb3 = ~clusterFile[2][8];
	~t3 = 5/~clusterFile[2][9] + 10;

~entropyFile = CSVFileReader.readInterpret("./data/test_2_output_2.csv".resolveRelative, startRow: 1, skipBlanks: true, skipEmptyLines: true);

	~grayEnt = ~entropyFile[0][0];
	~rEnt = ~entropyFile[0][1];
	~gEnt = ~entropyFile[0][2];
	~bEnt = ~entropyFile[0][3];
	~rbuf1 = ~rbuf.choose; //Reverb for user/just picked randomly.

	s.sync;
// Fiddly reverbers need to sync up with some impulse response buffer reading
	~size1 = 2048;
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

/*	// Testing what it'd be like to get a sound directly from the image FFT
~aRoll = CSVFileReader.readInterpret("spectrum_test.csv".resolveRelative, startRow: 1, skipBlanks: true, skipEmptyLines: true)[0];
~aRoll;
	s.sync;
//Testing what just making a straight up ifft thing would sound like
SynthDef(\spec_test,
	{|freq = 520, amp = 0.35, out = 0|
		var snd = Mix.fill(~aRoll.size,
				{|i| SinOsc.ar(freq:freq*(i + 1),mul: ~aRoll[i].dbamp;)});
		Out.ar(out, [snd, snd]);
	}
).add;*/



// CREATE THE SOUNDSCAPE


// spanning two octaves centered at middle C
	~seqliblib = [
		[50, 53, 57, 59, 62, 65, 69, 71, 74], // C Eb G A C (Ocarina of Time) [Forest]
		[50, 54, 57, 61, 62, 66, 69, 73, 74], // C E G B C (V7M-ish) [Sea]
		[50, 52, 54, 57, 59, 62, 64, 66, 69, 71, 72], // C D E G A C (Pentatonic) [Glacier]
		[50, 52, 55, 58, 62, 64, 67, 70, 74], // C D F G# C [Mountain]
		Array.series(25,start:50,step:1)// Chromatic [Other]
	];

	~seqlibrary = ~seqliblib.choose; //picks notes randomly or according to user
// various speeds to pull
~speedlibrary = [1, 1/2, 1/4, 1/3];

~transposelibrary = [-12, -8, -7, -5, 0, 4, 5, 7, 12];

~tc = TempoClock.default;
~tc.tempo = ~grayEnt*100/15/60; //greyscale entropy value;

// Cluster 1 scheduler
~tc.sched(0,
	{
		var lnotes = rrand(2, ~rEnt); //run len determined by color channel entropy
		var transposeval = ~transposelibrary[rrand(~lv1,~hv1)];
		var noteseq = Array.fill(lnotes, {~seqlibrary.choose}) + transposeval;
		var lens = Array.fill(lnotes, {~speedlibrary.choose});
		var durs = lens.copy;
		durs[lnotes-1] = durs[lnotes-1]+15;
		"cluster 1 firing!".postln;
		Pfx(Pseq([Pbind(
			\instrument, \H_synth,
			\red,Pseq([~r1],lnotes),
			\green,Pseq([~g1],lnotes),
			\blue,Pseq([~b1],lnotes),
			\lmuf,Pseq([~ls1+1],lnotes),
			\hmuf,Pseq([~hs1*10],lnotes),
			\pan,Pseq([~pan1],lnotes),
			\midinote,Pseq(noteseq),
			\out,Pseq([21],lnotes),
			\amp,Pseq([0.45],lnotes),
			\dur,Pseq(durs),
			\len,Pseq(lens))
		],1),\convFX1,\mix,~reverb1).play;
	rrand(10,~t1); //firing rate determined by cluster size
});

// Cluster 2 scheduler
~tc.sched(rrand(0,10),
	{
		var lnotes = rrand(2, ~gEnt); //run len determined by color channel entropy
		var transposeval = ~transposelibrary[rrand(~lv2,~hv2)];
		var noteseq = Array.fill(lnotes, {~seqlibrary.choose}) + transposeval;
		var lens = Array.fill(lnotes, {~speedlibrary.choose});
		var durs = lens.copy;
		durs[lnotes-1] = durs[lnotes-1]+15;
		"cluster 2 firing!".postln;
		Pfx(Pseq([Pbind(
			\instrument, \H_synth,
			\red,Pseq([~r2],lnotes),
			\green,Pseq([~g2],lnotes),
			\blue,Pseq([~b2],lnotes),
			\lmuf,Pseq([~ls2+1],lnotes),
			\hmuf,Pseq([~hs2*10],lnotes),
			\pan,Pseq([~pan2],lnotes),
			\midinote,Pseq(noteseq),
			\out,Pseq([21],lnotes),
			\amp,Pseq([0.45],lnotes),
			\dur,Pseq(durs),
			\len,Pseq(lens))
		],1),\convFX1,\mix,~reverb2).play;
	rrand(10,~t2); //firing rate determined by cluster size
});

// Cluster 3 scheduler
~tc.sched(rrand(0,10),
	{
		var lnotes = rrand(2, ~bEnt); //run len determined by color channel entropy
			var transposeval = ~transposelibrary[rrand(~lv3,~hv3)];
		var noteseq = Array.fill(lnotes, {~seqlibrary.choose}) + transposeval;
		var lens = Array.fill(lnotes, {~speedlibrary.choose});
		var durs = lens.copy;
		durs[lnotes-1] = durs[lnotes-1]+15;
		"cluster 3 firing!".postln;
		Pfx(Pseq([Pbind(
			\instrument, \H_synth,
			\red,Pseq([~r3],lnotes),
			\green,Pseq([~g3],lnotes),
			\blue,Pseq([~b3],lnotes),
			\lmuf,Pseq([~ls3+1],lnotes),
			\hmuf,Pseq([~hs3*10],lnotes),
			\pan,Pseq([~pan3],lnotes),
			\midinote,Pseq(noteseq),
			\out,Pseq([21],lnotes),
			\amp,Pseq([0.45],lnotes),
			\dur,Pseq(durs),
			\len,Pseq(lens))
		],1),\convFX1,\mix,~reverb3).play;
	rrand(10,~t3); //firing rate determined by cluster size
	});


} // closing the waitforboot
) // closing the big expression



s.freqscope;
ServerMeter.new(s,2,2)
Synth(\convFX1);
// Synth(\spec_test,[\amp, 0.75]);
(
// Synth(\steeldrum,[\out,21,\amp,4]);
// Synth(\toy_piano,[\out,21,\amp,0.35]);
Synth(\H_synth,[\green,0,\red,10,\blue,0,\out,21,\freq,54.midicps,\amp,1]);
Synth(\H_synth,[\green,10,\red,0,\blue,0,\out,21,\freq,54.midicps,\amp,1]);
Synth(\H_synth,[\green,0,\red,0,\blue,10,\out,21,\freq,54.midicps,\amp,1]);
)