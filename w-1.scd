// Musical networks of live coders workshop led by Alo Allik (alo@tehis.net) and Anna Xambó (axambo@qmul.ac.uk).
// January 16, 2019.
// ICLC 2019, Madrid

"
INTRODUCTION
----------------------------------------------------------

The files are available at: https://goo.gl/wV4QJ4



SuperCollider basics:

- there are 3 components to SuperCollider:
	synthesis server - a separate application that makes the sound
	unit generator plugins - sound synthesis units (e.g. SinOsc)
	language - programming language to control synthesis

- when you open the SuperCollider IDE there are 2 windows:
	post - where the application posts feedback e.g. errors, info, status etc.
	editor window

to make a new window use cmd-N or choose File->New from the menu

..and to get help use cmd-D to launch the searchable help system

to execute code, highlight it and press cmd-ENTER (varies by platform)

to stop all local server processes cmd-.

Make visible Library folder in Mac:
cmd-SHIFT-.

Where to copy extended libraries?
SuperCollider Extensions folder:
http://doc.sccode.org/Guides/UsingExtensions.html

debugging tips:
http://danielnouri.org/docs/SuperColliderHelp/Language/Debugging-tips.html


connect to eototo
password: iame0t0t0
"

/*
FIRST, LET'S ALL TRY TO CONNECT :)
*/


~myname = ""; // <--- ASSIGN YOUR NAME TO A VARIABLE

~myip = "ipconfig getifaddr en0".unixCmdGetStdOut // <-- FIND YOUR IP

~send_to = "192.168.3.3"; // <--- SEND YOUR ADDRESS TO ME

~alo = NetAddr(~send_to, 57120)

~alo.sendMsg("/chat", ~myname, "hello! my ip is %".format(~myip))





~ips = ()

~ips['alo'] = ~send_to


(
OSCdef('chat', {arg message;
	var ip;
	Post << ">" << message[1] << ": " << message[2] << " " << Char.nl;
	ip =
	~ips[message[1]] = message[2].asString.drop("hello! my ip is ".size);
}, "/chat")
)
~ips










/*
NOW I WOULD LIKE TO SEND YOU EVERYONE'S ADDRESSES
*/



// open send-me-code.scd
~codedoc = Document("send-me-code.scd")

// ~codedoc = Document.allDocuments.select({arg doc; doc.name == "send-me-code.scd"}).first

// activate a receiver that posts the code in the send-me-code.scd file
(
OSCdef('code', {arg message;
	message.postln;
	~codedoc.string = " /*from " ++ message[1] ++ "*/ " ++ Char.nl.asString ++ message[2] ++ Char.nl.asString;
	~codedoc.front;
}, "/code")

)


~mycode = ~ips.asString



// MAKE A DICTIONARY OF ALL CLIENT ADDRESSES
~lang_addr = ~ips.collect({arg value;
	NetAddr(value, 57120)
})


// SEND ADDRESSES TO EVERYONE
~lang_addr.do({arg addr;
	addr.sendMsg("/code", "alo", ~mycode)
})











~mycode = "~servers = ~ips.collect({arg ip;
	Server(ip, NetAddr(ip, 57120))
})"


// evaluate this to have everyone's server addresses
~servers = ~ips.collect({arg value;
	Server(value, NetAddr(value, 57110))
})

s.boot

~synthdef = SynthDef('sine', {arg freq, amp, dur;
	var sig;
	sig = SinOsc.ar(freq) * EnvGen.kr(Env.perc, 1, amp, timeScale: dur, doneAction: Done.freeSelf);
	Out.ar(0, sig.dup)
}).add.send(~servers['alo'])


Synth('sine', ['freq', 601.rand, 'amp', 0.4, 'dur', 1.0], ~servers['alo'])


~servers.do({arg server;
	~synthdef.send(server)
})

~servers.do({arg server;
	Synth('sine', ['freq', 401.rand, 'amp', 0.2, 'dur', 1.0], server)
})





// to send code to others to edit, create a SynthDef
~mycode = SynthDef('tone', {arg freq, amp, dur;
	var sig;
	sig = LFSaw.ar(freq, mul: amp) * Line.kr(1, 0, dur, doneAction: Done.freeSelf);
	Out.ar(0, sig)
}).asCompileString


