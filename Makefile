all:
	cd synth && ./colormake
%:
	cd synth && ./colormake $*
