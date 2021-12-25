// Server
(
SynthDef(\sine, {
	arg out, freq, amp, gate = 1, mode = 0;
	var sig, sig_env, sig_noenv, env;
    var envctl;

	envctl = \env.kr(Env.newClear(4).asArray);
	env = EnvGen.kr(envctl, gate, doneAction:2);

	sig_noenv = SinOsc.ar(freq, mul: amp*0.05);
	sig_env = sig_noenv * env;

	sig = Select.ar(mode, [sig_env, sig_noenv]);
	Out.ar(out, [sig, sig]);
}).add;
)

// Client
(
// Variables for GUI elements on window
var w, u1, u2, u3, uv_new1, uv_new2, k1, k2, k3, k4, t1, t2, t3, t4;

// Variables for click & drag
var clicked, relativeX, relativeY;
var dragging = false, drag_from, drag_to;

// Variables for ADSR
var attackTime = 5.0, decayTime = 0.0, releaseTime = 5.0;
var sustainLevel = 1.0;

// editMode: "new" --> create notes one by one, editMode: "new2" --> create multiple notes simultaneously
var editMode = "new";

// Variables for grouping notes using colors
var currentGroup = 0;
var u_color = Array.newClear(3);
var colors = [Color.black, Color.blue, Color.new255(0, 128, 0)];
var colors_shadow = [Color.grey, Color.new255(192, 192, 255), Color.new255(128, 192, 128)];

// Create a window
w = Window.new("Tapioca Synth", Rect(300, 300, 660, 260)).front;

~notes = List.newClear;

// Main UserView 
u1 = UserView(w, Rect(10, 10, 600, 150));
u1.background = Color.white;
u1.animate = true;

u1.drawFunc = {
	var x, y;
	~notes.do( {|n,i|
		n.refresh;

		x = n.x;
		y = n.amp.linlin(0, 1, 148, 50);

		Pen.strokeColor = Color.new255(230, 230, 230);
		Pen.width = 1;
		Pen.line(Point(x, 150), Point(x, y));
		Pen.stroke;

		Pen.color = colors_shadow[n.group];
		Pen.fillOval(Rect(x - 10, y - 20, 21, 21));
		Pen.color = colors[n.group];
		Pen.fillOval(Rect(x - 9, y - 19, 19, 19));

		if(n.selected) {
			Pen.strokeColor = Color.red;
			Pen.width = 2;
			Pen.addOval(Rect(x - 11, y - 21, 23, 23));
			Pen.stroke;
		};
	  };
	);

	~notes.do( {|n,i|
		if (~notes[i].state == "finished") {
			~notes.removeAt(i);
		};
	});

	if(clicked.isNil && dragging) {
		Pen.alpha = 0.5;
		Pen.color = Color.grey;
		Pen.fillRect(Rect.fromPoints(drag_from, drag_to));
	};
};

u1.mouseDownAction = {|v,mouseX,mouseY,modifiers,buttonNumber,clickCount|
	var y;
	~notes.do( {|n,i|
		y = n.amp.linlin(0, 1, 150, 50);
		if(Rect(n.x-10, y - 20, 21, 21).contains(Point(mouseX,mouseY))) {
			clicked = i;
			relativeX = mouseX - n.x;
			relativeY = mouseY - y;
			if(n.selected == false) {
				~notes.do( {|n,i|
					~notes[i].selected = false;
				});
				if((n.state != "release") && (n.state != "finished")) {
					~notes[clicked].selected = true;
				};
			};
		};
	});
	dragging = false;
	drag_from = mouseX @ mouseY;
};

u1.mouseMoveAction = {|v,mouseX,mouseY,mod|
	var xn, yn, dx, d_amp;
	if(clicked.isNil) {
		dragging = true;
		drag_to = mouseX @ mouseY;
	};
	if(clicked.notNil) {
		if(mod.isShift) {
			xn = mouseX - relativeX;
			dx = xn - ~notes[clicked].x;
			~notes.do( {|n,i|
				if(n.selected) {
					~notes[i].x = ~notes[i].x + dx;
					~notes[i].synth.set(\freq, ~notes[i].x.linexp(0, 600, 80, 4000));
				}
			});
		};
		if(mod == 0) {
			yn = mouseY - relativeY;
			d_amp = yn.linlin(50, 150, 1, 0) - ~notes[clicked].amp;
			~notes.do( {|n,i|
				if(n.selected) {
					~notes[i].changeSustainLevel(n.amp + d_amp);
				};
			});
		};
	};
};

u1.mouseUpAction = {|v,mouseX,mouseY,modifiers,buttonNumber,clickCount|
	var y, group;

	drag_to = mouseX @ mouseY;
	if(clicked.isNil) {
		if(dragging) {
			~notes.do( {|n,i|
				y = n.amp.linlin(0, 1, 150, 50);
				~notes[i].selected = false;
				if(Rect.fromPoints(drag_from, drag_to).contains(Rect(n.x-10, y-20, 21, 21))) {
					if((n.state != "release") && (n.state != "finished")) {
						~notes[i].selected = true;
					};
				};

			});
		};
		if(dragging == false) {
			if(editMode == "new") {
				if (currentGroup.isNil, {group = 0}, {group = currentGroup});
				~notes.add(Tapioca(mouseX, group, attackTime, decayTime, sustainLevel, releaseTime));
			};
			if(editMode == "new2") {
				if (currentGroup.isNil, {group = 0}, {group = currentGroup});
				~notes.add(Tapioca(mouseX, group, attackTime, decayTime, sustainLevel, releaseTime, true));
			};

		};

	};
	if(clicked.notNil) {
		clicked = nil;
	};

    dragging = false;
};

w.view.keyDownAction = {|v, char, mod, unicode, keycode|
	if(keycode == 32) {
		~notes.do( {|n, i|
			if(n.selected) {
				if(n.state == "standby", {
					~notes[i].play;
				},{
					~notes[i].setSustainLevelWithCurrentAmp;
					~notes[i].synth.set(\mode, 0);
					~notes[i].synth.release;
					~notes[i].state = "release";
					~notes[i].start_time = Main.elapsedTime;
					~notes[i].selected = false;
				});
			};
		});
	};
};

// UserView for ADSR
u2 = UserView(w, Rect(10, 170, 260, 80));
u2.background = Color.white;

k1 = Knob(u2, Rect(20, 10, 40, 40));
k1.color = [Color.black, Color.black, Color.white, Color.white];
k1.value = 1.0;
t1 = StaticText(u2, Rect(20, 50, 40, 30))
 .string_("A")
 .font_(Font("Arial", bold: true))
 .align_(\center);
k1.action = {|v|
	attackTime = v.value.cubed * 5.0;
};

k2 = Knob(u2, Rect(80, 10, 40, 40));
k2.color = [Color.black, Color.black, Color.white, Color.white];
k2.value = 0.0;
t2 = StaticText(u2, Rect(80, 50, 40, 30))
 .string_("D")
 .font_(Font("Arial", bold: true))
 .align_(\center);
k2.action = {|v|
	decayTime = v.value;
};

k3 = Knob(u2, Rect(140, 10, 40, 40));
k3.color = [Color.black, Color.black, Color.white, Color.white];
k3.value = 1.0;
t3 = StaticText(u2, Rect(140, 50, 40, 30))
 .string_("S")
 .font_(Font("Arial", bold: true))
 .align_(\center);
k3.action = {|v|
	sustainLevel = v.value * 1.0;
};

k4 = Knob(u2, Rect(200, 10, 40, 40));
k4.color = [Color.black, Color.black, Color.white, Color.white];
k4.value = 1.0;
t4 = StaticText(u2, Rect(200, 50, 40, 30))
 .string_("R")
 .font_(Font("Arial", bold: true))
 .align_(\center);
k4.action = {|v|
	releaseTime = v.value * 5.0;
};

// UserView for setting editMode: new (creates notes one by one)
uv_new1 = UserView(w, Rect(620, 10, 30, 30));
uv_new1.background = Color.white;
uv_new1.drawFunc = {
	Pen.color = Color.grey;
	Pen.fillOval(Rect(5, 5, 20, 20));
	Pen.color = Color.black;
	Pen.fillOval(Rect(6, 6, 18, 18));

	if(editMode == "new") {
		Pen.strokeColor = Color.red;
		Pen.width = 3;
		Pen.addRect(Rect(0, 0, 30, 30));
		Pen.stroke;
	};
};
uv_new1.mouseUpAction = {|v|
	editMode = "new";
	uv_new1.refresh;
	uv_new2.refresh;
};

// UserView for setting editMode: new2 (creates multiple notes simultaneously)
uv_new2 = UserView(w, Rect(620, 50, 30, 30));
uv_new2.background = Color.white;
uv_new2.drawFunc = {
	Pen.color = Color.grey;
	Pen.fillOval(Rect(5, 5, 15, 15));
	Pen.color = Color.black;
	Pen.fillOval(Rect(6, 6, 13, 13));

	Pen.color = Color.grey;
	Pen.fillOval(Rect(10, 10, 15, 15));
	Pen.color = Color.black;
	Pen.fillOval(Rect(11, 11, 13, 13));

	if(editMode == "new2") {
		Pen.strokeColor = Color.red;
		Pen.width = 3;
		Pen.addRect(Rect(0, 0, 30, 30));
		Pen.stroke;
	};
};
uv_new2.mouseUpAction = {|v|
	editMode = "new2";
	uv_new2.refresh;
	uv_new1.refresh;
};

// UserView for group settings
u3 = UserView(w, Rect(280, 170, 330, 80));
u3.background = Color.white;
u_color.do({|uv, i|
	u_color[i] = UserView(u3, Rect(5+((30+10)*i), 5, 30, 30));
	u_color[i].background = colors[i];

	u_color[i].drawFunc = {
		if(currentGroup == i) {
			Pen.strokeColor = Color.red;
			Pen.width = 4;
			Pen.addRect(Rect(0, 0, 30, 30));
			Pen.stroke;
		};
	};

	u_color[i].mouseUpAction = {

		currentGroup = i;
		u_color.do({|v|
			v.refresh;
		});

		~notes.do({|n,j|
			if(n.selected) {
				~notes[j].group = i;
			};
		});

		~notes.do({|n,j|
			if(n.group == i, {
				if((n.state != "release") && (n.state != "finished")) {
					~notes[j].selected = true;
				};
			},{
				~notes[j].selected = false;
			});
		});
	};
});

)