~alo = NetAddr("192.168.1.102", 57120)
// and send it, including the type of message, your nickname, and the contents
~client.sendMsg("/code", "alo", ~mycode)

~sd = NetAddr("192.168.1.108", 57120)
~sd.sendMsg("/code", "alo", ~mycode)








/*
you can also make the code execute automatically in another client
if you wrap it in a string and send it and hope that they trust you to
receive it
*/

Tdef('loop', {
	100.do({
		SynthDef('racket', {
			Out.ar(0, PMOsc.ar(rrand(30, 60), rrand(100, 200), 10.rand)
				* Line.kr(0.06.rand, 0, rrand(0.3, 1.0), doneAction: Done.freeSelf))
		}).play;
		rrand(0.2, 0.6).wait;
	})
}).play

~mycode = "";

~client.sendMsg("/run", ~mycode)


// this is how you would receive it
OSCdef('run', { arg message;
	message[1].asString.compile.()
}, '/run')












// SEQUENCING WITH SCHEDULERS AND LOOPS

x.send(~servers[''])


~freqs = Scale.minor.ratios * 301;
Tdef('myloop', {
	loop({
		Synth('sine', ['freq', ~freqs.choose, 'amp', 0.7.rand, 'dur', 1 ]);
		1.wait; // <---- VERY IMPORTANT!!!!
	})
}).play

// you can change it while it runs

Tdef('myloop', {
	loop({
		Synth('sine', ['freq', ~freqs.choose, 'amp', 0.2, 'dur', 0.4 ], ~servers.choose);
		0.3.wait;
	})
}).play;

// now clear it up so it doesn't run indefinitely
Tdef('myloop').clear













// SEQUENCING WITH PATTERNS

// there is this magical object called Pbind...
~bind = Pbind().play
~bind.stop


~seq = Pbind(
	'server', Prand(~servers, inf),
	'instrument', 'sine',
	'freq', Pseq(Scale.minor.ratios * 201, inf),
	'amp', Pwhite(0.4, 0.8),
	'dur', Pseq([1, 2, 3, 4], inf),
	'delta', 0.5
).play

~seq.stop














SynthDef('slide', {arg freq, amp, dur;
	var sig;
	sig = SinOsc.ar(XLine.kr(freq, freq*2, dur)) * EnvGen.kr(Env.perc, 1, amp, timeScale: dur, doneAction: Done.freeSelf);
	Out.ar(0, sig.dup)
}).add

.send(~server)


// you can also sequence Pbinds
~seq = Pseq([
	Pbind(
		'server', Prand([s, ~servers['anna']], inf),
		'instrument', 'sine',
		'freq', Pseq(Scale.minor.ratios * 201, 2),
		'amp', Pwhite(0.4, 0.8),
		'dur', Prand([1, 2, 3, 4], inf),
		'delta', 0.5
	),
	Pbind(
		'server', Pstutter(2, Pseq([s, ~servers['anna']], 2)),
		'instrument', Pseq(['sine', 'slide'], 8),
		'freq', Pseq(Scale.minor.ratios.reverse * 401, 2),
		'amp', 0.5,
		'dur', 0.7,
		'delta', 0.25
	)
], inf).play


~seq.stop











// you can play Pbinds in parallel
~seq = Ppar([
	Pbind(
		// 'server', Prand([s, ~server], inf),
		'instrument', 'sine',
		'freq', Pseq(Scale.minor.ratios * 201, 2),
		'amp', Pwhite(0.4, 0.8),
		'dur', Prand([1, 2, 3, 4], inf),
		'delta', 0.5
	),
	Pbind(
		// 'server', Pstutter(2, Pseq([s, ~server], 2)),
		'instrument', Pseq(['sine', 'slide'], 8),
		'freq', Pseq(Scale.minor.ratios.reverse * 401, 2),
		'amp', 0.5,
		'dur', 0.7,
		'delta', 0.25
	)
], inf).play

~seq.stop








// MORE SYNTHESIS

{ LFSaw.ar(440) }.plot


