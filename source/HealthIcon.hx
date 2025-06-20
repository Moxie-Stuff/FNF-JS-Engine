package;

import haxe.Json;

using StringTools;

// metadatas for icons
// so I don't have to deal with stupid annoying icons cutting off
typedef IconMeta = {
	?noAntialiasing:Bool,
	?fps:Int,
	?frameOrder:Array<String> // ["normal", "losing", "winning"]
}
class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var canBounce:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';
	public var iconMeta:IconMeta;

	var initialWidth:Float = 0;
	var initialHeight:Float = 0;

	public function new(char:String = 'bf', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);

		if(canBounce) {
			var mult:Float = FlxMath.lerp(1, scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			scale.set(mult, mult);
			updateHitbox();
		}
	}

	public var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String) {
		if(this.char != char) {
			if (char.length < 1)
				char = 'face';

			iconMeta = getFile(char);
			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			var file:Dynamic = Paths.image(name);

			if (file == null)
				file == Paths.image('icons/icon-face');
			else if (!Paths.fileExists('images/icons/icon-face.png', IMAGE)){
				// throw "Don't delete the placeholder icon";
				trace("Warning: could not find the placeholder icon, expect crashes!");
			}
			if (iconMeta?.frameOrder != null){
				final framesCount:Int = Math.floor(file.width / file.height);
				final frameWidth:Int = Math.floor(file.width / framesCount);
				loadGraphic(file, true, frameWidth, Math.floor(file.height));
				initialWidth = width;
				initialHeight = height;

				iconOffsets[0] = (width - 150) / framesCount;
				iconOffsets[1] = (height - 150) / framesCount;
			}
			else
			{
				final iSize:Float = Math.round(file.width / file.height);
				loadGraphic(file, true, Math.floor(file.width / iSize), Math.floor(file.height));
				initialWidth = width;
				initialHeight = height;
				iconOffsets[0] = (width - 150) / iSize;
				iconOffsets[1] = (height - 150) / iSize;
			}

			updateHitbox();

			animation.add(char, [for(i in 0...frames.frames.length) i], 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			antialiasing = ClientPrefs.globalAntialiasing;
			if(char.endsWith('-pixel')) {
				antialiasing = false;
			}
		}
	}

	public function bounce() {
		if(canBounce) {
			var mult:Float = 1.2;
			scale.set(mult, mult);
			updateHitbox();
		}
	}

	public static function getFile(name:String):IconMeta {
		var characterPath:String = 'images/icons/$name.json';
		var path:String = Paths.getPath(characterPath);
		if (!Paths.exists(path, TEXT))
		{
			path = Paths.getPreloadPath('images/icons/bf.json'); //If a character couldn't be found, change them to BF just to prevent a crash
		}

		var rawJson = Paths.getContent(path);
		if (rawJson == null) {
			return null;
		}

		var json:IconMeta = cast Json.parse(rawJson);
		if (json.noAntialiasing == null) json.noAntialiasing = false;
		if (json.fps == null) json.fps = 24;
		// if (json.frameOrder == null) json.frameOrder = ['normal', 'losing', 'winning'];
		return json;
	}

	override function updateHitbox()
	{
		if (ClientPrefs.iconBounceType != 'Golden Apple' && ClientPrefs.iconBounceType != 'Dave and Bambi' || !Std.isOfType(FlxG.state, PlayState))
		{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
		} else {
			super.updateHitbox();
			if (initialWidth != (150 * animation.numFrames) || initialHeight != 150) //Fixes weird icon offsets when they're HUMONGUS (sussy)
			{
				offset.x = iconOffsets[0];
				offset.y = iconOffsets[1];
			}
		}
	}

	public function getCharacter():String {
		return char;
	}
}
