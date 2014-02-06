package;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.events.SampleDataEvent;
import flash.Lib;
import flash.media.Sound;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.utils.ByteArray;
import openfl.Assets;

class Main extends Sprite
{

	// Private
	private var _pitchShiftSpeed:Float;
	private var _pitchShiftSound:Sound = null;
	private var _pitchShiftPosition:Float;
	private var _pitchShiftBytes:ByteArray = null;
	private var _pitchShiftSamples:Int;

	public function new()
	{
		super();

		var textField = new TextField();
		var format = new TextFormat("_serif", 24, 0xffffff, false, false, false, "", "", TextFormatAlign.CENTER);
		textField.defaultTextFormat = format;
		textField.selectable = false;
		textField.width = Lib.current.stage.stageWidth;
		textField.height = Lib.current.stage.stageHeight;
		textField.text = "Click screen to increase pitch.";
		textField.addEventListener(MouseEvent.MOUSE_DOWN, increasePitch);
		addChild(textField);

		playPitchShiftingSound("loop");
	}

	private function increasePitch(event:MouseEvent):Void
	{
		_pitchShiftSpeed += 0.1;
	}

	/**
	 * Play pitch shifting sound.
	 *
	 * @param	id				If of the sound to play.
	 * @param	speed			Playback speed. 1 = normal, 0.5 = half, 2 = double... etc.
	 */
	private function playPitchShiftingSound(id:String, speed:Float = 1):Void
	{
		#if flash

		_pitchShiftBytes = new ByteArray();
		var sound:Sound = Assets.getSound("assets/" + id + ".mp3");
		sound.extract(_pitchShiftBytes, Std.int(sound.length * 44.1));

		//var f = new flash.net.FileReference();
		//f.save(_pitchShiftBytes, id + ".dat");	// Save raw sound bytes for playback on native targets

		#else

		_pitchShiftBytes = Assets.getBytes("assets/" + id + ".dat");	// On native we have to use raw sound bytes because there is no Sound.extract() function.

		#end

		_pitchShiftSpeed = speed;

		_pitchShiftPosition = _pitchShiftBytes.position = 0;
		_pitchShiftSamples = Std.int(_pitchShiftBytes.length / 8);

		_pitchShiftSound = new Sound();
		_pitchShiftSound.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
		_pitchShiftSound.play();
	}

	private function onSampleData(event:SampleDataEvent):Void
	{
		var data:Float = 0;

		for (i in 0...4096)
		{
			// Move to the correct position in our sounds ByteArray
			_pitchShiftBytes.position = Std.int(_pitchShiftPosition) * 8;	// 4 bytes per channel, 2 channels = 8

			// Write to left + right channels
			data = _pitchShiftBytes.readFloat();
			event.data.writeFloat(data);
			data = _pitchShiftBytes.readFloat();
			event.data.writeFloat(data);

			// Update position
			_pitchShiftPosition += _pitchShiftSpeed;
			if (_pitchShiftPosition >= _pitchShiftSamples)
				_pitchShiftPosition -= _pitchShiftSamples;
		}
	}
}