// MODULATION

SynthDef('mod', {arg freq, rate, amp, pan;
	Out.ar(0, Pan2.ar(
		LFSaw.ar(
			SinOsc.kr(SinOsc.ar(rate).range(0.5, 10.0)).range(freq/pi, freq*pi),
			mul:amp),
		0)
	)
}).add.send(~server = ~servers.choose)


~synth = Synth('mod', ['freq', 222, 'amp', 0.2, 'rate', 10])
~synth.set('freq', 37, 'amp', 0.0, 'rate', 60.0)
~synth.free




s.queryAllNodes
s.sendMsg("/n_free", 1011)





s.boot

Env.sine.plot

{ LFNoise2.ar(4400) }.plot

SynthDef('mod', {arg freq, rate, amp, pan, dur;
	Out.ar(0, Pan2.ar(
		SinOsc.ar(freq,
			mul:amp), pan
		); //* EnvGen.kr(Env.sine, timeScale: dur, doneAction: 2)
	)
}).add.send(~server = ~servers.choose)

Env.perc.plot



~synth = Synth('mod', ['freq', 40, 'rate', 1, 'amp', 1.0, 'pan', 1])

~synth.set('freq', 400, 'rate', 10)
~synth.free

Tdef('setFreq', {
	var incr, amp = 0.2;
	incr = amp / 100;
	100.do({
		amp = amp - incr;
		~synth.set('amp', amp);
		0.1.wait
	})
}).play



~freqs = Array.geom(12, 211, 2**(1/12))

~player = Pbind(
	'instrument', 'mod',
	'freq', Prand(~freqs, inf),
	'rate', Pwhite(1, 8, inf),
	'amp', 0.5, 'pan', Prand([-1, 1], inf),
	'dur', Pseq([0.5, 1.0, 2.0], inf)
).play

~player.stop







s.queryAllNodes


s.sendMsg("/n_free", 1000)


// SUBTRACTIVE SYNTHESIS: FILTERING

SynthDef('sub', {arg freq, bw, amp, pan;
	Out.ar(0, Pan2.ar(
		Resonz.ar(
			Crackle.ar(LFNoise2.kr(1).range(1.5, 1.99)),
			SinOsc.kr(0.5).range(freq/2, freq*2), bw/freq, 100
		) * amp,
		pan
	))
}).add.send(~server = ~servers.choose)

~synth = Synth('sub', ['freq', 532, 'bw', 10, 'amp', 0.5, 'pan', 0])

~synth.set('amp', 0.5, 'bw', 10, 'freq', 211)

~synth.free








SynthDef('submod', {arg freq, bw, amp, pan;
	Out.ar(0, Pan2.ar(
		BPF.ar(
			Crackle.ar(1.97),
			LFNoise1.kr(13).range(freq/2, freq*2),
			SinOsc.kr(17).range(bw/2, bw*2) / freq, 10
		) * amp,
		pan
	))
}).add

~synth = Synth('submod', ['freq', 532, 'bw', 10, 'amp', 10, 'pan', 0])

~synth.set('amp', 3, 'freq', 300, 'bw', 30)

~synth.free











/*
Granular Synthesis: composing beyond the note level

Basic granular synthesis can be implemented the same way as note-level time structures, with a simple synthdef and Pbind, the only differences would be the (1) durations of the synths and (2) the delta time between the synths
*/

~synthdef = SynthDef('grain', {arg freq, rate, amp, pan, dur;
	Out.ar(0, Pan2.ar(
		SinOsc.ar(
			LFNoise1.kr(rate).range(freq/8, freq*8),
			mul:amp),
		0) * EnvGen.kr(Env.perc, timeScale: dur, doneAction: 2)
	)
}).add

~servers.do({arg server;
	~synthdef.send(server)
})


Tdef('grains', {
	loop({
		Synth('grain', ['freq', rrand(11, 333), 'rate', rrand(1, 11),
			'amp', exprand(0.2, 0.5), 'pan', rrand(-1.0, 1.0),
			'dur', rrand(0.01, 0.1)],
		//~servers.choose
		);
		rrand(0.001, 0.01).wait
	})
})
.play


Tdef('grains').stop




{ Dust.ar(440) }.plot


z = { Dust2.ar(100) * 0.6 }.play
z.free




SynthDef('fmgrains', {arg cfr, mfr, idx, amp;
	var sig, trig;
	trig = Impulse.kr(400);
	sig = GrainFM.ar(1, trig, TRand.kr(0.01, 0.05, trig), cfr, mfr, idx);
	Out.ar(0, Pan2.ar(sig, TRand.kr(-1.0, 1.0, trig), amp))
}).add

~synth = Synth('fmgrains', ['cfr', 200, 'mfr', 40, 'idx', 20, 'amp', 0.05 ])

~synth.set('mfr', 10, 'idx', 10, 'amp', 0.1)

~synth.free





SynthDef(\sinegrain, {|freq, amp, dur|
	var env;
	env = Env.perc;
	Out.ar(0,
		SinOsc.ar(freq, 0, amp)
			* EnvGen.kr(env, timeScale: dur, doneAction: 2)
	)
}).add;

// make a grain cloud with random frequencies within an octave
p = Pbind(
	\instrument, \sinegrain,
	\freq, Pwhite(40.0, 1800.0, inf),
	\amp, Pwhite(0.1, 0.4),
	\dur, Pwhite(0.01, 0.05),
	\delta, Pwhite(0.005, 0.01)
).play

p.stop

Scale.dorian.ratios

// change the grain envelope and waveform
(
SynthDef(\sawgrain, {|freq, amp, dur|
	var env;
	env = Env.perc;
	Out.ar(0,
		Select.ar(
			TIRand.kr(0, 1, Impulse.kr(1)),
			[LFSaw.ar(freq, 0, amp), Dust2.ar(freq, amp)]
		) * EnvGen.kr(env, timeScale: dur, doneAction: 2)
	)
}).add;
)

(
p = Pbind(
	\instrument, \sawgrain,
	\freq, Pshuf(Array.geom(24, 4000.0, 2**(1/24)), inf),
	\amp, Pwhite(0.4, 0.7),
	\dur, Pwhite(0.005, 0.2),
	\delta, Pwhite(0.002, 0.05)
).play
)

p.stop








/*
There are a number of granular synthesis Unit Generators that make it more efficient to generate grains
*/

{Dust.ar(1000)}.plot
{SinOsc.ar(440)}.plot

SynthDef(\grainsin, {|density, gdur, freq, amp, dur|
	var trig, sig;
	trig = Impulse.kr(density);
	sig = GrainSin.ar(2, trig, gdur, freq) * amp;
	Out.ar(0, sig * EnvGen.kr(Env.sine, timeScale: dur, doneAction: 2))
}).add

Synth(\grainsin, [\density, 300, \gdur, 0.001, \freq, 2000.0, \amp, 0.2, \dur, 5.0])

p = Pbind(
	\instrument, \grainsin,
	\density, Pseq([200, 50, 100, 200], 4),
	\gdur, Pseq([2, 4, 2, 1], 4) / Pkey(\density),
	\freq, Pseq([300, 150, 300, 150], 4) * Pshuf(Scale.dorian.ratios, 16),
	\amp, Pxrand([0.1, 0.2, 0.3, 0.4], 16),
	\dur, 1.0,
	\delta, Pkey(\dur) / 2
).play




SynthDef(\grainfm, {|density, gdur, freq, mod, index, amp, dur|
	var trig, sig;
	trig = Dust.kr(density);
	sig = GrainFM.ar(2, trig, gdur, freq, mod, index) * amp;
	Out.ar(0, sig * EnvGen.kr(Env.sine, timeScale: dur, doneAction: 2))
}).add

Synth(\grainfm, [\density, 100, \gdur, 0.04, \freq, 400.0, \mod, 200/3, \index, 10, \amp, 0.1, \dur, 5.0])

p = Pbind(
	\instrument, \grainfm,
	\density, Pseq([200, 50, 100, 200], 4),
	\gdur, Pseq([2, 4, 2, 1], 4) / Pkey(\density),
	\freq, Pseq([300, 150, 300, 150], 4) * Pshuf(Scale.dorian.ratios, 16),
	\mod, Pkey(\freq) / 3,
	\index, Pwrand([5, 10, 20], [0.5, 0.3, 0.2], 16),
	\amp, Pxrand([0.1, 0.2, 0.3, 0.4], 16),
	\dur, 1.0,
	\delta, Pkey(\dur) / 2
).play








~sample = Buffer.read(s, "/Users/rewire/snd/lonams4.aiff")

10000.do({
Buffer.read(s, "/Users/rewire/snd/lonams1.aiff")
})


~sample.path
~sample.numChannels

// we can then make it a bit more interesting
(
SynthDef(\shiftSample, {arg buffer, rate, winsize, shift, roomsize, revtime, amp;
	var sig;
	sig = PlayBuf.ar(~sample.numChannels, buffer, rate, loop: 1);
	sig = GVerb.ar(sig, roomsize, revtime);
	sig = PitchShift.ar(sig, winsize, shift);
	Out.ar(0, sig.dup * amp)
}).add
)


s.queryAllNodes


~synth = Synth(\shiftSample, [\buffer, ~sample1, \rate, 1.0, \winsize, 0.1, \shift, 1.0, \roomsize, 100, \revtime, 4, \amp, 2.0])

~synth.set(\rate, 4.0, \shift, 0.25, \amp, 1.0)

~synth.set(\roomsize, 300, \revtime, 1.0)

~synth.free

// ~buffer.write("/Users/alo/snd/lonams4.aiff")

{ LFSaw.ar(100).range(0, 1) }.plot

(
SynthDef(\warpSample, {| buffer, warp, fscale, wsize, dens, ratio, amp |
	var pointer;
	pointer = LFSaw.kr(warp/BufDur.kr(buffer), 1).range(0, 1);
	Out.ar(0, Pan2.ar(Warp1.ar(1, buffer, pointer, fscale, wsize, -1, dens, ratio )) * amp)
}).add
)


~synth2.set('amp', 2.0)
~synth1.set(\warp, 0.3, \fscale, 1.0, \wsize, 1.0, \dens, 2)

~synth1 = Synth(\warpSample, [\buffer, ~sample, \warp, 0.3, \fscale, 1.0, \wsize, 0.1,
	\dens, 6, \ratio, 0.02, \amp, 1.0
])

~synth2 = Synth(\warpSample, [\buffer, ~sample, \warp, 0.05, \fscale, 2.0, \wsize, 0.1,
	\dens, 6, \ratio, 0.02, \amp, 0.9
])

~synth3 = Synth(\warpSample, [\buffer, ~sample, \warp, 0.2, \fscale, 0.5, \wsize, 0.1,
	\dens, 6, \ratio, 0.02, \amp, 0.2
])

~synth4 = Synth(\warpSample, [\buffer, ~sample, \warp, 0.01, \fscale, 1.0, \wsize, 0.1,
	\dens, 3, \ratio, 0.0, \amp, 0.2
])

(
~synth1.free;
~synth2.free;
~synth3.free;
~synth4.free;
)



(


SynthDef(\warpSample, {| buffer, warp, fscale, pointer, wsize, dens, ratio |
	Out.ar(0, Pan2.ar(Warp1.ar(1, buffer, pointer, 1.0, wsize, -1, dens, ratio )))
}).add
)



~synth1 = Synth(\warpSample, [\buffer, ~sample, \fscale, 1.0, \wsize, 0.1,
	\dens, 6, \ratio, 0.02, \pointer, 1.0
])

~synth1.free

~win = Window("scratch", Rect(20, 20, 400, 100)).front;
Slider(~win, Rect(10, 10, 360, 60))
	.action_({|slider|
	     ~synth1.set(\pointer, slider.value)
	});





/*
control warping with a sine oscillator
*/

(
SynthDef(\warpSample, {| buffer, fscale, wsize, dens, ratio |
	var pointer;
	pointer = LFSaw.kr(SinOsc.kr(0.05, pi).range(0.01, 1.0)/BufDur.kr(buffer), 1).range(0, 1);
	Out.ar(0, Pan2.ar(Warp1.ar(1, buffer, pointer, fscale, wsize, -1, dens, ratio )))
}).add
)



~synth = Synth(\warpSample, [\buffer, ~sample, \fscale, 1.0, \wsize, 0.1,
	\dens, 6, \ratio, 0.02
])

~synth.free













// MORE ADVANCED DRUMMING SEQUENCE
// DJEMBE RHYTHM PATTERN DJAKANDI

(
// define rhythm patterns as 2D array
~seq = [
	[ 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0 ],
	[ 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
	[ 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0 ],
	[ 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0 ],
	[ 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
	[ 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0 ],
	[ 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ],
	[ 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0 ],
	[ 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0 ]
];
)



(
// mass generate SynthDefs to save typing
~ugens = [LFNoise2, LFSaw, LFPulse, SinOsc, VarSaw, LFNoise0, LFTri, SinOsc, SinOsc, VarSaw];

//~ugens = PinkNoise.dup(11);

~defs = ~ugens.collect({|ugen, i|
	SynthDef((ugen.name.asString.toLower ++ i.asString).asSymbol, {arg freq, amp, dur, pan;
		Out.ar(0, Pan2.ar(ugen.ar(freq, mul: amp), pan)
			* EnvGen.kr(Env.perc, timeScale: dur, doneAction: 2)
		)
	})
})

)

~defs.do({arg def; def.add })

~defs.do(_.add);

~bpm = 140;
~bps = ~bpm / 60;
~delta = ~bps.reciprocal / 4

(
~freqs = Array.geom(11, 121.0, 2**(1/13));
// ~seq = Array.fill(10, { Array.fill(64, { [1, 0].wchoose([0.05, 0.95]) }) });
~binds = ~ugens.collect({|ugen, i|
	Pbind(
		'instrument', ~defs[i].name,// (ugen.name.asString.toLower ++ i.asString).asSymbol,
		'freq', ~freqs[i],
		'amp', Pwhite(0.2, 0.5, inf),
		'dur', Pbrown(0.05, 0.3, 0.06, inf),
		'delta', Pfunc({ ~delta }),
		'type', Pseq(~seq[i].replace(0, \rest).replace(1, \note), inf),
		'pan', Pwhite(-1.0, 1.0, inf)
	)
})
)

Pdef('rhythm', Ppar(~binds)).quant(24)

Pdef('rhythm').play

Pdef('rhythm').stop


// add some reverb
~rev = SynthDef('reverb', {arg revamp=0.1, revtime=0.5;
	var sig;
	sig = In.ar(0, 2);
	ReplaceOut.ar(0, GVerb.ar(sig, 30, revtime, earlyreflevel: revamp))
}).play

~rev.free

~rev.set('revamp', 0.3, 'revtime', 2.0)







// ROUTING


SynthDef('slide', {arg out, freq, amp, dur;
	var sig;
	sig = SinOsc.ar(XLine.kr(freq, freq*2, dur)) * EnvGen.kr(Env.perc, 1, amp, timeScale: dur, doneAction: Done.freeSelf);
	Out.ar(out, sig.dup)
}).add;

SynthDef('delay', {arg out, in, delay, time;
	var input, sig;
	input = In.ar(in);
	sig = CombC.ar(input, 1, delay, time);
	Out.ar(out, sig);
}).add;


SynthDef('reverb', {arg in, revamp=0.1, revtime=0.5;
	var sig;
	sig = In.ar(in);
	Out.ar(0, GVerb.ar(sig, 30, revtime, earlyreflevel: revamp))
}).add;


~delaybus = Bus.audio(s)
~revbus = Bus.audio(s)


~reverb = Synth('reverb', ['in', ~revbus, 'revtime', 2.0])

~delay = Synth.before(~reverb, 'delay', ['out', ~revbus, 'in', ~delaybus, 'delay', 0.5, 'time', 2.0])

~delay.set('delay', 0.3, 'time', 4.0, 'out', 0)

~delay.free

Synth.before(~delay, 'slide', ['out', ~delaybus, 'freq', rrand(201, 1501), 'amp', rrand(0.3, 0.5), 'dur', rrand(0.1, 2.0)])


s.queryAllNodes


~delay.free

~reverb.free



